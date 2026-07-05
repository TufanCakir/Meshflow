//
//  RootView.swift
//  Meshflow
//
//  Created by Tufan Cakir on 26.04.26.
//

import SwiftUI

struct RootView: View {
    var body: some View {
        TabView {
            ConverterView()
                .tabItem {
                    Label(
                        "Convert",
                        systemImage: "arrow.trianglehead.2.clockwise.rotate.90"
                    )
                }

            SubscriptionView()
                .tabItem {
                    Label("Meshflow Pro", systemImage: "cube")
                }

            NavigationStack {
                SettingsView()
            }
            .tabItem {
                Label("Settings", systemImage: "gear")
            }
        }
    }
}

#Preview {
    RootView()
        .environmentObject(ThemeManager(configuration: .fallback))
        .environmentObject(LocalizationManager(configuration: .fallback))
        .environmentObject(ConversionHistoryManager())
        .environmentObject(StoreViewModel(configuration: .fallback))
        .environmentObject(ReviewPromptManager())
}
