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

    nonisolated static func convert(inputURL: URL, targetFormat: FileFormat)
        throws -> URL
    {
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
        } else if sourceFormat.isNativeSceneFormat
            && targetFormat.isNativeSceneFormat
        {
            try convertNativeScene(
                inputURL: inputURL,
                outputURL: outputURL,
                sourceFormat: sourceFormat,
                targetFormat: targetFormat
            )
        } else {
            throw ConversionError.invalidConversion
        }

        return outputURL
    }

    nonisolated static func loadPreviewScene(from inputURL: URL) -> SCNScene? {
        guard let sourceFormat = FileFormat.detect(from: inputURL) else {
            return nil
        }

        return try? loadScene(from: inputURL, sourceFormat: sourceFormat)
    }

    nonisolated private static func convertImage(
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

    nonisolated private static func convertNativeScene(
        inputURL: URL,
        outputURL: URL,
        sourceFormat: FileFormat,
        targetFormat: FileFormat
    ) throws {
        switch targetFormat {
        case .scn, .usdz:
            let scene = try loadScene(
                from: inputURL,
                sourceFormat: sourceFormat
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
        case .usd, .usda, .usdc:
            let asset = try loadAsset(
                from: inputURL,
                sourceFormat: sourceFormat
            )

            guard MDLAsset.canExportFileExtension(outputURL.pathExtension)
            else {
                throw ConversionError.invalidConversion
            }

            try asset.export(to: outputURL)
        default:
            throw ConversionError.invalidConversion
        }
    }

    nonisolated private static func loadScene(
        from inputURL: URL,
        sourceFormat: FileFormat
    ) throws -> SCNScene {
        switch sourceFormat {
        case .scn, .usdz:
            return try SCNScene(
                url: inputURL,
                options: sceneLoadingOptions(for: inputURL)
            )
        case .usd, .usda, .usdc:
            return SCNScene(
                mdlAsset: try loadAsset(
                    from: inputURL,
                    sourceFormat: sourceFormat
                )
            )
        default:
            throw ConversionError.invalidConversion
        }
    }

    nonisolated private static func loadAsset(
        from inputURL: URL,
        sourceFormat: FileFormat
    ) throws -> MDLAsset {
        switch sourceFormat {
        case .scn, .usdz:
            return MDLAsset(
                scnScene: try loadScene(
                    from: inputURL,
                    sourceFormat: sourceFormat
                )
            )
        case .usd, .usda, .usdc:
            guard MDLAsset.canImportFileExtension(inputURL.pathExtension) else {
                throw ConversionError.cannotReadFile
            }

            return MDLAsset(url: inputURL)
        default:
            throw ConversionError.invalidConversion
        }
    }

    nonisolated private static func sceneLoadingOptions(
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
