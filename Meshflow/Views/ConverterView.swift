//
//  ConverterView.swift
//  Meshwork
//
//  Created by Tufan Cakir on 26.04.26.
//

import ImageIO
import Photos
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
    @State private var showImportSourceDialog = false
    @State private var message = ""
    @State private var savedPhotoFileName: String?

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
                    convertFile()
                } label: {
                    Label(
                        localizationManager.text(.convert),
                        systemImage: "arrow.triangle.2.circlepath"
                    )
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .disabled(selectedURL == nil || availableTargetFormats.isEmpty)

                if outputURL != nil {
                    if canSaveOutputToPhotos {
                        Button {
                            Task {
                                await saveOutputToPhotos()
                            }
                        } label: {
                            Label(
                                localizationManager.text(.saveToPhotos),
                                systemImage: "photo.on.rectangle"
                            )
                            .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.bordered)
                    }

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
            .navigationTitle(localizationManager.text(.navigationTitle))
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        presentImportSourceDialog()
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
            .confirmationDialog(
                localizationManager.text(.pickSource),
                isPresented: $showImportSourceDialog,
                titleVisibility: .visible
            ) {
                Button(localizationManager.text(.pickFile)) {
                    showPicker = true
                }

                Button(localizationManager.text(.pickPhoto)) {
                    showPhotoPicker = true
                }
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
                    savedPhotoFileName = nil
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
        RoundedRectangle(cornerRadius: 20)
            .stroke(style: StrokeStyle(lineWidth: 2, dash: [8]))
            .frame(height: 130)
            .overlay {
                VStack {
                    Image(systemName: "tray.and.arrow.down")
                        .font(.largeTitle)

                    Text(localizationManager.text(.dropTitle))
                        .font(.headline)

                    Text(localizationManager.text(.dropSubtitle))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .contentShape(RoundedRectangle(cornerRadius: 20))
            .onTapGesture {
                presentImportSourceDialog()
            }
            .onDrop(of: [.fileURL], isTargeted: nil) { providers in
                handleDrop(providers: providers)
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
            } else if format == .scn || format == .dae || format == .usdz {
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

    private var outputFormat: FileFormat? {
        guard let outputURL else {
            return nil
        }

        return FileFormat.detect(from: outputURL)
    }

    private var canSaveOutputToPhotos: Bool {
        outputFormat?.isImageFormat == true
    }

    private func convertFile() {
        guard let selectedURL else { return }
        guard availableTargetFormats.contains(selectedFormat) else {
            message = localizationManager.text(.invalidConversion)
            return
        }

        do {
            outputURL = try ConverterService.convert(
                inputURL: selectedURL,
                targetFormat: selectedFormat
            )
            savedPhotoFileName = nil

            message = localizationManager.text(
                .finishedFile,
                outputURL?.lastPathComponent ?? ""
            )
        } catch {
            message = localizationManager.conversionErrorMessage(for: error)
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
                selectedURL = copyToTemporaryFolder(url)
                outputURL = nil
                savedPhotoFileName = nil
                message = localizationManager.text(
                    .loadedFile,
                    url.lastPathComponent
                )
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

    private func presentImportSourceDialog() {
        showImportSourceDialog = true
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
                selectedURL = importedURL
                outputURL = nil
                savedPhotoFileName = nil
                message = localizationManager.text(
                    .loadedFile,
                    importedURL.lastPathComponent
                )
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

    private func saveOutputToPhotos() async {
        guard let outputURL, canSaveOutputToPhotos else {
            return
        }

        do {
            try await requestPhotoLibraryAccess()
            try await writeImageToPhotoLibrary(from: outputURL)

            await MainActor.run {
                savedPhotoFileName = outputURL.lastPathComponent
                message = localizationManager.text(
                    .savedToPhotos,
                    outputURL.lastPathComponent
                )
            }
        } catch PhotoLibrarySaveError.accessDenied {
            await MainActor.run {
                message = localizationManager.text(.photoAccessDenied)
            }
        } catch {
            await MainActor.run {
                message = localizationManager.text(.saveToPhotosFailed)
            }
        }
    }

    private func requestPhotoLibraryAccess() async throws {
        let currentStatus = PHPhotoLibrary.authorizationStatus(for: .addOnly)

        switch currentStatus {
        case .authorized, .limited:
            return
        case .notDetermined:
            let newStatus = await PHPhotoLibrary.requestAuthorization(
                for: .addOnly
            )
            guard newStatus == .authorized || newStatus == .limited else {
                throw PhotoLibrarySaveError.accessDenied
            }
        case .denied, .restricted:
            throw PhotoLibrarySaveError.accessDenied
        @unknown default:
            throw PhotoLibrarySaveError.saveFailed
        }
    }

    private func writeImageToPhotoLibrary(from fileURL: URL) async throws {
        try await withCheckedThrowingContinuation {
            (continuation: CheckedContinuation<Void, Error>) in
            PHPhotoLibrary.shared().performChanges {
                let creationRequest = PHAssetCreationRequest.forAsset()
                creationRequest.addResource(
                    with: .photo,
                    fileURL: fileURL,
                    options: nil
                )
            } completionHandler: { success, error in
                if let error {
                    continuation.resume(throwing: error)
                } else if success {
                    continuation.resume()
                } else {
                    continuation.resume(
                        throwing: PhotoLibrarySaveError.saveFailed
                    )
                }
            }
        }
    }

    private func updateMessageForCurrentLanguage() {
        if let savedPhotoFileName {
            message = localizationManager.text(
                .savedToPhotos,
                savedPhotoFileName
            )
        } else if let outputURL {
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

private enum PhotoLibrarySaveError: Error {
    case accessDenied
    case saveFailed
}

#Preview {
    ConverterView()
        .environmentObject(ThemeManager(configuration: .fallback))
        .environmentObject(LocalizationManager(configuration: .fallback))
}
