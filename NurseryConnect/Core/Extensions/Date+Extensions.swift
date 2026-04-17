//
//  Date+Extensions.swift
//  NurseryConnect
//
//  Feature: Core
//  Role: Keyworker
//  Created: 29 March 2026
//  Description: Shared date helpers for diary and incident timelines.
//
// -----------------------------------------------------------------
// Date       Name        What has done
// -----------------------------------------------------------------
// 290326     Tommy1914   Created the file with calendar range and formatting helpers.
// -----------------------------------------------------------------

import Foundation

extension Date {
    /// - Description: Start of the calendar day in the current locale’s time zone.
    var startOfDay: Date {
        Calendar.current.startOfDay(for: self)
    }

    /// - Description: End of the calendar day (exclusive next midnight) for range queries.
    var endOfDay: Date {
        let cal = Calendar.current
        guard let next = cal.date(byAdding: .day, value: 1, to: startOfDay) else {
            return self
        }
        return next
    }

    /// - Description: Whether this date falls on the same calendar day as another.
    /// - Parameters:
    ///   - other: Comparison date.
    /// - Returns: `true` when both share the same day.
    func isSameDay(as other: Date) -> Bool {
        Calendar.current.isDate(self, inSameDayAs: other)
    }

    /// - Description: Formats time for compact diary rows.
    /// - Parameters:
    ///   - style: DateFormatter style for time.
    /// - Returns: Localised time string.
    func formattedTime(style: DateFormatter.Style = .short) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = style
        formatter.dateStyle = .none
        return formatter.string(from: self)
    }

    /// - Description: Formats a medium date suitable for dashboard headers.
    /// - Returns: Localised date string.
    func formattedMediumDate() -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: self)
    }

    /// - Description: Human-readable early-years age from date of birth (years/months).
    /// - Parameters:
    ///   - dateOfBirth: Child’s date of birth.
    ///   - reference: Date used as “today” for the calculation (defaults to now).
    /// - Returns: Short age string such as “3 years, 2 months”, “8 months”, or “3 years”.
    static func earlyYearsAgeDescription(dateOfBirth: Date, reference: Date = Date()) -> String {
        guard reference >= dateOfBirth else { return "0 months" }
        let comps = Calendar.current.dateComponents([.year, .month], from: dateOfBirth, to: reference)
        let years = max(0, comps.year ?? 0)
        let months = max(0, comps.month ?? 0)

        if years > 0 {
            let yLabel = years == 1 ? "year" : "years"
            if months > 0 {
                let mLabel = months == 1 ? "month" : "months"
                return "\(years) \(yLabel), \(months) \(mLabel)"
            }
            return "\(years) \(yLabel)"
        }
        if months > 0 {
            let mLabel = months == 1 ? "month" : "months"
            return "\(months) \(mLabel)"
        }
        return "0 months"
    }
}
