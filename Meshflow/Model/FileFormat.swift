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
    case dae
    case usdz
    case obj
    case stl

    var id: String { rawValue }

    var title: String {
        rawValue.uppercased()
    }

    var pathExtension: String {
        rawValue
    }

    var isImageFormat: Bool {
        switch self {
        case .jpg, .png, .heic, .tiff, .bmp:
            return true
        default:
            return false
        }
    }

    var isSceneFormat: Bool {
        switch self {
        case .scn, .dae, .usdz:
            return true
        default:
            return false
        }
    }

    var isModelExportFormat: Bool {
        switch self {
        case .obj, .stl:
            return true
        default:
            return false
        }
    }

    var utType: UTType? {
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
        case .dae:
            return UTType(filenameExtension: "dae")
        case .usdz:
            return UTType(filenameExtension: "usdz")
        case .obj:
            return UTType(filenameExtension: "obj")
        case .stl:
            return UTType(filenameExtension: "stl")
        }
    }

    static func availableTargets(for sourceFormat: FileFormat?) -> [FileFormat]
    {
        guard let sourceFormat else {
            return []
        }

        if sourceFormat.isImageFormat {
            return allCases.filter { $0.isImageFormat && $0 != sourceFormat }
        }

        if sourceFormat.isSceneFormat {
            return allCases.filter {
                ($0.isSceneFormat || $0.isModelExportFormat)
                    && $0 != sourceFormat
            }
        }

        return []
    }

    static func detect(from url: URL) -> FileFormat? {
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
        case "dae":
            return .dae
        case "usdz":
            return .usdz
        case "obj":
            return .obj
        case "stl":
            return .stl
        default:
            return nil
        }
    }
}
