//
//  DiaryEntry+Audit.swift
//  NurseryConnect
//
//  Feature: Daily Diary
//  Role: Keyworker
//  Created: 16 April 2026
//  Description: Audit helpers for comparing event and submission timestamps.
//

import Foundation

extension DiaryEntry {
    /// - Description: True when event and submission times differ by more than the review threshold.
    var needsLateLogManagerReview: Bool {
        guard let eventTime = timestamp, let submittedAt else { return false }
        let gap = abs(submittedAt.timeIntervalSince(eventTime))
        return gap > AppConstants.diaryLateLogReviewThresholdSeconds
    }
}
