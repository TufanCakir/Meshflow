//
//  ThemeManager.swift
//  Meshwork
//
//  Created by Codex on 27.04.26.
//

import Combine
import Foundation
import SwiftUI

final class ThemeManager: ObservableObject {
    @Published var selectedThemeID: String {
        didSet {
            UserDefaults.standard.set(selectedThemeID, forKey: Self.storageKey)
        }
    }

    let themes: [ThemeDefinition]

    private static let storageKey = "selectedThemeID"
    private let defaultThemeID: String

    init(configuration: AppConfiguration) {
        themes = configuration.themes
        defaultThemeID = configuration.defaultTheme

        let storedTheme = UserDefaults.standard.string(forKey: Self.storageKey)
        let initialTheme = storedTheme ?? configuration.defaultTheme

        if themes.contains(where: { $0.id == initialTheme }) {
            selectedThemeID = initialTheme
        } else {
            selectedThemeID = configuration.defaultTheme
        }
    }

    var selectedTheme: ThemeDefinition {
        themes.first(where: { $0.id == selectedThemeID })
            ?? themes.first(where: { $0.id == defaultThemeID })
            ?? ThemeDefinition(
                id: "system",
                displayNames: ["de": "Automatisch", "en": "Automatic"]
            )
    }
}
