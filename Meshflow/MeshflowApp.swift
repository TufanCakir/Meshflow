//
//  MeshflowApp.swift
//  Meshflow
//
//  Created by Tufan Cakir on 26.04.26.
//

import SwiftUI

@main
struct MeshflowApp: App {

    @AppStorage("hasSeenOnboarding")
    private var hasSeenOnboarding = false

    @StateObject private var themeManager: ThemeManager
    @StateObject private var localizationManager: LocalizationManager
    @StateObject private var conversionHistoryManager =
        ConversionHistoryManager()
    @StateObject private var storeViewModel = StoreViewModel()
    @StateObject private var reviewPromptManager = ReviewPromptManager()

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
            rootContent
                .environmentObject(themeManager)
                .environmentObject(localizationManager)
                .environmentObject(conversionHistoryManager)
                .environmentObject(storeViewModel)
                .environmentObject(reviewPromptManager)
                .environment(\.locale, localizationManager.locale)
                .preferredColorScheme(themeManager.selectedTheme.colorScheme)
        }
    }

    @ViewBuilder
    private var rootContent: some View {
        Group {
            if hasSeenOnboarding {
                RootView()
            } else {
                OnboardingView {
                    hasSeenOnboarding = true
                }
            }
        }
    }
}
