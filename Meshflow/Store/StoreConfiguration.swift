//
//  StoreConfiguration.swift
//  Meshflow
//
//  Created by Tufan Cakir on 26.04.26.
//

import Foundation

struct StoreConfiguration: Decodable {
    let freeLimits: UsageLimits
    let coinCosts: CoinCosts
    let products: [StoreProductDefinition]

    static let fallback = StoreConfiguration(
        freeLimits: UsageLimits(
            dailyConversions: 5,
            dailyExports: 5,
            storageSlots: 5
        ),
        coinCosts: CoinCosts(conversion: 1, export: 1, storageSlot: 2),
        products: []
    )

    static func load() -> StoreConfiguration {
        guard
            let url = Bundle.main.url(
                forResource: "StoreConfiguration",
                withExtension: "json"
            ),
            let data = try? Data(contentsOf: url),
            let configuration = try? JSONDecoder().decode(
                StoreConfiguration.self,
                from: data
            )
        else {
            return fallback
        }

        return configuration
    }
}

struct UsageLimits: Decodable {
    let dailyConversions: Int
    let dailyExports: Int
    let storageSlots: Int
}

struct CoinCosts: Decodable {
    let conversion: Int
    let export: Int
    let storageSlot: Int
}

struct StoreProductDefinition: Decodable, Identifiable, Hashable {
    let id: String
    let kind: StoreProductKind
    let productID: String?
    let coinAmount: Int?
    let displayNames: [String: String]
    let subtitles: [String: String]
    let benefits: [String: [String]]

    func displayName(languageID: String, fallbackLanguageID: String) -> String {
        displayNames[languageID] ?? displayNames[fallbackLanguageID] ?? id
    }

    func subtitle(languageID: String, fallbackLanguageID: String) -> String {
        subtitles[languageID] ?? subtitles[fallbackLanguageID] ?? ""
    }

    func localizedBenefits(languageID: String, fallbackLanguageID: String)
        -> [String]
    {
        benefits[languageID] ?? benefits[fallbackLanguageID] ?? []
    }
}

enum StoreProductKind: String, Decodable {
    case free
    case subscription
    case nonConsumable
    case consumable
}
