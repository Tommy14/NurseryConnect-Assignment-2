//
//  ChildSessionSchedule.swift
//  NurseryConnect
//
//  Feature: Attendance
//  Role: Keyworker
//  Created: 29 May 2026
//  Description: Resolves which calendar days a child is expected at nursery.
//

import Foundation

/// - Description: Parses a child's recurring session days and answers whether they are expected on a date.
enum ChildSessionSchedule {
    /// - Description: Mon–Fri using `Calendar` weekday components (Sunday = 1 … Saturday = 7).
    static let defaultWeekdays: Set<Int> = [2, 3, 4, 5, 6]

    /// - Description: Default Mon–Fri seed value stored on `Child.sessionWeekdays`.
    static let defaultWeekdaysStorageValue = "2,3,4,5,6"

    /// - Description: Parses comma/space separated weekday numbers; falls back to Mon–Fri when empty or invalid.
    static func weekdays(from stored: String?) -> Set<Int> {
        guard let stored else { return defaultWeekdays }
        let trimmed = stored.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.isEmpty == false else { return defaultWeekdays }

        let parts = trimmed.split { $0 == "," || $0 == " " || $0 == ";" }
        let parsed = parts.compactMap { Int($0.trimmingCharacters(in: .whitespaces)) }
            .filter { (1 ... 7).contains($0) }
        return parsed.isEmpty ? defaultWeekdays : Set(parsed)
    }

    /// - Description: True when the child’s recurring placement includes `date`’s weekday.
    static func isExpected(on date: Date, sessionWeekdays: String?, calendar: Calendar = .current) -> Bool {
        let weekday = calendar.component(.weekday, from: date)
        return weekdays(from: sessionWeekdays).contains(weekday)
    }
}
