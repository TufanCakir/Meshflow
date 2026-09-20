//
//  StoreViewModel.swift
//  Meshflow
//
//  Created by Tufan Cakir on 26.04.26.
//

import Combine
import Foundation
import StoreKit

@MainActor
final class StoreViewModel: ObservableObject {
    @Published private(set) var configuration: StoreConfiguration
    @Published private(set) var productsByID: [String: Product] = [:]
    @Published private(set) var purchasedProductIDs: Set<String> = []
    @Published private(set) var coinBalance: Int
    @Published private(set) var dailyConversionsUsed: Int
    @Published private(set) var dailyExportsUsed: Int
    @Published private(set) var statusMessage = ""
    @Published private(set) var isLoading = false
    @Published private(set) var hasLoadedProducts = false

    private let calendar: Calendar
    private let defaults: UserDefaults

    // HIER NEU: Task-Referenz für den Hintergrund-Listener
    private var updatesTask: Task<Void, Never>? = nil

    private enum StorageKey {
        static let coinBalance = "store.coinBalance"
        static let dailyConversionsUsed = "store.dailyConversionsUsed"
        static let dailyExportsUsed = "store.dailyExportsUsed"
        static let lastResetDate = "store.lastResetDate"
    }

    init(
        configuration: StoreConfiguration? = nil,
        defaults: UserDefaults = .standard,
        calendar: Calendar = .current
    ) {
        self.configuration = configuration ?? StoreConfiguration.load()
        self.defaults = defaults
        self.calendar = calendar
        coinBalance = defaults.integer(forKey: StorageKey.coinBalance)
        dailyConversionsUsed = defaults.integer(
            forKey: StorageKey.dailyConversionsUsed
        )
        dailyExportsUsed = defaults.integer(forKey: StorageKey.dailyExportsUsed)

        resetDailyUsageIfNeeded()

        // HIER NEU: Startet die permanente Überwachung asynchron beim App-Launch
        updatesTask = Task { [weak self] in
            await self?.listenForTransactionUpdates()
        }
    }

    // HIER NEU: Beendet den Task sauber, falls das ViewModel deallokiert wird
    deinit {
        updatesTask?.cancel()
    }

    var hasUnlimitedAccess: Bool {
        purchasedProductIDs.contains { productID in
            guard let definition = definition(for: productID) else {
                return false
            }

            return definition.kind == .subscription
                || definition.kind == .nonConsumable
        }
    }

    var remainingFreeConversions: Int {
        max(configuration.freeLimits.dailyConversions - dailyConversionsUsed, 0)
    }

    var remainingFreeExports: Int {
        max(configuration.freeLimits.dailyExports - dailyExportsUsed, 0)
    }

    var storageSlots: Int {
        configuration.freeLimits.storageSlots
    }

    func loadProducts() async {
        let productIDs = configuration.products.compactMap(\.productID)
        guard !productIDs.isEmpty else {
            hasLoadedProducts = true
            return
        }

        isLoading = true
        statusMessage = ""
        defer {
            isLoading = false
            hasLoadedProducts = true
        }

        do {
            let products = try await Product.products(for: productIDs)
            productsByID = Dictionary(
                uniqueKeysWithValues: products.map { ($0.id, $0) }
            )
            await refreshPurchasedProducts()
        } catch {
            statusMessage = error.localizedDescription
        }
    }

    func priceText(for definition: StoreProductDefinition) -> String {
        guard let productID = definition.productID else {
            return "Free"
        }

        return productsByID[productID]?.displayPrice ?? "App Store"
    }

    func canConvert(fileCount: Int) -> Bool {
        guard fileCount > 0 else { return false }
        if hasUnlimitedAccess { return true }
        if remainingFreeConversions >= fileCount { return true }
        return coinBalance >= configuration.coinCosts.conversion * fileCount
    }

    func consumeConversionAllowance(fileCount: Int) -> Bool {
        guard canConvert(fileCount: fileCount) else { return false }
        if hasUnlimitedAccess { return true }

        if remainingFreeConversions >= fileCount {
            dailyConversionsUsed += fileCount
            defaults.set(
                dailyConversionsUsed,
                forKey: StorageKey.dailyConversionsUsed
            )
            return true
        }

        coinBalance -= configuration.coinCosts.conversion * fileCount
        defaults.set(coinBalance, forKey: StorageKey.coinBalance)
        return true
    }

    func canStore(fileCount: Int, currentUsed: Int) -> Bool {
        guard fileCount > 0 else { return false }
        if hasUnlimitedAccess { return true }
        let overflow = max(
            currentUsed + fileCount - configuration.freeLimits.storageSlots,
            0
        )
        if overflow == 0 { return true }
        return coinBalance >= configuration.coinCosts.storageSlot * overflow
    }

