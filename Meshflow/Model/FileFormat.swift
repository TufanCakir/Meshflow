//
//  FileFormat.swift
//  Meshwork
//
//  Created by Tufan Cakir on 26.04.26.
//

import Foundation
import UniformTypeIdentifiers

enum FileFormat: String, CaseIterable, Identifiable {
    case jpg
    case png
    case heic
    case tiff
    case bmp
    case scn
    case usd
    case usda
    case usdc
    case usdz

    nonisolated var id: String { rawValue }

    nonisolated var title: String {
        rawValue.uppercased()
    }

    nonisolated var pathExtension: String {
        rawValue
    }

    nonisolated var isImageFormat: Bool {
        switch self {
        case .jpg, .png, .heic, .tiff, .bmp:
            return true
        default:
            return false
        }
    }

    nonisolated var isNativeSceneFormat: Bool {
        switch self {
        case .scn, .usd, .usda, .usdc, .usdz:
            return true
        default:
            return false
        }
    }

    nonisolated var utType: UTType? {
        switch self {
        case .jpg:
            return .jpeg
        case .png:
            return .png
        case .heic:
            return .heic
        case .tiff:
            return .tiff
        case .bmp:
            return .bmp
        case .scn:
            return UTType(filenameExtension: "scn")
        case .usd:
            return UTType(filenameExtension: "usd")
        case .usda:
            return UTType(filenameExtension: "usda")
        case .usdc:
            return UTType(filenameExtension: "usdc")
        case .usdz:
            return UTType(filenameExtension: "usdz")
        }
    }

    nonisolated static func availableTargets(for sourceFormat: FileFormat?)
        -> [FileFormat]
    {
        guard let sourceFormat else {
            return []
        }

        if sourceFormat.isImageFormat {
            return allCases.filter { $0.isImageFormat && $0 != sourceFormat }
        }

        if sourceFormat.isNativeSceneFormat {
            return allCases.filter {
                $0.isNativeSceneFormat && $0 != sourceFormat
            }
        }

        return []
    }

    nonisolated static func detect(from url: URL) -> FileFormat? {
        let ext = url.pathExtension.lowercased()

        switch ext {
        case "jpg", "jpeg":
            return .jpg
        case "png":
            return .png
        case "heic":
            return .heic
        case "tif", "tiff":
            return .tiff
        case "bmp":
            return .bmp
        case "scn":
            return .scn
        case "usd":
            return .usd
        case "usda":
            return .usda
        case "usdc":
            return .usdc
        case "usdz":
            return .usdz
        default:
            return nil
        }
    }
}
