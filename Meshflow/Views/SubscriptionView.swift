//
//  SubscriptionView.swift
//  Meshflow
//
//  Created by Tufan Cakir on 26.04.26.
//

import SwiftUI

struct SubscriptionView: View {

    @EnvironmentObject private var storeViewModel: StoreViewModel
    @EnvironmentObject private var localizationManager: LocalizationManager
    // HIER: Binde den ThemeManager ein
    @EnvironmentObject private var themeManager: ThemeManager

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    usageSummary

                    ForEach(storeViewModel.configuration.products) {
                        definition in
                        productCard(for: definition)
                    }

                    if !storeViewModel.statusMessage.isEmpty {
                        Text(storeViewModel.statusMessage)
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding()
            }
            .navigationTitle("Meshflow Pro")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Restore") {
                        Task {
                            await storeViewModel.restorePurchases()
                        }
                    }
                }
            }
            .task {
                await storeViewModel.loadProducts()
            }
        }
        // HIER: Erzwingt das gewählte Color Scheme für die gesamte View
        // (Wichtig, damit der Cutout-Effekt des Münz-Symbols nahtlos mitswitcht)
        .colorScheme(themeManager.selectedTheme.colorScheme ?? .light)
    }

    private var usageSummary: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                // Das Münz-Symbol holt sich nun automatisch das korrekte Theme aus der Environment
                CoinStackSymbol()
                    .frame(width: 24, height: 24)

                Text("Coins")
                    .font(.headline)

                Spacer()

                Text("\(storeViewModel.coinBalance)")
                    .font(.title3.weight(.semibold))
            }

            HStack(spacing: 12) {
                usagePill(
                    title: "Convert",
                    value: "\(storeViewModel.remainingFreeConversions)"
                )
                usagePill(
                    title: "Export",
                    value: "\(storeViewModel.remainingFreeExports)"
                )
                usagePill(
                    title: "Storage",
                    value: "\(storeViewModel.storageSlots)"
                )
            }
        }
        .padding(12)
        .background(.quaternary, in: RoundedRectangle(cornerRadius: 8))
    }

    private func usagePill(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.headline)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func productCard(for definition: StoreProductDefinition)
        -> some View
    {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(
                        definition.displayName(
                            languageID: localizationManager.selectedLanguageID,
                            fallbackLanguageID: "en"
                        )
                    )
                    .font(.headline)

                    Text(
                        definition.subtitle(
                            languageID: localizationManager.selectedLanguageID,
                            fallbackLanguageID: "en"
                        )
                    )
                    .font(.caption)
                    .foregroundStyle(.secondary)
                }

                Spacer()

                Text(storeViewModel.priceText(for: definition))
                    .font(.subheadline.weight(.semibold))
            }

            VStack(alignment: .leading, spacing: 6) {
                ForEach(
                    definition.localizedBenefits(
                        languageID: localizationManager.selectedLanguageID,
                        fallbackLanguageID: "en"
                    ),
                    id: \.self
                ) { benefit in
                    Label(benefit, systemImage: "checkmark.circle")
                        .font(.caption)
                }
            }

            if definition.kind != .free {
                Button {
                    Task {
                        await storeViewModel.purchase(definition)
                    }
                } label: {
                    Label {
                        Text(
                            definition.kind == .consumable
                                ? "Buy Coins" : "Unlock"
                        )
                        // Textfarbe im Button explizit auf Weiß/Schwarz-Invertierung setzen
                        .foregroundStyle(
                            themeManager.selectedTheme.id == "dark"
                                ? .black : .white
                        )
                    } icon: {
                        if definition.kind == .consumable {
                            // Die Münze bekommt hier eine feste Farbe, damit sie auf dem Button knallt
                            CoinStackSymbol()
                                .frame(width: 18, height: 18)
                        } else {
                            Image(systemName: "lock.open")
                                .foregroundStyle(
                                    themeManager.selectedTheme.id == "dark"
                                        ? .black : .white
                                )
                        }
                    }
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                // HIER: Macht den Button im Light Mode Schwarz und im Dark Mode Weiß
                .tint(.primary)
            }
        }
        .padding(12)
        .background(.quaternary, in: RoundedRectangle(cornerRadius: 8))
    }
}

#Preview {
    SubscriptionView()
        .environmentObject(StoreViewModel(configuration: .fallback))
        .environmentObject(LocalizationManager(configuration: .fallback))
        // HIER: Auch im Preview den ThemeManager übergeben, damit es nicht crasht
        .environmentObject(ThemeManager(configuration: .fallback))
}