    func consumeStorageAllowance(fileCount: Int, currentUsed: Int) -> Bool {
        guard canStore(fileCount: fileCount, currentUsed: currentUsed) else {
            return false
        }
        if hasUnlimitedAccess { return true }

        let overflow = max(
            currentUsed + fileCount - configuration.freeLimits.storageSlots,
            0
        )
        guard overflow > 0 else { return true }

        coinBalance -= configuration.coinCosts.storageSlot * overflow
        defaults.set(coinBalance, forKey: StorageKey.coinBalance)
        return true
    }

    func canExport(fileCount: Int) -> Bool {
        guard fileCount > 0 else { return false }
        if hasUnlimitedAccess { return true }
        if remainingFreeExports >= fileCount { return true }
        return coinBalance >= configuration.coinCosts.export * fileCount
    }

    func consumeExportAllowance(fileCount: Int) -> Bool {
        guard canExport(fileCount: fileCount) else { return false }
        if hasUnlimitedAccess { return true }

        if remainingFreeExports >= fileCount {
            dailyExportsUsed += fileCount
            defaults.set(dailyExportsUsed, forKey: StorageKey.dailyExportsUsed)
            return true
        }

        coinBalance -= configuration.coinCosts.export * fileCount
        defaults.set(coinBalance, forKey: StorageKey.coinBalance)
        return true
    }

    func purchase(_ definition: StoreProductDefinition) async {
        guard let productID = definition.productID else { return }
        guard let product = productsByID[productID] else {
            statusMessage = "Product not available."
            return
        }

        do {
            let result = try await product.purchase()
            switch result {
            case .success(let verification):
                let transaction = try checkVerified(verification)
                await applyPurchase(definition, transaction: transaction)
                await transaction.finish()
            case .userCancelled, .pending:
                break
            @unknown default:
                break
            }
        } catch {
            statusMessage = error.localizedDescription
        }
    }

    func restorePurchases() async {
        do {
            try await AppStore.sync()
            await refreshPurchasedProducts()
        } catch {
            statusMessage = error.localizedDescription
        }
    }

    // HIER NEU: Reagiert auf Transaktions-Updates abseits des direkten Kauf-Buttons
    private func listenForTransactionUpdates() async {
        for await result in Transaction.updates {
            do {
                let transaction = try checkVerified(result)

                // Definition anhand der ProductID suchen, um zu wissen wie die Zuweisung läuft
                if let definition = definition(for: transaction.productID) {
                    await applyPurchase(definition, transaction: transaction)
                }

                // Transaktion gegenüber Apple final abschließen
                await transaction.finish()

                // Gekaufte Produkte direkt neu laden, um die UI zu aktualisieren
                await refreshPurchasedProducts()
            } catch {
                // Fehlgeschlagene Verifizierungen loggen
                print("Transaction update verification failed: \(error)")
            }
        }
    }

    private func refreshPurchasedProducts() async {
        var purchasedIDs: Set<String> = []

        for await result in Transaction.currentEntitlements {
            guard let transaction = try? checkVerified(result) else {
                continue
            }

            purchasedIDs.insert(transaction.productID)
        }

        purchasedProductIDs = purchasedIDs
    }

    private func applyPurchase(
        _ definition: StoreProductDefinition,
        transaction: StoreKit.Transaction
    ) async {
        switch definition.kind {
        case .free:
            break
        case .subscription, .nonConsumable:
            purchasedProductIDs.insert(transaction.productID)
        case .consumable:
            coinBalance += definition.coinAmount ?? 0
            defaults.set(coinBalance, forKey: StorageKey.coinBalance)
        }
    }

    private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified:
            throw StoreError.failedVerification
        case .verified(let signedType):
            return signedType
        }
    }

    private func resetDailyUsageIfNeeded() {
        let now = Date()
        let lastReset =
            defaults.object(forKey: StorageKey.lastResetDate) as? Date

        guard let lastReset else {
            defaults.set(now, forKey: StorageKey.lastResetDate)
            return
        }

        if !calendar.isDate(lastReset, inSameDayAs: now) {
            dailyConversionsUsed = 0
            dailyExportsUsed = 0
            defaults.set(0, forKey: StorageKey.dailyConversionsUsed)
            defaults.set(0, forKey: StorageKey.dailyExportsUsed)
            defaults.set(now, forKey: StorageKey.lastResetDate)
        }
    }

    private func definition(for productID: String) -> StoreProductDefinition? {
        configuration.products.first { $0.productID == productID }
    }
}

enum StoreError: LocalizedError {
    case failedVerification

    var errorDescription: String? {
        switch self {
        case .failedVerification:
            return "The App Store transaction could not be verified."
        }
    }
}
