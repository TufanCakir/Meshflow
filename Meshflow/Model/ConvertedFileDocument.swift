//
//  ConvertedFileDocument.swift
//  Meshwork
//
//  Created by Tufan Cakir on 26.04.26.
//

import SwiftUI
import UniformTypeIdentifiers

struct ConvertedFileDocument: FileDocument {
    static var readableContentTypes: [UTType] { [.data] }
    static var writableContentTypes: [UTType] {
        [.data] + FileFormat.allCases.compactMap(\.utType)
    }

    let data: Data

    init(data: Data = Data()) {
        self.data = data
    }

    init(configuration: ReadConfiguration) throws {
        guard let data = configuration.file.regularFileContents else {
            throw CocoaError(.fileReadCorruptFile)
        }

        self.data = data
    }

    init(fileURL: URL) throws {
        data = try Data(contentsOf: fileURL)
    }

    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        FileWrapper(regularFileWithContents: data)
    }
}
