//
//  ConversionHistoryManager.swift
//  Meshwork
//
//  Created by Tufan Cakir on 26.04.26.
//

import Combine
import Foundation

struct ConversionHistoryEntry: Codable, Identifiable, Equatable {
    let id: UUID
    let sourceName: String
    let outputName: String
    let sourceFormat: String
    let targetFormat: String
    let createdAt: Date
    let filePath: String

    var fileURL: URL {
        URL(fileURLWithPath: filePath)
    }
}

final class ConversionHistoryManager: ObservableObject {
    @Published private(set) var entries: [ConversionHistoryEntry] = []

    private static let storageKey = "conversionHistoryEntries"
    private let maxEntries = 20
    private let fileManager: FileManager

    init(fileManager: FileManager = .default) {
        self.fileManager = fileManager
        entries = loadEntries()
        removeMissingFiles()
    }

    @discardableResult
    func recordConversion(
        sourceURL: URL,
        outputURL: URL,
        sourceFormat: FileFormat,
        targetFormat: FileFormat
    ) throws -> ConversionHistoryEntry {
        let destinationURL = try copyToHistoryFolder(outputURL)
        let entry = ConversionHistoryEntry(
            id: UUID(),
            sourceName: sourceURL.lastPathComponent,
            outputName: destinationURL.lastPathComponent,
            sourceFormat: sourceFormat.title,
            targetFormat: targetFormat.title,
            createdAt: Date(),
            filePath: destinationURL.path
        )

        entries.insert(entry, at: 0)
        trimOldEntries()
        saveEntries()
        return entry
    }

    func clearHistory() {
        for entry in entries {
            try? fileManager.removeItem(at: entry.fileURL)
        }

        entries.removeAll()
        saveEntries()
    }

    private func loadEntries() -> [ConversionHistoryEntry] {
        guard
            let data = UserDefaults.standard.data(forKey: Self.storageKey),
            let decodedEntries = try? JSONDecoder().decode(
                [ConversionHistoryEntry].self,
                from: data
            )
        else {
            return []
        }

        return decodedEntries
    }

    private func saveEntries() {
        guard let data = try? JSONEncoder().encode(entries) else {
            return
        }

        UserDefaults.standard.set(data, forKey: Self.storageKey)
    }

    private func copyToHistoryFolder(_ outputURL: URL) throws -> URL {
        let folderURL = try historyFolderURL()
        let destinationURL = uniqueURL(
            in: folderURL,
            preferredName: outputURL.lastPathComponent
        )

        try fileManager.copyItem(at: outputURL, to: destinationURL)
        return destinationURL
    }

    private func historyFolderURL() throws -> URL {
        let appSupportURL = try fileManager.url(
            for: .applicationSupportDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        )
        let folderURL = appSupportURL.appendingPathComponent(
            "ConversionHistory",
            isDirectory: true
        )

        try fileManager.createDirectory(
            at: folderURL,
            withIntermediateDirectories: true
        )

        return folderURL
    }

    private func uniqueURL(in folderURL: URL, preferredName: String) -> URL {
        let baseURL = folderURL.appendingPathComponent(preferredName)

        guard fileManager.fileExists(atPath: baseURL.path) else {
            return baseURL
        }

        let originalName = baseURL.deletingPathExtension().lastPathComponent
        let pathExtension = baseURL.pathExtension

        for index in 2...999 {
            let fileName = "\(originalName)-\(index)"
            let candidateURL =
                folderURL
                .appendingPathComponent(fileName)
                .appendingPathExtension(pathExtension)

            if !fileManager.fileExists(atPath: candidateURL.path) {
                return candidateURL
            }
        }

        return
            folderURL
            .appendingPathComponent(UUID().uuidString)
            .appendingPathExtension(pathExtension)
    }

    private func trimOldEntries() {
        guard entries.count > maxEntries else {
            return
        }

        let removedEntries = entries.dropFirst(maxEntries)
        for entry in removedEntries {
            try? fileManager.removeItem(at: entry.fileURL)
        }

        entries = Array(entries.prefix(maxEntries))
    }

    private func removeMissingFiles() {
        let availableEntries = entries.filter {
            fileManager.fileExists(atPath: $0.filePath)
        }

        if availableEntries != entries {
            entries = availableEntries
            saveEntries()
        }
    }
}
