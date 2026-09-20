import StoreKit
import SwiftUI

struct SubscriptionView: View {
    @EnvironmentObject private var storeViewModel: StoreViewModel
    @EnvironmentObject private var localizationManager: LocalizationManager
    @EnvironmentObject private var themeManager: ThemeManager

    var body: some View {
        NavigationStack {
            VStack(spacing: 12) {
                usageSummary
                    .padding(.horizontal)

                NativeStoreView(
                    subscriptionGroupID: storeViewModel.configuration.subscriptionGroupID,
                    oneTimeProducts: nonSubscriptionProducts,
                    isLoading: storeViewModel.isLoading,
                    hasLoadedProducts: storeViewModel.hasLoadedProducts,
                    statusMessage: storeViewModel.statusMessage,
                    copy: storeCopy
                ) {
                    await storeViewModel.loadProducts()
                }
            }
            .padding(.top, 8)
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
                definition.kind == .nonConsumable || definition.kind == .consumable,
                let productID = definition.productID
            else {
                return nil
            }

            return storeViewModel.productsByID[productID]
        }
    }

    private var usageSummary: some View {
        HStack(spacing: 10) {
            Label {
                VStack(alignment: .leading, spacing: 1) {
                    Text(isGerman ? "Guthaben" : "Balance")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text("\(storeViewModel.coinBalance)")
                        .font(.headline)
                        .contentTransition(.numericText())
                }
            } icon: {
                CoinStackSymbol()
                    .frame(width: 22, height: 22)
            }

            Divider()
                .frame(height: 32)

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
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(
            Color(.secondarySystemGroupedBackground),
            in: RoundedRectangle(cornerRadius: 14)
        )
    }

    private var storeCopy: NativeStoreView.Copy {
        NativeStoreView.Copy(
            sectionLabel: isGerman ? "Shop-Bereich" : "Store Section",
            subscriptions: isGerman ? "Abos" : "Subscriptions",
            oneTimePurchases: isGerman ? "Einmalkäufe" : "One-Time",
            loading: isGerman ? "Produkte werden geladen …" : "Loading products …",
            unavailableTitle: isGerman ? "Keine Produkte verfügbar" : "No products available",
            unavailableDescription: isGerman
                ? "Lifetime und Coin-Pakete sind im App Store derzeit nicht verfügbar."
                : "Lifetime and coin packs are currently unavailable in the App Store.",
            retry: isGerman ? "Erneut versuchen" : "Try Again",
            footer: isGerman
                ? "Preise, Beschreibungen und Käufe werden sicher vom App Store bereitgestellt."
                : "Prices, descriptions, and purchases are securely provided by the App Store."
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
        VStack(spacing: 1) {
            Text(value)
                .font(.subheadline.weight(.semibold))
                .contentTransition(.numericText())
            Text(title)
                .font(.caption2)
                .foregroundStyle(.secondary)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        .frame(maxWidth: .infinity)
    }
}

#Preview {
    SubscriptionView()
        .environmentObject(StoreViewModel(configuration: .fallback))
        .environmentObject(LocalizationManager(configuration: .fallback))
        .environmentObject(ThemeManager(configuration: .fallback))
}
