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

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    usageSummary
                    nativeStore
                }
                .padding()
            }
            .navigationTitle("Meshflow Pro")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarMinimizationBehavior(.onScrollDown, for: .navigationBar)
            .toolbarMinimizationRestoration(.atScrollEdge, for: .navigationBar)
            .background(Color(.systemGroupedBackground))
            .preferredColorScheme(themeManager.selectedTheme.colorScheme)
        }
        .task {
            await storeViewModel.loadProducts()
        }
    }

    private var productIDs: [String] {
        storeViewModel.configuration.products.compactMap(\.productID)
    }

    private var nativeStore: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(isGerman ? "Produkte" : "Products")
                .font(.headline)

            StoreView(ids: productIDs, prefersPromotionalIcon: true) { product in
                StoreProductIcon(productID: product.id)
            }
            .productViewStyle(.regular)
            .productDescription(.visible)
            .productIconBorder()
            .storeButton(.visible, for: .restorePurchases)

            Text(
                isGerman
                    ? "Preise, Beschreibungen und Käufe werden sicher vom App Store bereitgestellt."
                    : "Prices, descriptions, and purchases are securely provided by the App Store."
            )
            .font(.footnote)
            .foregroundStyle(.secondary)

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

private struct StoreProductIcon: View {
    let productID: String

    var body: some View {
        Image(systemName: symbolName)
            .font(.title2)
            .foregroundStyle(.tint)
            .frame(width: 44, height: 44)
            .background(.tint.opacity(0.12), in: RoundedRectangle(cornerRadius: 10))
    }

    private var symbolName: String {
        if productID.contains("coins") {
            return "bitcoinsign.circle.fill"
        }

        if productID.contains("lifetime") {
            return "infinity.circle.fill"
        }

        return "sparkles"
    }
}

#Preview {
    SubscriptionView()
        .environmentObject(StoreViewModel(configuration: .fallback))
        .environmentObject(LocalizationManager(configuration: .fallback))
        .environmentObject(ThemeManager(configuration: .fallback))
}
