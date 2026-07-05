//
//  ConverterView.swift
//  Meshwork
//
//  Created by Tufan Cakir on 26.04.26.
//

import PhotosUI
import StoreKit
import SwiftUI
import UniformTypeIdentifiers

struct ConverterView: View {
    @EnvironmentObject private var themeManager: ThemeManager
    @EnvironmentObject private var localizationManager: LocalizationManager
    @EnvironmentObject private var conversionHistoryManager:
        ConversionHistoryManager
    @EnvironmentObject private var storeViewModel: StoreViewModel
    @EnvironmentObject private var reviewPromptManager: ReviewPromptManager
    @Environment(\.requestReview) private var requestReview

    @StateObject private var viewModel = ConverterViewModel()

    @State private var showPicker = false
    @State private var showShareSheet = false
    @State private var showPhotoPicker = false
    @State private var showConvertConfirmation = false
    @State private var showFileExporter = false
    @State private var showHistory = false
    @State private var showFileInfo = false
    @State private var showSubscription = false
    @State private var selectedDropAreaSource: DropAreaSource = .none

    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                dropArea
                previewArea
                targetFormatArea
                convertButton
                progressArea
                comparisonArea

                Text(viewModel.message)
                    .font(.footnote)
                    .foregroundStyle(.secondary)

