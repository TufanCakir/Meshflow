//
//  ReviewPromptManager.swift
//  Meshflow
//
//  Created by Tufan Cakir on 26.04.26.
//

import Combine
import Foundation

final class ReviewPromptManager: ObservableObject {
    private enum StorageKey {
        static let successfulConversionCount =
            "review.successfulConversionCount"
        static let lastAutomaticPromptDate = "review.lastAutomaticPromptDate"
        static let automaticPromptCount = "review.automaticPromptCount"
    }

    private let defaults: UserDefaults
    private let calendar: Calendar
    private let minimumSuccessfulConversions = 2
    private let minimumDaysBetweenPrompts = 30
    private let maximumAutomaticPrompts = 3

    init(
        defaults: UserDefaults = .standard,
        calendar: Calendar = .current
    ) {
        self.defaults = defaults
        self.calendar = calendar
    }

    func shouldRequestReviewAfterSuccessfulConversion(count: Int) -> Bool {
        guard count > 0 else { return false }

        let successfulConversionCount =
            defaults.integer(
                forKey: StorageKey.successfulConversionCount
            ) + count
        defaults.set(
            successfulConversionCount,
            forKey: StorageKey.successfulConversionCount
        )

        guard successfulConversionCount >= minimumSuccessfulConversions else {
            return false
        }

        let automaticPromptCount = defaults.integer(
            forKey: StorageKey.automaticPromptCount
        )
        guard automaticPromptCount < maximumAutomaticPrompts else {
            return false
        }

        if let lastPromptDate = defaults.object(
            forKey: StorageKey.lastAutomaticPromptDate
        ) as? Date {
            guard
                let nextAllowedDate = calendar.date(
                    byAdding: .day,
                    value: minimumDaysBetweenPrompts,
                    to: lastPromptDate
                ),
                Date() >= nextAllowedDate
            else {
                return false
            }
        }

        defaults.set(Date(), forKey: StorageKey.lastAutomaticPromptDate)
        defaults.set(
            automaticPromptCount + 1,
            forKey: StorageKey.automaticPromptCount
        )
        return true
    }
}
