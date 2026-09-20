//
//  ConverterViewModel.swift
//  Meshflow
//
//  Created by Tufan Cakir on 26.04.26.
//

import Combine
import Foundation
import ImageIO
import PhotosUI
import SwiftUI
import UniformTypeIdentifiers

@MainActor
final class ConverterViewModel: ObservableObject {
    @Published var selectedURL: URL?
    @Published var selectedURLs: [URL] = []
    @Published var outputURL: URL?
    @Published var outputURLs: [URL] = []
    @Published var selectedFormat: FileFormat = .png
    @Published var selectedPreviewIndex = 0
    @Published var selectedPhotoItems: [PhotosPickerItem] = []
    @Published var conversionResults: [ConversionResultItem] = []
    @Published var conversionIssues: [ConversionIssue] = []
    @Published var exportDocument = ConvertedFileDocument()
    @Published var exportContentType: UTType = .data
    @Published var exportDefaultFilename = "converted-file"
    @Published var isConverting = false
    @Published var conversionProgress = 0.0
    @Published var message = ""

    var selectedSourceFormat: FileFormat? {
        selectedURL.flatMap(FileFormat.detect(from:))
    }

    var availableTargetFormats: [FileFormat] {
        FileFormat.availableTargets(for: selectedSourceFormat)
    }

    var validSelectedFormat: FileFormat {
        availableTargetFormats.contains(selectedFormat)
            ? selectedFormat
            : availableTargetFormats.first ?? selectedFormat
    }

    var recommendedTargetFormat: FileFormat? {
        selectedURL.flatMap(recommendedTargetFormat(for:))
    }

    func recommendationKind() -> RecommendationKind? {
        if selectedSourceFormat?.isImageFormat == true { return .image }
        if selectedSourceFormat?.isNativeSceneFormat == true { return .scene }
        return nil
    }

    func updateSelectedPreview() {
        guard selectedURLs.indices.contains(selectedPreviewIndex) else {
            return
        }
        selectedURL = selectedURLs[selectedPreviewIndex]
        selectDefaultTargetFormat()
    }

    func startConversion(
        localizationManager: LocalizationManager,
        conversionHistoryManager: ConversionHistoryManager
    ) {
        guard !isConverting else { return }
        isConverting = true
        conversionProgress = 0.08

        Task {
            async let progressTask: Void = animateConversionProgress()
            async let conversionTask: Result<BatchConversionResult, Error> =
                performConversion()
            let result = await conversionTask
            _ = await progressTask

            conversionProgress = 1
            try? await Task.sleep(for: .milliseconds(120))
            isConverting = false

            switch result {
            case .success(let batchResult):
                conversionResults = batchResult.outputs.map { output in
                    storeHistoryEntry(
                        for: output,
                        conversionHistoryManager: conversionHistoryManager
                    )
                }
                conversionIssues = batchResult.issues
                outputURLs = conversionResults.map(\.outputURL)
                outputURL = outputURLs.first
                updateCompletionMessage(
                    localizationManager: localizationManager,
                    fallbackOutputURL: batchResult.outputs.first?.outputURL
                )
            case .failure(let error):
                conversionResults = []
                conversionIssues = []
                message = localizationManager.conversionErrorMessage(for: error)
            }

            conversionProgress = 0
        }
    }

    func copyToTemporaryFolder(_ url: URL) -> URL {
        let didAccess = url.startAccessingSecurityScopedResource()
        defer {
            if didAccess { url.stopAccessingSecurityScopedResource() }
        }

        let destination = FileManager.default.temporaryDirectory
            .appendingPathComponent(url.lastPathComponent)
        try? FileManager.default.removeItem(at: destination)
        try? FileManager.default.copyItem(at: url, to: destination)
        return destination
    }

    func formattedFileSize(for url: URL) -> String {
        guard
            let values = try? url.resourceValues(forKeys: [.fileSizeKey]),
            let fileSize = values.fileSize
        else { return "-" }

        return ByteCountFormatter.string(
            fromByteCount: Int64(fileSize),
            countStyle: .file
        )
    }

    func formattedTotalFileSize(for urls: [URL]) -> String {
        let totalSize = urls.reduce(Int64(0)) { total, url in
            guard
                let values = try? url.resourceValues(forKeys: [.fileSizeKey]),
                let fileSize = values.fileSize
            else { return total }
            return total + Int64(fileSize)
        }

        return ByteCountFormatter.string(
            fromByteCount: totalSize,
            countStyle: .file
        )
    }

    func updateSelection(
        with url: URL,
        localizationManager: LocalizationManager
    ) {
        updateSelection(with: [url], localizationManager: localizationManager)
    }

    func updateSelection(
        with urls: [URL],
        localizationManager: LocalizationManager
    ) {
        guard let firstURL = urls.first else { return }
        selectedURLs = urls
        selectedPreviewIndex = 0
        selectedURL = firstURL
        selectDefaultTargetFormat(for: firstURL)
        outputURLs = []
        outputURL = nil
        conversionResults = []
        conversionIssues = []
        message =
            urls.count == 1
            ? localizationManager.text(.loadedFile, firstURL.lastPathComponent)
            : localizationManager.text(.selectedFiles, urls.count)
    }

