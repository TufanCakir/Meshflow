//
//  ConverterView.swift
//  Meshwork
//
//  Created by Tufan Cakir on 26.04.26.
//

import ImageIO
import PhotosUI
import SwiftUI
import UniformTypeIdentifiers

struct ConverterView: View {
    @EnvironmentObject private var themeManager: ThemeManager
    @EnvironmentObject private var localizationManager: LocalizationManager

    @State private var selectedURL: URL?
    @State private var outputURL: URL?
    @State private var selectedFormat: FileFormat = .png
    @State private var selectedPhotoItem: PhotosPickerItem?

    @State private var showPicker = false
    @State private var showShareSheet = false
    @State private var showPhotoPicker = false
    @State private var showConvertConfirmation = false
    @State private var isConverting = false
    @State private var conversionProgress = 0.0
    @State private var selectedDropAreaSource: DropAreaSource = .none
    @State private var message = ""

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {

                dropArea

                previewArea

                VStack(alignment: .leading, spacing: 8) {
                    Text(localizationManager.text(.targetFormat))
                        .font(.headline)

                    Picker(
                        localizationManager.text(.targetFormat),
                        selection: $selectedFormat
                    ) {
                        ForEach(availableTargetFormats) { format in
                            Text(format.title).tag(format)
                        }
                    }
                    .pickerStyle(.menu)
                }

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
                    selectedURL == nil
                        || availableTargetFormats.isEmpty
                        || isConverting
                )
                .alert(
                    localizationManager.text(.confirmConversionTitle),
                    isPresented: $showConvertConfirmation
                ) {
                    Button(localizationManager.text(.continueAction)) {
                        startConversion()
                    }
                    Button(
                        localizationManager.text(.cancelAction),
                        role: .cancel
                    ) {
                    }
                } message: {
                    Text(localizationManager.text(.confirmConversionMessage))
                }

