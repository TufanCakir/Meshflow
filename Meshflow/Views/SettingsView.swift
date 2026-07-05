//
//  SettingsView.swift
//  Meshflow
//
//  Created by Tufan Cakir on 18.12.25.
//

import SwiftUI

struct SettingsView: View {

    @EnvironmentObject private var themeManager: ThemeManager
    @EnvironmentObject private var localizationManager: LocalizationManager

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        Form {
            purchaseSection
            languageSection
            themeSection
            aboutSection
        }
        .navigationTitle(localizationManager.text(.settings))
        .navigationBarTitleDisplayMode(.inline)
        .scrollDismissesKeyboard(.interactively)
        .preferredColorScheme(themeManager.selectedTheme.colorScheme)
    }
}

// MARK: - Sections

extension SettingsView {

    fileprivate var purchaseSection: some View {
        Section(
            localizationManager.selectedLanguageID == "de" ? "Abo" : "Plans"
        ) {
            NavigationLink {
                SubscriptionView()
            } label: {
                Label(
                    localizationManager.selectedLanguageID == "de"
                        ? "Abo & Einmalkauf"
                        : "Plans & one-time purchase",
                    systemImage: "sparkles"
                )
            }
        }
    }

    fileprivate var languageSection: some View {
        Section(localizationManager.text(.language)) {
            Picker(
                localizationManager.text(.language),
                selection: $localizationManager.selectedLanguageID
            ) {
                ForEach(localizationManager.languages) { language in
                    Text(language.displayName)
                        .tag(language.id)
                }
            }
            .pickerStyle(.segmented)
        }
    }

    fileprivate var themeSection: some View {
        Section(localizationManager.text(.theme)) {
            ForEach(themeManager.themes) { theme in
                // LÖSUNG: Kein Button-Objekt mehr! Ein einfaches HStack verhindert,
                // dass SwiftUI die Klick-Eigenschaften der Form-Rows korrumpiert.
                HStack {
                    Image(systemName: icon(for: theme.id))
                        .frame(width: 28)
                        .foregroundStyle(.primary)

                    VStack(alignment: .leading, spacing: 3) {
                        Text(localizationManager.themeTitle(for: theme))
                            .font(.body)
                            .foregroundStyle(.primary)

                        Text(description(for: theme.id))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    Spacer()

                    if theme.id == themeManager.selectedThemeID {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(.blue)
                    }
                }
                .contentShape(Rectangle())
                // Die Geste liegt nun direkt auf der Row, genau wie bei nativen System-Einstellungen
                .onTapGesture {
                    changeTheme(theme.id)
                }
            }
        }
    }

    fileprivate var aboutSection: some View {
        Section(
            localizationManager.selectedLanguageID == "de" ? "Über" : "About"
        ) {
            NavigationLink {
                InfoView()
            } label: {
                Label("Meshflow", systemImage: "info.circle")
            }

            Link(
                localizationManager.selectedLanguageID == "de"
                    ? "Nutzungsbedingungen"
                    : "Terms of Use",
                destination: URL(
                    string:
                        "https://www.apple.com/legal/internet-services/itunes/dev/stdeula/"
                )!
            )

            Label(Bundle.main.appVersionString, systemImage: "number")
        }
    }
}

// MARK: - Helpers

extension SettingsView {

    fileprivate func changeTheme(_ id: String) {
        if reduceMotion {
            themeManager.selectedThemeID = id
        } else {
            withAnimation(.easeInOut(duration: 0.2)) {
                themeManager.selectedThemeID = id
            }
        }
    }

    fileprivate func icon(for id: String) -> String {
        switch id {
        case "light":
            return "sun.max.fill"
        case "dark":
            return "moon.fill"
        default:
            return "circle.lefthalf.filled"
        }
    }

    fileprivate func description(for id: String) -> String {
        let isGerman = localizationManager.selectedLanguageID == "de"

        switch id {
        case "light":
            return isGerman ? "Heller Modus" : "Light mode"
        case "dark":
            return isGerman ? "Dunkler Modus" : "Dark mode"
        default:
            return isGerman ? "Folgt dem System" : "Follows system"
        }
    }
}

// MARK: - Bundle Version

extension Bundle {
    fileprivate var appVersionString: String {
        let version = infoDictionary?["CFBundleShortVersionString"] as? String
        let build = infoDictionary?[kCFBundleVersionKey as String] as? String

        switch (version, build) {
        case (let version?, let build?):
            return "Version \(version) (\(build))"
        case (let version?, nil):
            return "Version \(version)"
        case (nil, let build?):
            return "Build \(build)"
        default:
            return "Version"
        }
    }
}

// MARK: - Preview

#Preview {
    let configuration = AppConfiguration.fallback

    NavigationStack {
        SettingsView()
            .environmentObject(ThemeManager(configuration: configuration))
            .environmentObject(
                LocalizationManager(configuration: configuration)
            )
    }
}
