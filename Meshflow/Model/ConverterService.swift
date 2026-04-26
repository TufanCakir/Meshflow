//
//  ConverterService.swift
//  Meshwork
//
//  Created by Tufan Cakir on 26.04.26.
//

import Foundation
import ImageIO
import ModelIO
import SceneKit
import SceneKit.ModelIO
import UniformTypeIdentifiers

final class ConverterService {

    static func convert(inputURL: URL, targetFormat: FileFormat) throws -> URL {
        guard let sourceFormat = FileFormat.detect(from: inputURL) else {
            throw ConversionError.unsupportedFormat
        }

        let outputURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(
                inputURL.deletingPathExtension().lastPathComponent
            )
            .appendingPathExtension(targetFormat.pathExtension)

        try? FileManager.default.removeItem(at: outputURL)

        if sourceFormat.isImageFormat && targetFormat.isImageFormat {
            try convertImage(
                inputURL: inputURL,
                outputURL: outputURL,
                targetFormat: targetFormat
            )
        } else if sourceFormat.isSceneFormat && targetFormat.isSceneFormat {
            try convertSceneFile(inputURL: inputURL, outputURL: outputURL)
        } else if sourceFormat.isSceneFormat && targetFormat.isModelExportFormat
        {
            try convertSceneToModelAsset(
                inputURL: inputURL,
                outputURL: outputURL
            )
        } else {
            throw ConversionError.invalidConversion
        }

        return outputURL
    }

    private static func convertImage(
        inputURL: URL,
        outputURL: URL,
        targetFormat: FileFormat
    ) throws {
        guard
            let source = CGImageSourceCreateWithURL(inputURL as CFURL, nil),
            let typeIdentifier = targetFormat.utType?.identifier as CFString?,
            let destination = CGImageDestinationCreateWithURL(
                outputURL as CFURL,
                typeIdentifier,
                1,
                nil
            )
        else {
            throw ConversionError.cannotReadFile
        }

        let properties = CGImageSourceCopyPropertiesAtIndex(source, 0, nil)

        CGImageDestinationAddImageFromSource(
            destination,
            source,
            0,
            properties
        )

        if !CGImageDestinationFinalize(destination) {
            throw ConversionError.conversionFailed
        }
    }

    private static func convertSceneFile(inputURL: URL, outputURL: URL) throws {
        let scene = try SCNScene(
            url: inputURL,
            options: sceneLoadingOptions(for: inputURL)
        )
        let success = scene.write(
            to: outputURL,
            options: nil,
            delegate: nil,
            progressHandler: nil
        )

        if !success {
            throw ConversionError.conversionFailed
        }
    }

    private static func convertSceneToModelAsset(
        inputURL: URL,
        outputURL: URL
    ) throws {
        guard MDLAsset.canExportFileExtension(outputURL.pathExtension) else {
            throw ConversionError.invalidConversion
        }

        let scene = try SCNScene(
            url: inputURL,
            options: sceneLoadingOptions(for: inputURL)
        )
        let asset = MDLAsset(scnScene: scene)
        try asset.export(to: outputURL)
    }

    private static func sceneLoadingOptions(
        for inputURL: URL
    ) -> [SCNSceneSource.LoadingOption: Any] {
        [
            .checkConsistency: true,
            .assetDirectoryURLs: [inputURL.deletingLastPathComponent()],
        ]
    }
}

enum ConversionError: LocalizedError {
    case unsupportedFormat
    case invalidConversion
    case cannotReadFile
    case conversionFailed

    var errorDescription: String? {
        switch self {
        case .unsupportedFormat:
            return "Dieses Format wird nicht unterstützt."
        case .invalidConversion:
            return "Diese Konvertierung ist nicht erlaubt."
        case .cannotReadFile:
            return "Datei konnte nicht gelesen werden."
        case .conversionFailed:
            return "Konvertierung fehlgeschlagen."
        }
    }
}
