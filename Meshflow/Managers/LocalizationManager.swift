//
//  LocalizationManager.swift
//  Meshwork
//
//  Created by Tufan Cakir on 26.04.26.
//

import Combine
import Foundation

enum AppTextKey: String {
    case targetFormat = "target_format"
    case convert = "convert"
    case share = "share"
    case saveToFiles = "save_to_files"
    case pickSource = "pick_source"
    case pickFile = "pick_file"
    case pickPhoto = "pick_photo"
    case dropTitle = "drop_title"
    case dropSubtitle = "drop_subtitle"
    case noFile = "no_file"
    case noFileSelected = "no_file_selected"
    case pickOrDropFile = "pick_or_drop_file"
    case noPreview = "no_preview"
    case confirmConversionTitle = "confirm_conversion_title"
    case confirmConversionMessage = "confirm_conversion_message"
    case continueAction = "continue_action"
    case cancelAction = "cancel_action"
    case converting = "converting"
    case settings = "settings"
    case rateApp = "rate_app"
    case theme = "theme"
    case language = "language"
    case loadedFile = "loaded_file"
    case finishedFile = "finished_file"
    case saveToPhotos = "save_to_photos"
    case savedToPhotos = "saved_to_photos"
    case photoAccessDenied = "photo_access_denied"
    case saveToPhotosFailed = "save_to_photos_failed"
    case history = "history"
    case clearHistory = "clear_history"
    case emptyHistory = "empty_history"
    case sourceToTarget = "source_to_target"
    case loadResult = "load_result"
    case fileInfo = "file_info"
    case fileName = "file_name"
    case fileFormat = "file_format"
    case fileSize = "file_size"
    case unknownFormat = "unknown_format"
    case recommendedTarget = "recommended_target"
    case imageRecommendation = "image_recommendation"
    case sceneRecommendation = "scene_recommendation"
    case selectedFiles = "selected_files"
    case convertedFiles = "converted_files"
    case removeFile = "remove_file"
    case clearSelection = "clear_selection"
    case results = "results"
    case failedConversions = "failed_conversions"
    case beforeAfter = "before_after"
    case beforeSize = "before_size"
    case afterSize = "after_size"
    case exportFailed = "export_failed"
    case exportFinished = "export_finished"
    case unsupportedFormat = "unsupported_format"
    case invalidConversion = "invalid_conversion"
    case cannotReadFile = "cannot_read_file"
    case conversionFailed = "conversion_failed"
}

final class LocalizationManager: ObservableObject {
    @Published var selectedLanguageID: String {
        didSet {
            UserDefaults.standard.set(
                selectedLanguageID,
                forKey: Self.storageKey
            )
        }
    }

    let languages: [LanguageDefinition]

    private static let storageKey = "selectedLanguageID"
    private let defaultLanguageID: String
    private let translations: [String: [String: String]]

    init(configuration: AppConfiguration) {
        languages = configuration.languages
        translations = configuration.translations
        defaultLanguageID = configuration.defaultLanguage

        let storedLanguage = UserDefaults.standard.string(
            forKey: Self.storageKey
        )
        let initialLanguage = storedLanguage ?? configuration.defaultLanguage

        if languages.contains(where: { $0.id == initialLanguage }) {
            selectedLanguageID = initialLanguage
        } else {
            selectedLanguageID = configuration.defaultLanguage
        }
    }

    var locale: Locale {
        Locale(identifier: selectedLanguageID)
    }

    func text(_ key: AppTextKey) -> String {
        if let value = translations[selectedLanguageID]?[key.rawValue] {
            return value
        }

        if let value = translations[defaultLanguageID]?[key.rawValue] {
            return value
        }

        return key.rawValue
    }

    func text(_ key: AppTextKey, _ arguments: CVarArg...) -> String {
        String(format: text(key), locale: locale, arguments: arguments)
    }

    func themeTitle(for theme: ThemeDefinition) -> String {
        theme.displayNames[selectedLanguageID]
            ?? theme.displayNames[defaultLanguageID]
            ?? theme.id.capitalized
    }

    func conversionErrorMessage(for error: Error) -> String {
        guard let conversionError = error as? ConversionError else {
            return error.localizedDescription
        }

        switch conversionError {
        case .unsupportedFormat:
            return text(.unsupportedFormat)
        case .invalidConversion:
            return text(.invalidConversion)
        case .cannotReadFile:
            return text(.cannotReadFile)
        case .conversionFailed:
            return text(.conversionFailed)
        }
    }
}
