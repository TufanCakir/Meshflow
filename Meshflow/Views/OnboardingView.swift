//
//  OnboardingView.swift
//  Meshflow
//
//  Created by Tufan Cakir on 18.12.25.
//

import SwiftUI

struct OnboardingView: View {

    var onFinish: () -> Void
    @State private var page = 0

    // Holt sich das aktive Sprach-Kürzel (z.B. "de" oder "en")
    @EnvironmentObject private var localizationManager: LocalizationManager

    // Lädt die JSON-Konfiguration dynamisch
    private var onboardingConfig: OnboardingConfiguration {
        let currentLang = localizationManager.selectedLanguageID

        // Versucht das JSON aus dem Bundle zu laden
        guard
            let url = Bundle.main.url(
                forResource: "Onboarding_\(currentLang)",
                withExtension: "json"
            ),
            let data = try? Data(contentsOf: url),
            let config = try? JSONDecoder().decode(
                OnboardingConfiguration.self,
                from: data
            )
        else {

            // Fallback, falls die Datei fehlt
            return OnboardingConfiguration(
                title: "Meshflow",
                subtitle: "",
                sections: [
                    OnboardingSection(
                        title: "Conversion",
                        text: "Fast file conversion."
                    )
                ]
            )
        }
        return config
    }

    var body: some View {
        let sections = onboardingConfig.sections
        let maxPage = max(0, sections.count - 1)

        VStack {
            TabView(selection: $page) {
                ForEach(0..<sections.count, id: \.self) { index in
                    OnboardingPage(
                        // Weist jeder JSON-Sektion ein passendes Icon zu
                        icon: getIcon(for: index),
                        title: sections[index].title,
                        text: sections[index].text
                    )
                    .tag(index)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .automatic))
            .animation(.easeInOut, value: page)

            Button(action: { advance(maxPage: maxPage) }) {
                Text(
                    page < maxPage
                        ? (localizationManager.selectedLanguageID == "de"
                            ? "Weiter" : "Continue")
                        : (localizationManager.selectedLanguageID == "de"
                            ? "\(onboardingConfig.title) starten"
                            : "Start using \(onboardingConfig.title)")
                )
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .padding()
        }
        .safeAreaInset(edge: .bottom) {
            Color.clear.frame(height: 8)
        }
    }

    // Navigations-Logik basierend auf der dynamischen JSON-Länge
    private func advance(maxPage: Int) {
        if page < maxPage {
            page += 1
        } else {
            onFinish()
        }
    }

    // KORRIGIERT: Der Rückgabetyp ist nun exakt 'OnboardingIcon'
    private func getIcon(for index: Int) -> OnboardingIcon {
        switch index {
        case 0: return .system("arrow.trianglehead.2.clockwise.rotate.90")  // Konvertierung
        case 1: return .system("eye.fill")  // Vorschau / Prüfen
        case 2: return .system("iphone")  // Voll nativ
        default: return .system("doc.badge.arrow.up.fill")  // Verlauf / Export
        }
    }
}
