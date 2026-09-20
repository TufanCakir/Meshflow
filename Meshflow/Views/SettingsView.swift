import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var themeManager: ThemeManager
    @EnvironmentObject private var localizationManager: LocalizationManager

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.openURL) private var openURL

    private let viewModel = SettingsViewModel()

    var body: some View {
        Form {
            languageSection
            themeSection
            aboutSection
        }
        .navigationTitle(localizationManager.text(.settings))
        .navigationBarTitleDisplayMode(.inline)
        .preferredColorScheme(themeManager.selectedTheme.colorScheme)
    }
}

extension SettingsView {
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
                Button {
                    changeTheme(theme.id)
                } label: {
                    HStack {
                        Image(systemName: icon(for: theme.id))
                            .frame(width: 28)

                        VStack(alignment: .leading, spacing: 3) {
                            Text(localizationManager.themeTitle(for: theme))
                                .foregroundStyle(.primary)
                            Text(description(for: theme.id))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }

                        Spacer()

                        if theme.id == themeManager.selectedThemeID {
                            Image(systemName: "checkmark")
                                .fontWeight(.semibold)
                                .foregroundStyle(.tint)
                        }
                    }
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityAddTraits(
                    theme.id == themeManager.selectedThemeID ? .isSelected : []
                )
            }
        }
    }

    fileprivate var aboutSection: some View {
        Section(isGerman ? "Über" : "About") {
            Button {
                openURL(viewModel.reviewURL)
            } label: {
                Label(localizationManager.text(.rateApp), systemImage: "star")
            }

            NavigationLink {
                InfoView()
            } label: {
                Label("Meshflow", systemImage: "info.circle")
            }

            Link(destination: viewModel.termsURL) {
                Label(
                    isGerman ? "Nutzungsbedingungen" : "Terms of Use",
                    systemImage: "doc.text"
                )
            }

            LabeledContent {
                Text(Bundle.main.appVersionString)
                    .foregroundStyle(.secondary)
            } label: {
                Label(isGerman ? "App-Version" : "App Version", systemImage: "number")
            }
        }
    }
}

extension SettingsView {
    fileprivate var isGerman: Bool {
        localizationManager.selectedLanguageID == "de"
    }

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

private struct SettingsViewModel {
    let reviewURL = URL(
        string: "https://apps.apple.com/app/id6763824235?action=write-review"
    )!

    let termsURL = URL(
        string: "https://www.apple.com/legal/internet-services/itunes/dev/stdeula/"
    )!
}

extension Bundle {
    fileprivate var appVersionString: String {
        let version = infoDictionary?["CFBundleShortVersionString"] as? String
        let build = infoDictionary?[kCFBundleVersionKey as String] as? String

        switch (version, build) {
        case (let version?, let build?):
            return "\(version) (\(build))"
        case (let version?, nil):
            return version
        case (nil, let build?):
            return build
        default:
            return "—"
        }
    }
}

#Preview {
    let configuration = AppConfiguration.fallback

    NavigationStack {
        SettingsView()
            .environmentObject(ThemeManager(configuration: configuration))
            .environmentObject(LocalizationManager(configuration: configuration))
    }
}
