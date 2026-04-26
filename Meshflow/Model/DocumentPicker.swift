//
//  DocumentPicker.swift
//  Meshwork
//
//  Created by Tufan Cakir on 26.04.26.
//

import SwiftUI
import UniformTypeIdentifiers

struct DocumentPicker: UIViewControllerRepresentable {

    var onPick: (URL) -> Void

    func makeUIViewController(context: Context)
        -> UIDocumentPickerViewController
    {
        let types = FileFormat.allCases.compactMap(\.utType)

        let picker = UIDocumentPickerViewController(
            forOpeningContentTypes: types
        )
        picker.allowsMultipleSelection = false
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(
        _ uiViewController: UIDocumentPickerViewController,
        context: Context
    ) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(onPick: onPick)
    }

    final class Coordinator: NSObject, UIDocumentPickerDelegate {
        let onPick: (URL) -> Void

        init(onPick: @escaping (URL) -> Void) {
            self.onPick = onPick
        }

        func documentPicker(
            _ controller: UIDocumentPickerViewController,
            didPickDocumentsAt urls: [URL]
        ) {
            guard let url = urls.first else { return }
            onPick(url)
        }
    }
}
