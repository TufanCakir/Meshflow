//
//  AppConfiguration.swift
//  Meshwork
//
//  Created by Tufan Cakir on 26.04.26.
//

import Foundation
import SwiftUI

struct AppConfiguration: Decodable {
    let defaultTheme: String
    let defaultLanguage: String
    let themes: [ThemeDefinition]
    let languages: [LanguageDefinition]
    let translations: [String: [String: String]]

    static let fallback = AppConfiguration(
        defaultTheme: "system",
        defaultLanguage: "de",
        themes: [
            ThemeDefinition(
                id: "system",
                displayNames: ["de": "Automatisch", "en": "Automatic"]
            ),
            ThemeDefinition(
                id: "light",
                displayNames: ["de": "Weiss", "en": "Light"]
            ),
            ThemeDefinition(
                id: "dark",
                displayNames: ["de": "Schwarz", "en": "Dark"]
            ),
        ],
        languages: [
            LanguageDefinition(id: "de", displayName: "Deutsch"),
            LanguageDefinition(id: "en", displayName: "English"),
        ],
        translations: [
            "de": [
                "target_format": "Zielformat",
                "convert": "Konvertieren",
                "share": "Exportieren / Teilen",
                "save_to_files": "In Dateien sichern",
                "pick_source": "Auswählen",
                "pick_file": "Datei wählen",
                "pick_photo": "Foto wählen",
                "drop_title": "Datei hier ablegen",
                "drop_subtitle":
                    "JPG, PNG, HEIC, TIFF, BMP, SCN, USD, USDA, USDC, USDZ",
                "no_file": "Keine Datei",
                "no_file_selected": "Keine Datei ausgewählt",
                "pick_or_drop_file": "Wähle eine Datei oder ziehe sie hinein.",
                "no_preview": "Keine Vorschau verfuegbar",
                "confirm_conversion_title": "Konvertierung starten?",
                "confirm_conversion_message":
                    "Moechtest du die ausgewählte Datei wirklich konvertieren?",
                "continue_action": "Fortfahren",
                "cancel_action": "Abbrechen",
                "converting": "Konvertiere...",
                "settings": "Einstellungen",
                "rate_app": "App bewerten",
                "theme": "Theme",
                "language": "Sprache",
                "loaded_file": "Datei geladen: %@",
                "finished_file": "Fertig: %@",
                "save_to_photos": "In Fotos speichern",
                "saved_to_photos": "In Fotos gespeichert: %@",
                "photo_access_denied":
                    "Bitte erlaube den Zugriff auf Fotos, um Bilder zu speichern.",
                "save_to_photos_failed":
                    "Bild konnte nicht in Fotos gespeichert werden.",
                "history": "Verlauf",
                "clear_history": "Verlauf leeren",
                "empty_history": "Noch keine Konvertierungen",
                "source_to_target": "%@ zu %@",
                "load_result": "Ergebnis laden",
                "file_info": "Datei-Info",
                "file_name": "Name",
                "file_format": "Format",
                "file_size": "Groesse",
                "unknown_format": "Unbekannt",
                "recommended_target": "Empfohlen: %@",
                "image_recommendation":
                    "PNG ist ein guter Standard fuer verlustfreien Austausch. JPG ist kleiner, wenn Dateigroesse wichtiger ist.",
                "scene_recommendation":
                    "USDZ ist am besten fuer Teilen, Vorschau und AR auf Apple-Geraeten.",
                "selected_files": "%d Dateien ausgewaehlt",
                "converted_files": "%d Dateien konvertiert",
                "remove_file": "Datei entfernen",
                "clear_selection": "Auswahl leeren",
                "results": "Ergebnisse",
                "failed_conversions":
                    "%d Dateien konnten nicht konvertiert werden",
                "before_after": "Vorher / Nachher",
                "before_size": "Vorher",
                "after_size": "Nachher",
                "export_failed": "Export fehlgeschlagen.",
                "export_finished": "Export gesichert.",
                "unsupported_format": "Dieses Format wird nicht unterstuetzt.",
                "invalid_conversion": "Diese Konvertierung ist nicht erlaubt.",
                "cannot_read_file": "Datei konnte nicht gelesen werden.",
                "conversion_failed": "Konvertierung fehlgeschlagen.",
            ],
            "en": [
                "target_format": "Target Format",
                "convert": "Convert",
                "share": "Export / Share",
                "save_to_files": "Save to Files",
                "pick_source": "Choose",
                "pick_file": "Pick File",
                "pick_photo": "Pick Photo",
                "drop_title": "Drop file here",
                "drop_subtitle":
                    "JPG, PNG, HEIC, TIFF, BMP, SCN, USD, USDA, USDC, USDZ",
                "no_file": "No File",
                "no_file_selected": "No file selected",
                "pick_or_drop_file": "Choose a file or drop it here.",
                "no_preview": "No preview available",
                "confirm_conversion_title": "Start conversion?",
                "confirm_conversion_message":
                    "Do you want to convert the selected file now?",
                "continue_action": "Continue",
                "cancel_action": "Cancel",
                "converting": "Converting...",
                "settings": "Settings",
                "rate_app": "Rate App",
                "theme": "Theme",
                "language": "Language",
                "loaded_file": "Loaded file: %@",
                "finished_file": "Done: %@",
                "save_to_photos": "Save to Photos",
                "saved_to_photos": "Saved to Photos: %@",
                "photo_access_denied": "Allow Photos access to save images.",
                "save_to_photos_failed":
                    "The image could not be saved to Photos.",
                "history": "History",
                "clear_history": "Clear History",
                "empty_history": "No conversions yet",
                "source_to_target": "%@ to %@",
                "load_result": "Load Result",
                "file_info": "File Info",
                "file_name": "Name",
                "file_format": "Format",
                "file_size": "Size",
                "unknown_format": "Unknown",
                "recommended_target": "Recommended: %@",
                "image_recommendation":
                    "PNG is a good default for lossless exchange. JPG is smaller when file size matters more.",
                "scene_recommendation":
                    "USDZ is best for sharing, preview, and AR on Apple devices.",
                "selected_files": "%d files selected",
                "converted_files": "%d files converted",
                "remove_file": "Remove file",
                "clear_selection": "Clear selection",
                "results": "Results",
                "failed_conversions": "%d files could not be converted",
                "before_after": "Before / After",
                "before_size": "Before",
                "after_size": "After",
                "export_failed": "Export failed.",
                "export_finished": "Export saved.",
                "unsupported_format": "This format is not supported.",
                "invalid_conversion": "This conversion is not allowed.",
                "cannot_read_file": "The file could not be read.",
                "conversion_failed": "Conversion failed.",
            ],
        ]
    )

    static func load() -> AppConfiguration {
        guard
            let url = Bundle.main.url(
                forResource: "AppConfiguration",
                withExtension: "json"
            ),
            let data = try? Data(contentsOf: url),
            let configuration = try? JSONDecoder().decode(
                AppConfiguration.self,
                from: data
            )
        else {
            return fallback
        }

        return configuration
    }
}

struct ThemeDefinition: Decodable, Identifiable, Hashable {
    let id: String
    let displayNames: [String: String]

    var colorScheme: ColorScheme? {
        switch id {
        case "light":
            return .light
        case "dark":
            return .dark
        default:
            return nil
        }
    }
}

struct LanguageDefinition: Decodable, Identifiable, Hashable {
    let id: String
    let displayName: String
}