                Spacer(minLength: 0)
            }
            .padding()
            .toolbar { toolbarContent }
            .onAppear {
                if viewModel.message.isEmpty {
                    viewModel.message = localizationManager.text(
                        .noFileSelected
                    )
                }
            }
            .onChange(of: localizationManager.selectedLanguageID) {
                viewModel.updateMessageForCurrentLanguage(
                    localizationManager: localizationManager
                )
            }
            .onChange(of: viewModel.selectedURL) {
                viewModel.selectDefaultTargetFormat()
            }
            .onChange(of: viewModel.conversionResults.count) {
                guard
                    reviewPromptManager
                        .shouldRequestReviewAfterSuccessfulConversion(
                            count: viewModel.conversionResults.count
                        )
                else {
                    return
                }

                requestReview()
            }
            .photosPicker(
                isPresented: $showPhotoPicker,
                selection: $viewModel.selectedPhotoItems,
                matching: .images,
                preferredItemEncoding: .current
            )
            .onChange(of: viewModel.selectedPhotoItems) {
                guard !viewModel.selectedPhotoItems.isEmpty else { return }

                Task {
                    await viewModel.importPhotos(
                        from: viewModel.selectedPhotoItems,
                        localizationManager: localizationManager
                    )
                    viewModel.selectedPhotoItems = []
                }
            }
            .sheet(isPresented: $showPicker) {
                DocumentPicker { urls in
                    viewModel.updateSelection(
                        with: urls.map(viewModel.copyToTemporaryFolder),
                        localizationManager: localizationManager
                    )
                }
            }
            .sheet(isPresented: $showShareSheet) {
                if !viewModel.outputURLs.isEmpty {
                    ShareSheet(items: viewModel.outputURLs)
                }
            }
            .sheet(isPresented: $showHistory) {
                historySheet
            }
            .sheet(isPresented: $showFileInfo) {
                fileInfoSheet
            }
            .sheet(isPresented: $showSubscription) {
                SubscriptionView()
            }
            .fileExporter(
                isPresented: $showFileExporter,
                document: viewModel.exportDocument,
                contentType: viewModel.exportContentType,
                defaultFilename: viewModel.exportDefaultFilename
            ) { result in
                switch result {
                case .success:
                    viewModel.message = localizationManager.text(
                        .exportFinished
                    )
                case .failure:
                    viewModel.message = localizationManager.text(.exportFailed)
                }
            }
        }
    }

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .topBarLeading) {
            Menu {
                Button {
                    showPicker = true
                } label: {
                    Label(
                        localizationManager.text(.pickFile),
                        systemImage: "folder"
                    )
                }

                Button {
                    showPhotoPicker = true
                } label: {
                    Label(
                        localizationManager.text(.pickPhoto),
                        systemImage: "photo"
                    )
                }
            } label: {
                Label(
                    localizationManager.text(.pickSource),
                    systemImage: "plus.circle"
                )
            }
        }

        ToolbarItem(placement: .topBarTrailing) {
            HStack {
                Button {
                    showHistory = true
                } label: {
                    Label(
                        localizationManager.text(.history),
                        systemImage: "clock.arrow.circlepath"
                    )
                }

                if viewModel.selectedURL != nil {
                    Button {
                        showFileInfo = true
                    } label: {
                        Label(
                            localizationManager.text(.fileInfo),
                            systemImage: "info.circle"
                        )
                    }

                    Button(role: .destructive) {
                        viewModel.clearSelection(
                            localizationManager: localizationManager
                        )
                    } label: {
                        Label(
                            localizationManager.text(.clearSelection),
                            systemImage: "trash"
                        )
                    }
                }

                if !viewModel.outputURLs.isEmpty {
                    Button {
                        guard
                            storeViewModel.consumeExportAllowance(
                                fileCount: viewModel.outputURLs.count
                            )
                        else {
                            showSubscription = true
                            return
                        }

                        showShareSheet = true
                    } label: {
                        Label(
                            localizationManager.text(.share),
                            systemImage: "square.and.arrow.up"
                        )
                    }
                }

                settingsMenu
            }
        }
    }

    private var settingsMenu: some View {
        Menu {
            Button {
                showSubscription = true
            } label: {
                Label("Abo & Coins", systemImage: "square.stack.3d.up")
            }

            Button {
                requestReview()
            } label: {
                Label(
                    localizationManager.text(.rateApp),
                    systemImage: "star.bubble"
                )
            }

            Picker(
                localizationManager.text(.theme),
                selection: $themeManager.selectedThemeID
            ) {
                ForEach(themeManager.themes) { theme in
                    Text(localizationManager.themeTitle(for: theme)).tag(
                        theme.id
                    )
                }
            }

            Picker(
                localizationManager.text(.language),
                selection: $localizationManager.selectedLanguageID
            ) {
                ForEach(localizationManager.languages) { language in
                    Text(language.displayName).tag(language.id)
                }
            }
        } label: {
            Label(
                localizationManager.text(.settings),
                systemImage: "paintbrush"
            )
        }
    }

    private var dropArea: some View {
        VStack(spacing: 8) {
            RoundedRectangle(cornerRadius: 20)
                .fill(.clear)
                .overlay {
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(style: StrokeStyle(lineWidth: 2))
                }
                .overlay {
                    VStack(spacing: 6) {
                        Image(systemName: "tray.and.arrow.down")
                            .font(.largeTitle)

                        Text(localizationManager.text(.dropTitle))
                            .font(.headline)

                        Text(localizationManager.text(.dropSubtitle))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 8)
                    .allowsHitTesting(false)
                }
                .frame(height: viewModel.selectedURLs.isEmpty ? 120 : 86)
                .onDrop(of: [UTType.fileURL.identifier], isTargeted: nil) {
                    providers in
                    viewModel.handleDrop(
                        providers: providers,
                        localizationManager: localizationManager
                    )
                }

            Picker(
                localizationManager.text(.pickSource),
                selection: $selectedDropAreaSource
            ) {
                Text(localizationManager.text(.pickSource)).tag(
                    DropAreaSource.none
                )
                Text(localizationManager.text(.pickFile)).tag(
                    DropAreaSource.file
                )
                Text(localizationManager.text(.pickPhoto)).tag(
                    DropAreaSource.photo
                )
            }
            .pickerStyle(.menu)
            .onChange(of: selectedDropAreaSource) {
                switch selectedDropAreaSource {
                case .none:
                    break
                case .file:
                    showPicker = true
                case .photo:
                    showPhotoPicker = true
                }

                selectedDropAreaSource = .none
            }
        }
    }

    @ViewBuilder
    private var previewArea: some View {
        if let currentURL = viewModel.selectedURL {
            if viewModel.selectedURLs.count > 1 {
                TabView(selection: $viewModel.selectedPreviewIndex) {
                    ForEach(
                        Array(viewModel.selectedURLs.enumerated()),
                        id: \.offset
                    ) {
                        index,
                        url in
                        removablePreviewContent(for: url, index: index)
                            .tag(index)
                            .padding(.horizontal, 2)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .automatic))
                .frame(height: 250)
                .onChange(of: viewModel.selectedPreviewIndex) {
                    viewModel.updateSelectedPreview()
                }
            } else {
                removablePreviewContent(
                    for: currentURL,
                    index: viewModel.selectedPreviewIndex
                )
            }
        } else {
            ContentUnavailableView(
                localizationManager.text(.noFile),
                systemImage: "doc",
                description: Text(localizationManager.text(.pickOrDropFile))
            )
        }
    }

    private func removablePreviewContent(for url: URL, index: Int) -> some View
    {
        ZStack(alignment: .topTrailing) {
            previewContent(for: url)

            Button(role: .destructive) {
                viewModel.removeSelectedFile(
                    at: index,
                    localizationManager: localizationManager
                )
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.title2)
                    .symbolRenderingMode(.hierarchical)
                    .foregroundStyle(.secondary)
                    .padding(8)
                    .background(.ultraThinMaterial, in: Circle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel(localizationManager.text(.removeFile))
            .padding(8)
        }
    }

    @ViewBuilder
    private func previewContent(for url: URL) -> some View {
        let format = FileFormat.detect(from: url)

        if format?.isImageFormat == true,
            let image = UIImage(contentsOfFile: url.path)
        {
            Image(uiImage: image)
                .resizable()
                .scaledToFit()
                .frame(height: 210)
                .clipShape(RoundedRectangle(cornerRadius: 16))
        } else if format?.isNativeSceneFormat == true {
            ScenePreview(url: url)
                .frame(height: 230)
                .clipShape(RoundedRectangle(cornerRadius: 16))
        } else {
            Text(localizationManager.text(.noPreview))
                .frame(maxWidth: .infinity)
                .frame(height: 210)
                .background(.quaternary, in: RoundedRectangle(cornerRadius: 16))
        }
    }

    private var targetFormatArea: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(localizationManager.text(.targetFormat))
                .font(.headline)

            if !viewModel.availableTargetFormats.isEmpty {
                Picker(
                    localizationManager.text(.targetFormat),
                    selection: Binding(
                        get: { viewModel.validSelectedFormat },
                        set: { viewModel.selectedFormat = $0 }
                    )
                ) {
                    ForEach(viewModel.availableTargetFormats) { format in
                        Text(format.title).tag(format)
                    }
                }
                .pickerStyle(.menu)
            } else {
                Text(localizationManager.text(.noFileSelected))
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var convertButton: some View {
        Button {
            showConvertConfirmation = true
        } label: {
            Label(
                localizationManager.text(.convert),
                systemImage: "arrow.triangle.2.circlepath"
            )
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.borderedProminent)
        .disabled(
            viewModel.selectedURLs.isEmpty
                || viewModel.availableTargetFormats.isEmpty
                || viewModel.isConverting
        )
        .alert(
            localizationManager.text(.confirmConversionTitle),
            isPresented: $showConvertConfirmation
        ) {
            Button(localizationManager.text(.continueAction)) {
                guard
                    storeViewModel.consumeStorageAllowance(
                        fileCount: viewModel.selectedURLs.count,
                        currentUsed: conversionHistoryManager.entries.count
                    )
                else {
                    showSubscription = true
                    return
                }

                guard
                    storeViewModel.consumeConversionAllowance(
                        fileCount: viewModel.selectedURLs.count
                    )
                else {
                    showSubscription = true
                    return
                }

                viewModel.startConversion(
                    localizationManager: localizationManager,
                    conversionHistoryManager: conversionHistoryManager
                )
            }
            Button(localizationManager.text(.cancelAction), role: .cancel) {}
        } message: {
            Text(localizationManager.text(.confirmConversionMessage))
        }
    }

    @ViewBuilder
    private var progressArea: some View {
        if viewModel.isConverting {
            VStack(alignment: .leading, spacing: 8) {
                Text(localizationManager.text(.converting))
                    .font(.headline)

                ProgressView(value: viewModel.conversionProgress, total: 1)
                    .progressViewStyle(.linear)
            }
        }
    }

    @ViewBuilder
    private var comparisonArea: some View {
        if !viewModel.outputURLs.isEmpty {
            VStack(alignment: .leading, spacing: 10) {
                Text(localizationManager.text(.beforeAfter))
                    .font(.headline)

                HStack(spacing: 12) {
                    sizeComparisonColumn(
                        title: localizationManager.text(.beforeSize),
                        value: viewModel.formattedTotalFileSize(
                            for: viewModel.selectedURLs
                        )
                    )

                    Image(systemName: "arrow.right")
                        .foregroundStyle(.secondary)

                    sizeComparisonColumn(
                        title: localizationManager.text(.afterSize),
                        value: viewModel.formattedTotalFileSize(
                            for: viewModel.outputURLs
                        )
                    )
                }

                if viewModel.outputURLs.count == 1 {
                    Button {
                        guard
                            storeViewModel.consumeExportAllowance(fileCount: 1)
                        else {
                            showSubscription = true
                            return
                        }

                        showFileExporter = viewModel.exportCurrentOutput(
                            localizationManager: localizationManager
                        )
                    } label: {
                        Label(
                            localizationManager.text(.saveToFiles),
                            systemImage: "folder.badge.plus"
                        )
                        .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private func sizeComparisonColumn(title: String, value: String) -> some View
    {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)

            Text(value)
                .font(.subheadline.weight(.semibold))
                .lineLimit(1)
                .minimumScaleFactor(0.85)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(10)
        .background(.quaternary, in: RoundedRectangle(cornerRadius: 8))
    }

    private var historySheet: some View {
        NavigationStack {
            historyArea
                .padding()
                .navigationTitle(localizationManager.text(.history))
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button(localizationManager.text(.continueAction)) {
                            showHistory = false
                        }
                    }
                }
        }
    }

    private var fileInfoSheet: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 20) {
                fileDetailsArea
                recommendationArea
                comparisonArea
                conversionResultArea
                Spacer(minLength: 0)
            }
            .padding()
            .navigationTitle(localizationManager.text(.fileInfo))
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(localizationManager.text(.continueAction)) {
                        showFileInfo = false
                    }
                }
            }
        }
    }

    @ViewBuilder
    private var fileDetailsArea: some View {
        if let selectedURL = viewModel.selectedURL {
            VStack(alignment: .leading, spacing: 10) {
                Text(localizationManager.text(.fileInfo))
                    .font(.headline)

                VStack(spacing: 8) {
                    if viewModel.selectedURLs.count > 1 {
                        fileDetailRow(
                            title: localizationManager.text(.pickSource),
                            value: localizationManager.text(
                                .selectedFiles,
                                viewModel.selectedURLs.count
                            )
                        )
                    }
                    fileDetailRow(
                        title: localizationManager.text(.fileName),
                        value: selectedURL.lastPathComponent
                    )
                    fileDetailRow(
                        title: localizationManager.text(.fileFormat),
                        value: viewModel.selectedSourceFormat?.title
                            ?? localizationManager.text(.unknownFormat)
                    )
                    fileDetailRow(
                        title: localizationManager.text(.fileSize),
                        value: viewModel.formattedFileSize(for: selectedURL)
                    )
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private func fileDetailRow(title: String, value: String) -> some View {
        HStack(alignment: .firstTextBaseline) {
            Text(title)
                .foregroundStyle(.secondary)

            Spacer(minLength: 16)

            Text(value)
                .multilineTextAlignment(.trailing)
                .lineLimit(2)
        }
        .font(.caption)
    }

    @ViewBuilder
    private var recommendationArea: some View {
        if let recommendedTargetFormat = viewModel.recommendedTargetFormat {
            Button {
                viewModel.selectedFormat = recommendedTargetFormat
            } label: {
                HStack(alignment: .top, spacing: 10) {
                    Image(systemName: "sparkle.magnifyingglass")
                        .frame(width: 24)

                    VStack(alignment: .leading, spacing: 4) {
                        Text(
                            localizationManager.text(
                                .recommendedTarget,
                                recommendedTargetFormat.title
                            )
                        )
                        .font(.subheadline.weight(.semibold))

                        Text(recommendationText)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.leading)
                    }

                    Spacer()

                    if viewModel.selectedFormat == recommendedTargetFormat {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(.tint)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(10)
            }
            .buttonStyle(.plain)
            .background(.quaternary, in: RoundedRectangle(cornerRadius: 8))
        }
    }

    private var recommendationText: String {
        switch viewModel.recommendationKind() {
        case .image:
            return localizationManager.text(.imageRecommendation)
        case .scene:
            return localizationManager.text(.sceneRecommendation)
        case .none:
            return ""
        }
    }

    @ViewBuilder
    private var conversionResultArea: some View {
        if !viewModel.conversionResults.isEmpty
            || !viewModel.conversionIssues.isEmpty
        {
            VStack(alignment: .leading, spacing: 10) {
                Text(localizationManager.text(.results))
                    .font(.headline)

                ForEach(viewModel.conversionResults) { result in
                    conversionResultRow(for: result)
                }

                if !viewModel.conversionIssues.isEmpty {
                    Text(
                        localizationManager.text(
                            .failedConversions,
                            viewModel.conversionIssues.count
                        )
                    )
                    .font(.subheadline.weight(.semibold))

                    ForEach(viewModel.conversionIssues) { issue in
                        conversionIssueRow(for: issue)
                    }
                }
            }
        }
    }

    private func conversionResultRow(for result: ConversionResultItem)
        -> some View
    {
        HStack(spacing: 10) {
            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(.green)

            VStack(alignment: .leading, spacing: 2) {
                Text(result.outputURL.lastPathComponent)
                    .font(.subheadline)
                    .lineLimit(1)

                Text(
                    localizationManager.text(
                        .sourceToTarget,
                        result.sourceFormat.title,
                        result.targetFormat.title
                    )
                )
                .font(.caption)
                .foregroundStyle(.secondary)
            }

            Spacer()
        }
        .padding(10)
        .background(.quaternary, in: RoundedRectangle(cornerRadius: 8))
    }

    private func conversionIssueRow(for issue: ConversionIssue) -> some View {
        HStack(spacing: 10) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(.yellow)

            VStack(alignment: .leading, spacing: 2) {
                Text(issue.sourceURL.lastPathComponent)
                    .font(.subheadline)
                    .lineLimit(1)

                Text(issue.reason)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()
        }
        .padding(10)
        .background(.quaternary, in: RoundedRectangle(cornerRadius: 8))
    }

    private var historyArea: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(localizationManager.text(.history))
                    .font(.headline)

                Spacer()

                if !conversionHistoryManager.entries.isEmpty {
                    Button(role: .destructive) {
                        conversionHistoryManager.clearHistory()
                    } label: {
                        Label(
                            localizationManager.text(.clearHistory),
                            systemImage: "trash"
                        )
                    }
                    .labelStyle(.iconOnly)
                }
            }

            if conversionHistoryManager.entries.isEmpty {
                Text(localizationManager.text(.emptyHistory))
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
            } else {
                VStack(spacing: 8) {
                    ForEach(conversionHistoryManager.entries.prefix(5)) {
                        entry in
                        historyRow(for: entry)
                    }
                }
            }
        }
    }

    private func historyRow(for entry: ConversionHistoryEntry) -> some View {
        HStack(spacing: 12) {
            Image(systemName: "clock.arrow.circlepath")
                .foregroundStyle(.secondary)
                .frame(width: 28, height: 28)

            VStack(alignment: .leading, spacing: 2) {
                Text(entry.outputName)
                    .font(.subheadline)
                    .lineLimit(1)

                Text(
                    localizationManager.text(
                        .sourceToTarget,
                        entry.sourceFormat,
                        entry.targetFormat
                    )
                )
                .font(.caption)
                .foregroundStyle(.secondary)

                Text(entry.createdAt, style: .relative)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Menu {
                Button {
                    viewModel.loadHistoryEntry(
                        entry,
                        localizationManager: localizationManager
                    )
                    showHistory = false
                } label: {
                    Label(
                        localizationManager.text(.loadResult),
                        systemImage: "arrow.down.doc"
                    )
                }

                Button {
                    guard storeViewModel.consumeExportAllowance(fileCount: 1)
                    else {
                        showSubscription = true
                        return
                    }

                    showFileExporter = viewModel.exportHistoryEntry(
                        entry,
                        localizationManager: localizationManager
                    )
                } label: {
                    Label(
                        localizationManager.text(.saveToFiles),
                        systemImage: "folder.badge.plus"
                    )
                }

                Button {
                    guard storeViewModel.consumeExportAllowance(fileCount: 1)
                    else {
                        showSubscription = true
                        return
                    }

                    viewModel.outputURLs = [entry.fileURL]
                    viewModel.outputURL = entry.fileURL
                    showShareSheet = true
                } label: {
                    Label(
                        localizationManager.text(.share),
                        systemImage: "square.and.arrow.up"
                    )
                }
            } label: {
                Image(systemName: "ellipsis.circle")
                    .font(.title3)
            }
        }
        .padding(10)
        .background(.quaternary, in: RoundedRectangle(cornerRadius: 8))
    }
}

private enum DropAreaSource: Hashable {
    case none
    case file
    case photo
}

#Preview {
    ConverterView()
        .environmentObject(ThemeManager(configuration: .fallback))
        .environmentObject(LocalizationManager(configuration: .fallback))
        .environmentObject(ConversionHistoryManager())
        .environmentObject(StoreViewModel(configuration: .fallback))
        .environmentObject(ReviewPromptManager())
}
