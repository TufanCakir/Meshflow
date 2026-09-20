//
//  RootView.swift
//  Meshflow
//
//  Created by Tufan Cakir on 26.04.26.
//

import SwiftUI

struct RootView: View {
    @EnvironmentObject private var localizationManager: LocalizationManager
    @StateObject private var converterViewModel = ConverterViewModel()

    var body: some View {
        TabView {
            Tab(
                localizationManager.text(.convert),
                systemImage: "arrow.trianglehead.2.clockwise.rotate.90"
            ) {
                ConverterView(viewModel: converterViewModel)
            }

            Tab("Meshflow Pro", systemImage: "square.stack.3d.up") {
                SubscriptionView()
            }

            Tab(
                localizationManager.text(.settings),
                systemImage: "gear"
            ) {
                NavigationStack {
                    SettingsView()
                }
            }
        }
        .tabBarMinimizeBehavior(.onScrollDown)
        .tabViewBottomAccessory(isEnabled: converterViewModel.isConverting) {
            ConversionProgressAccessory(
                progress: converterViewModel.conversionProgress,
                title: localizationManager.text(.converting)
            )
        }
    }
}

private struct ConversionProgressAccessory: View {
    let progress: Double
    let title: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "arrow.triangle.2.circlepath")
                .symbolEffect(.rotate, options: .repeat(.continuous))

            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.caption.weight(.semibold))

                ProgressView(value: progress, total: 1)
                    .progressViewStyle(.linear)
            }

            Text(progress, format: .percent.precision(.fractionLength(0)))
                .font(.caption.monospacedDigit())
                .foregroundStyle(.secondary)
                .contentTransition(.numericText())
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
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