                if isConverting {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(localizationManager.text(.converting))
                            .font(.headline)

                        ProgressView(value: conversionProgress, total: 1)
                            .progressViewStyle(.linear)
                    }
                }

                if outputURL != nil {
                    Button {
                        showShareSheet = true
                    } label: {
                        Label(
                            localizationManager.text(.share),
                            systemImage: "square.and.arrow.up"
                        )
                        .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                }

                Text(message)
                    .font(.footnote)
                    .foregroundStyle(.secondary)

                Spacer()
            }
            .padding()
            .toolbar {
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
                    Menu {
                        Picker(
                            localizationManager.text(.theme),
                            selection: $themeManager.selectedThemeID
                        ) {
                            ForEach(themeManager.themes) { theme in
                                Text(localizationManager.themeTitle(for: theme))
                                    .tag(theme.id)
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
            }
            .onAppear {
                if message.isEmpty {
                    message = localizationManager.text(.noFileSelected)
                }
            }
            .onChange(of: localizationManager.selectedLanguageID) {
                updateMessageForCurrentLanguage()
            }
            .onChange(of: selectedURL) {
                selectDefaultTargetFormat()
            }
            .photosPicker(
                isPresented: $showPhotoPicker,
                selection: $selectedPhotoItem,
                matching: .images,
                preferredItemEncoding: .current
            )
            .onChange(of: selectedPhotoItem) {
                guard let selectedPhotoItem else {
                    return
                }

                Task {
                    await importPhoto(from: selectedPhotoItem)
                    await MainActor.run {
                        self.selectedPhotoItem = nil
                    }
                }
            }
            .sheet(isPresented: $showPicker) {
                DocumentPicker { url in
                    selectedURL = copyToTemporaryFolder(url)
                    outputURL = nil
                    message = localizationManager.text(
                        .loadedFile,
                        url.lastPathComponent
                    )
                }
            }
            .sheet(isPresented: $showShareSheet) {
                if let outputURL {
                    ShareSheet(items: [outputURL])
                }
            }
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
                .frame(height: 120)

            Picker(
                localizationManager.text(.pickSource),
                selection: $selectedDropAreaSource
            ) {
                Text(localizationManager.text(.pickSource))
                    .tag(DropAreaSource.none)
                Text(localizationManager.text(.pickFile))
                    .tag(DropAreaSource.file)
                Text(localizationManager.text(.pickPhoto))
                    .tag(DropAreaSource.photo)
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
        if let selectedURL {
            let format = FileFormat.detect(from: selectedURL)

            if format == .jpg
                || format == .png
                || format == .heic
                || format == .tiff
                || format == .bmp
            {
                if let image = UIImage(contentsOfFile: selectedURL.path) {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .frame(height: 250)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                }
            } else if format == .scn
                || format == .usd
                || format == .usda
                || format == .usdc
                || format == .usdz
            {
                ScenePreview(url: selectedURL)
                    .frame(height: 300)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
            } else {
                Text(localizationManager.text(.noPreview))
            }
        } else {
            ContentUnavailableView(
                localizationManager.text(.noFile),
                systemImage: "doc",
                description: Text(localizationManager.text(.pickOrDropFile))
            )
        }
    }

    private var selectedSourceFormat: FileFormat? {
        guard let selectedURL else {
            return nil
        }

        return FileFormat.detect(from: selectedURL)
    }

    private var availableTargetFormats: [FileFormat] {
        FileFormat.availableTargets(for: selectedSourceFormat)
    }

    private func startConversion() {
        guard !isConverting else {
            return
        }

        isConverting = true
        conversionProgress = 0.08

        Task {
            async let progressTask: Void = animateConversionProgress()
            async let conversionTask: Result<URL, Error> = performConversion()

            let result = await conversionTask
            _ = await progressTask

            await MainActor.run {
                conversionProgress = 1
            }

            try? await Task.sleep(for: .milliseconds(120))

            await MainActor.run {
                isConverting = false

                switch result {
                case .success(let convertedURL):
                    outputURL = convertedURL
                    message = localizationManager.text(
                        .finishedFile,
                        convertedURL.lastPathComponent
                    )
                case .failure(let error):
                    message = localizationManager.conversionErrorMessage(
                        for: error
                    )
                }

                conversionProgress = 0
            }
        }
    }

    private func performConversion() async -> Result<URL, Error> {
        guard let selectedURL else {
            return .failure(ConversionError.cannotReadFile)
        }

        guard availableTargetFormats.contains(selectedFormat) else {
            return .failure(ConversionError.invalidConversion)
        }

        let targetFormat = selectedFormat

        return await Task.detached(priority: .userInitiated) {
            do {
                let convertedURL = try ConverterService.convert(
                    inputURL: selectedURL,
                    targetFormat: targetFormat
                )
                return .success(convertedURL)
            } catch {
                return .failure(error)
            }
        }.value
    }

    private func animateConversionProgress() async {
        while await MainActor.run(body: {
            isConverting && conversionProgress < 0.9
        }) {
            try? await Task.sleep(for: .milliseconds(90))
            await MainActor.run {
                conversionProgress = min(conversionProgress + 0.08, 0.9)
            }
        }
    }

    private func copyToTemporaryFolder(_ url: URL) -> URL {
        let didAccess = url.startAccessingSecurityScopedResource()
        defer {
            if didAccess {
                url.stopAccessingSecurityScopedResource()
            }
        }

        let destination = FileManager.default.temporaryDirectory
            .appendingPathComponent(url.lastPathComponent)

        try? FileManager.default.removeItem(at: destination)
        try? FileManager.default.copyItem(at: url, to: destination)

        return destination
    }

    private func updateSelection(with url: URL) {
        selectedURL = url
        outputURL = nil
        message = localizationManager.text(
            .loadedFile,
            url.lastPathComponent
        )
    }

    private func handleDrop(providers: [NSItemProvider]) -> Bool {
        guard let provider = providers.first else { return false }

        provider.loadItem(
            forTypeIdentifier: UTType.fileURL.identifier,
            options: nil
        ) { item, _ in
            guard
                let data = item as? Data,
                let url = URL(dataRepresentation: data, relativeTo: nil)
            else { return }

            DispatchQueue.main.async {
                updateSelection(with: copyToTemporaryFolder(url))
            }
        }

        return true
    }

    private func selectDefaultTargetFormat() {
        guard !availableTargetFormats.isEmpty else {
            return
        }

        if !availableTargetFormats.contains(selectedFormat) {
            selectedFormat = availableTargetFormats[0]
        }
    }

    private func importPhoto(from item: PhotosPickerItem) async {
        do {
            guard let data = try await item.loadTransferable(type: Data.self)
            else {
                await MainActor.run {
                    message = localizationManager.text(.cannotReadFile)
                }
                return
            }

            let importedURL = try createTemporaryPhotoFile(from: data)

            await MainActor.run {
                updateSelection(with: importedURL)
            }
        } catch {
            await MainActor.run {
                message = localizationManager.text(.cannotReadFile)
            }
        }
    }

    private func createTemporaryPhotoFile(from data: Data) throws -> URL {
        let detectedType = imageType(for: data)
        let fileFormat = fileFormat(for: detectedType) ?? .jpg
        let fileName = "photo-\(UUID().uuidString).\(fileFormat.pathExtension)"
        let destination = FileManager.default.temporaryDirectory
            .appendingPathComponent(fileName)

        try data.write(to: destination, options: .atomic)
        return destination
    }

    private func imageType(for data: Data) -> UTType? {
        guard
            let source = CGImageSourceCreateWithData(data as CFData, nil),
            let typeIdentifier = CGImageSourceGetType(source)
        else {
            return nil
        }

        return UTType(typeIdentifier as String)
    }

    private func fileFormat(for type: UTType?) -> FileFormat? {
        guard let type else {
            return nil
        }

        if type.conforms(to: .jpeg) {
            return .jpg
        }

        if type.conforms(to: .png) {
            return .png
        }

        if type.conforms(to: .heic) {
            return .heic
        }

        if type.conforms(to: .tiff) {
            return .tiff
        }

        if type.conforms(to: .bmp) {
            return .bmp
        }

        return nil
    }

    private func updateMessageForCurrentLanguage() {
        if let outputURL {
            message = localizationManager.text(
                .finishedFile,
                outputURL.lastPathComponent
            )
        } else if let selectedURL {
            message = localizationManager.text(
                .loadedFile,
                selectedURL.lastPathComponent
            )
        } else {
            message = localizationManager.text(.noFileSelected)
        }
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
}