    func removeSelectedFile(
        at index: Int,
        localizationManager: LocalizationManager
    ) {
        guard selectedURLs.indices.contains(index) else { return }
        selectedURLs.remove(at: index)
        outputURLs = []
        outputURL = nil
        conversionResults = []
        conversionIssues = []

        guard !selectedURLs.isEmpty else {
            clearSelection(localizationManager: localizationManager)
            return
        }

        let nextIndex = min(index, selectedURLs.count - 1)
        selectedPreviewIndex = nextIndex
        selectedURL = selectedURLs[nextIndex]
        selectDefaultTargetFormat(for: selectedURLs[nextIndex])
        message =
            selectedURLs.count == 1
            ? localizationManager.text(
                .loadedFile,
                selectedURLs[0].lastPathComponent
            )
            : localizationManager.text(.selectedFiles, selectedURLs.count)
    }

    func clearSelection(localizationManager: LocalizationManager) {
        selectedURL = nil
        selectedURLs = []
        selectedPreviewIndex = 0
        outputURL = nil
        outputURLs = []
        conversionResults = []
        conversionIssues = []
        message = localizationManager.text(.noFileSelected)
    }

    func handleDrop(
        providers: [NSItemProvider],
        localizationManager: LocalizationManager
    ) -> Bool {
        guard
            let provider = providers.first,
            provider.canLoadObject(ofClass: NSURL.self)
        else {
            return false
        }

        provider.loadObject(ofClass: NSURL.self) { [weak self] object, _ in
            guard let url = object as? URL, let self else { return }

            Task { @MainActor [self] in
                self.updateSelection(
                    with: self.copyToTemporaryFolder(url),
                    localizationManager: localizationManager
                )
            }
        }
        return true
    }

    func exportCurrentOutput(localizationManager: LocalizationManager) -> Bool {
        guard let outputURL else { return false }
        return prepareExport(
            for: outputURL,
            localizationManager: localizationManager
        )
    }

    func exportHistoryEntry(
        _ entry: ConversionHistoryEntry,
        localizationManager: LocalizationManager
    ) -> Bool {
        prepareExport(
            for: entry.fileURL,
            localizationManager: localizationManager
        )
    }

    func loadHistoryEntry(
        _ entry: ConversionHistoryEntry,
        localizationManager: LocalizationManager
    ) {
        selectedURL = entry.fileURL
        selectedURLs = [entry.fileURL]
        selectedPreviewIndex = 0
        outputURL = entry.fileURL
        outputURLs = [entry.fileURL]
        conversionResults = []
        conversionIssues = []
        message = localizationManager.text(.finishedFile, entry.outputName)
    }

    func selectDefaultTargetFormat() {
        guard let selectedURL else { return }
        selectDefaultTargetFormat(for: selectedURL)
    }

    func importPhotos(
        from items: [PhotosPickerItem],
        localizationManager: LocalizationManager
    ) async {
        var importedURLs: [URL] = []

        for item in items {
            do {
                guard
                    let data = try await item.loadTransferable(type: Data.self)
                else { continue }
                importedURLs.append(try createTemporaryPhotoFile(from: data))
            } catch {
                continue
            }
        }

        if importedURLs.isEmpty {
            message = localizationManager.text(.cannotReadFile)
        } else {
            updateSelection(
                with: importedURLs,
                localizationManager: localizationManager
            )
        }
    }

