//
//  PlannedSessionLogContext.swift
//  NurseryConnect
//
//  Feature: Daily Diary
//  Role: Keyworker
//  Created: 16 April 2026
//  Description: Prefill payload when logging from a planned session row (tap-to-log).
//

import Foundation

/// - Description: Binds the add-diary sheet to a schedule segment and supplies default time/type.
struct PlannedSessionLogContext: Identifiable, Hashable {
    let segment: NurseryScheduleSegment
    /// - Description: “Now” used to clamp the default log time into the segment window.
    let referenceNow: Date

    var id: String {
        "planned-\(segment.block.id)-\(segment.start.timeIntervalSince1970)"
    }

    /// - Description: Clamps `referenceNow` to `[segment.start, segment.end)` (half-open), using `end − 1s` if needed so the value stays inside the window.
    func defaultLogTimestamp(calendar: Calendar = .current) -> Date {
        let start = segment.start
        let end = segment.end
        guard end > start else { return start }
        let lastValid = end.addingTimeInterval(-1)
        let clamped = min(max(referenceNow, start), lastValid)
        return max(start, min(clamped, lastValid))
    }

    /// - Description: Suggested diary type when opening the form from this session.
    var suggestedEntryType: DiaryEntryType {
        switch segment.block.kind {
        case .meal: return .meal
        case .activity: return .activity
        }
    }

    /// - Description: Meal slot when this block is a meal window.
    var suggestedMealSlot: MealSlot? {
        segment.block.mealSlot
    }

    var sessionSubtitle: String {
        let range = "\(segment.start.formattedTime()) – \(segment.end.formattedTime())"
        return "For: \(segment.block.title) (\(range))"
    }
}
