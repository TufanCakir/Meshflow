//
//  MeshflowApp.swift
//  Meshflow
//
//  Created by Tufan Cakir on 26.04.26.
//

import SwiftUI

@main
struct MeshflowApp: App {

    @StateObject private var themeManager: ThemeManager
    @StateObject private var localizationManager: LocalizationManager

    init() {
        let configuration = AppConfiguration.load()
        _themeManager = StateObject(
            wrappedValue: ThemeManager(configuration: configuration)
        )
        _localizationManager = StateObject(
            wrappedValue: LocalizationManager(configuration: configuration)
        )
    }

    var body: some Scene {
        WindowGroup {
            ConverterView()
                .environmentObject(themeManager)
                .environmentObject(localizationManager)
                .environment(\.locale, localizationManager.locale)
                .preferredColorScheme(themeManager.selectedTheme.colorScheme)
        }
    }
}
