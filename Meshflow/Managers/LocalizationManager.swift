//
//  LocalizationManager.swift
//  Meshwork
//
//  Created by Codex on 27.04.26.
//

import Combine
import Foundation

enum AppTextKey: String {
    case targetFormat = "target_format"
    case convert = "convert"
    case share = "share"
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
    case theme = "theme"
    case language = "language"
    case loadedFile = "loaded_file"
    case finishedFile = "finished_file"
    case saveToPhotos = "save_to_photos"
    case savedToPhotos = "saved_to_photos"
    case photoAccessDenied = "photo_access_denied"
    case saveToPhotosFailed = "save_to_photos_failed"
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