    func updateMessageForCurrentLanguage(
        localizationManager: LocalizationManager
    ) {
        if !conversionIssues.isEmpty && outputURLs.isEmpty {
            message = localizationManager.text(
                .failedConversions,
                conversionIssues.count
            )
        } else if !conversionIssues.isEmpty {
            message =
                "\(localizationManager.text(.convertedFiles, outputURLs.count)). \(localizationManager.text(.failedConversions, conversionIssues.count))."
        } else if outputURLs.count > 1 {
            message = localizationManager.text(
                .convertedFiles,
                outputURLs.count
            )
        } else if let outputURL {
            message = localizationManager.text(
                .finishedFile,
                outputURL.lastPathComponent
            )
        } else if selectedURLs.count > 1 {
            message = localizationManager.text(
                .selectedFiles,
                selectedURLs.count
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

    private func recommendedTargetFormat(for url: URL) -> FileFormat? {
        guard let sourceFormat = FileFormat.detect(from: url) else {
            return nil
        }
        let targetFormats = FileFormat.availableTargets(for: sourceFormat)
        if sourceFormat.isImageFormat {
            return targetFormats.contains(.png) ? .png : targetFormats.first
        }
        if sourceFormat.isNativeSceneFormat {
            return targetFormats.contains(.usdz) ? .usdz : targetFormats.first
        }
        return targetFormats.first
    }

    private func performConversion() async -> Result<
        BatchConversionResult, Error
    > {
        guard !selectedURLs.isEmpty else {
            return .failure(ConversionError.cannotReadFile)
        }
        let inputURLs = selectedURLs
        let targetFormat = selectedFormat

        return await Task.detached(priority: .userInitiated) {
            var convertedOutputs: [ConversionOutput] = []
            var issues: [ConversionIssue] = []

            for inputURL in inputURLs {
                guard let sourceFormat = FileFormat.detect(from: inputURL)
                else {
                    issues.append(
                        ConversionIssue(
                            sourceURL: inputURL,
                            reason: ConversionError.unsupportedFormat
                                .localizedDescription
                        )
                    )
                    continue
                }

                guard
                    FileFormat.availableTargets(for: sourceFormat).contains(
                        targetFormat
                    )
                else {
                    issues.append(
                        ConversionIssue(
                            sourceURL: inputURL,
                            reason: ConversionError.invalidConversion
                                .localizedDescription
                        )
                    )
                    continue
                }

                do {
                    let convertedURL = try ConverterService.convert(
                        inputURL: inputURL,
                        targetFormat: targetFormat
                    )
                    convertedOutputs.append(
                        ConversionOutput(
                            sourceURL: inputURL,
                            outputURL: convertedURL,
                            sourceFormat: sourceFormat
                        )
                    )
                } catch {
                    issues.append(
                        ConversionIssue(
                            sourceURL: inputURL,
                            reason: error.localizedDescription
                        )
                    )
                }
            }

            return .success(
                BatchConversionResult(outputs: convertedOutputs, issues: issues)
            )
        }.value
    }

    private func animateConversionProgress() async {
        while isConverting && conversionProgress < 0.9 {
            try? await Task.sleep(for: .milliseconds(90))
            conversionProgress = min(conversionProgress + 0.08, 0.9)
        }
    }

    private func prepareExport(
        for url: URL,
        localizationManager: LocalizationManager
    ) -> Bool {
        do {
            exportDocument = try ConvertedFileDocument(fileURL: url)
            exportContentType = FileFormat.detect(from: url)?.utType ?? .data
            exportDefaultFilename = url.lastPathComponent
            return true
        } catch {
            message = localizationManager.text(.exportFailed)
            return false
        }
    }

    private func storeHistoryEntry(
        for output: ConversionOutput,
        conversionHistoryManager: ConversionHistoryManager
    ) -> ConversionResultItem {
        do {
            let entry = try conversionHistoryManager.recordConversion(
                sourceURL: output.sourceURL,
                outputURL: output.outputURL,
                sourceFormat: output.sourceFormat,
                targetFormat: selectedFormat
            )
            return ConversionResultItem(
                sourceURL: output.sourceURL,
                outputURL: entry.fileURL,
                sourceFormat: output.sourceFormat,
                targetFormat: selectedFormat
            )
        } catch {
            return ConversionResultItem(
                sourceURL: output.sourceURL,
                outputURL: output.outputURL,
                sourceFormat: output.sourceFormat,
                targetFormat: selectedFormat
            )
        }
    }

    private func updateCompletionMessage(
        localizationManager: LocalizationManager,
        fallbackOutputURL: URL?
    ) {
        if outputURLs.isEmpty {
            message = localizationManager.text(
                .failedConversions,
                conversionIssues.count
            )
        } else if outputURLs.count == 1 && conversionIssues.isEmpty {
            message = localizationManager.text(
                .finishedFile,
                outputURL?.lastPathComponent ?? fallbackOutputURL?
                    .lastPathComponent ?? ""
            )
        } else if conversionIssues.isEmpty {
            message = localizationManager.text(
                .convertedFiles,
                outputURLs.count
            )
        } else {
            message =
                "\(localizationManager.text(.convertedFiles, outputURLs.count)). \(localizationManager.text(.failedConversions, conversionIssues.count))."
        }
    }

    private func selectDefaultTargetFormat(for url: URL) {
        let targetFormats = FileFormat.availableTargets(
            for: FileFormat.detect(from: url)
        )
        guard !targetFormats.isEmpty else { return }
        if let recommendedTargetFormat = recommendedTargetFormat(for: url) {
            selectedFormat = recommendedTargetFormat
            return
        }
        if !targetFormats.contains(selectedFormat) {
            selectedFormat = targetFormats[0]
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
        else { return nil }
        return UTType(typeIdentifier as String)
    }

    private func fileFormat(for type: UTType?) -> FileFormat? {
        guard let type else { return nil }
        if type.conforms(to: .jpeg) { return .jpg }
        if type.conforms(to: .png) { return .png }
        if type.conforms(to: .heic) { return .heic }
        if type.conforms(to: .tiff) { return .tiff }
        if type.conforms(to: .bmp) { return .bmp }
        return nil
    }
}

enum RecommendationKind {
    case image
    case scene
}

struct ConversionOutput: Sendable {
    let sourceURL: URL
    let outputURL: URL
    let sourceFormat: FileFormat
}

struct BatchConversionResult: Sendable {
    let outputs: [ConversionOutput]
    let issues: [ConversionIssue]
}

struct ConversionResultItem: Identifiable {
    let id = UUID()
    let sourceURL: URL
    let outputURL: URL
    let sourceFormat: FileFormat
    let targetFormat: FileFormat
}

struct ConversionIssue: Identifiable, Sendable {
    let id = UUID()
    let sourceURL: URL
    let reason: String
}
