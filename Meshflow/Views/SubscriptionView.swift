//
//  SubscriptionView.swift
//  Meshflow
//
//  Created by Tufan Cakir on 26.04.26.
//

import StoreKit
import SwiftUI

struct SubscriptionView: View {
    @EnvironmentObject private var storeViewModel: StoreViewModel
    @EnvironmentObject private var localizationManager: LocalizationManager
    @EnvironmentObject private var themeManager: ThemeManager

    @State private var selectedSection: StoreSection = .subscriptions

    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                usageSummary
                    .padding(.horizontal)

                Picker(
                    isGerman ? "Shop-Bereich" : "Store Section",
                    selection: $selectedSection
                ) {
                    Text(isGerman ? "Abos" : "Subscriptions")
                        .tag(StoreSection.subscriptions)
                    Text(isGerman ? "Einmalkäufe" : "One-Time")
                        .tag(StoreSection.oneTimePurchases)
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)

                switch selectedSection {
                case .subscriptions:
                    subscriptionStore
                case .oneTimePurchases:
                    purchaseStore
                }
            }
            .padding(.top)
            .navigationTitle("Meshflow Pro")
            .navigationBarTitleDisplayMode(.inline)
            .background(Color(.systemGroupedBackground))
            .preferredColorScheme(themeManager.selectedTheme.colorScheme)
        }
        .task {
            await storeViewModel.loadProducts()
        }
    }

    private var nonSubscriptionProducts: [Product] {
        storeViewModel.configuration.products.compactMap { definition in
            guard
                definition.kind == .nonConsumable
                    || definition.kind == .consumable,
                let productID = definition.productID
            else {
                return nil
            }

            return storeViewModel.productsByID[productID]
        }
    }

    private var subscriptionStore: some View {
        SubscriptionStoreView(
            groupID: storeViewModel.configuration.subscriptionGroupID
        )
        .storeButton(.visible, for: .restorePurchases)
    }

    private var purchaseStore: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                if storeViewModel.isLoading || !storeViewModel.hasLoadedProducts {
                    HStack(spacing: 12) {
                        ProgressView()
                        Text(isGerman ? "Produkte werden geladen …" : "Loading products …")
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity, minHeight: 120)
                } else if nonSubscriptionProducts.isEmpty {
                    ContentUnavailableView {
                        Label(
                            isGerman
                                ? "Keine Produkte verfügbar"
                                : "No products available",
                            systemImage: "cart.badge.questionmark"
                        )
                    } description: {
                        Text(
                            isGerman
                                ? "Lifetime und Coin-Pakete sind im App Store derzeit nicht verfügbar."
                                : "Lifetime and coin packs are currently unavailable in the App Store."
                        )
                    } actions: {
                        Button(isGerman ? "Erneut versuchen" : "Try Again") {
                            Task {
                                await storeViewModel.loadProducts()
                            }
                        }
                    }
                } else {
                    StoreView(
                        products: nonSubscriptionProducts,
                        prefersPromotionalIcon: true
                    )
                    .productViewStyle(.regular)
                    .productDescription(.visible)
                    .storeButton(.visible, for: .restorePurchases)

                    Text(
                        isGerman
                            ? "Preise, Beschreibungen und Käufe werden sicher vom App Store bereitgestellt."
                            : "Prices, descriptions, and purchases are securely provided by the App Store."
                    )
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                }

                if !storeViewModel.statusMessage.isEmpty {
                    Text(storeViewModel.statusMessage)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(16)
            .background(
                Color(.secondarySystemGroupedBackground),
                in: RoundedRectangle(cornerRadius: 16)
            )
            .padding(.horizontal)
            .padding(.bottom)
        }
    }

    private var usageSummary: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                CoinStackSymbol()
                    .frame(width: 24, height: 24)

                Text(isGerman ? "Guthaben" : "Balance")
                    .font(.headline)

                Spacer()

                Text("\(storeViewModel.coinBalance)")
                    .font(.title3.weight(.semibold))
                    .contentTransition(.numericText())
            }

            HStack(spacing: 12) {
                UsageValue(
                    title: isGerman ? "Konvertieren" : "Convert",
                    value: "\(storeViewModel.remainingFreeConversions)"
                )
                UsageValue(
                    title: isGerman ? "Exportieren" : "Export",
                    value: "\(storeViewModel.remainingFreeExports)"
                )
                UsageValue(
                    title: isGerman ? "Speicher" : "Storage",
                    value: "\(storeViewModel.storageSlots)"
                )
            }
        }
        .padding(16)
        .background(
            Color(.secondarySystemGroupedBackground),
            in: RoundedRectangle(cornerRadius: 16)
        )
    }

    private var isGerman: Bool {
        localizationManager.selectedLanguageID == "de"
    }
}

private enum StoreSection: Hashable {
    case subscriptions
    case oneTimePurchases
}

private struct UsageValue: View {
    let title: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)

            Text(value)
                .font(.headline)
                .contentTransition(.numericText())
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

#Preview {
    SubscriptionView()
        .environmentObject(StoreViewModel(configuration: .fallback))
        .environmentObject(LocalizationManager(configuration: .fallback))
        .environmentObject(ThemeManager(configuration: .fallback))
}
