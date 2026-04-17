//
//  NurseryDaySchedule.swift
//  NurseryConnect
//
//  Feature: Daily Diary
//  Role: Keyworker
//  Created: 18 April 2026
//  Description: Shared nursery timetable (meals + activity bands) for merging with per-child diary entries.
//

import Foundation

/// - Description: Whether a block is a fixed meal/snack window or a general activity band (sleep can override the latter in the merged timeline).
enum NurseryScheduleBlockKind: Equatable, Hashable {
    case meal(MealSlot)
    case activity
}

/// - Description: One row in the common nursery day plan.
struct NurseryScheduleBlock: Equatable, Hashable, Identifiable {
    let id: String
    let title: String
    let kind: NurseryScheduleBlockKind
    /// - Description: Minutes from midnight (local day) for block start.
    let startMinutesFromMidnight: Int
    /// - Description: Minutes from midnight for block end (exclusive if adjacent blocks abut).
    let endMinutesFromMidnight: Int

    /// - Description: True when this block represents a meal/snack slot used for allergy “near meal end” alerts.
    var isMealSlot: Bool {
        if case .meal = kind { return true }
        return false
    }

    /// - Description: Associated meal slot when `kind` is `.meal`.
    var mealSlot: MealSlot? {
        if case .meal(let slot) = kind { return slot }
        return nil
    }
}

/// - Description: A slice of a schedule block after splitting around sleep (or other) intervals.
struct NurseryScheduleSegment: Equatable, Hashable {
    let block: NurseryScheduleBlock
    let start: Date
    let end: Date
}

/// - Description: Default nursery routine and helpers for “now” and allergy windows.
enum NurseryDaySchedule {
    /// - Description: Local minutes from midnight when the standard session begins (08:00).
    static let sessionStartMinutesFromMidnight: Int = 8 * 60
    /// - Description: Local minutes from midnight when the standard session ends (18:00).
    static let sessionEndMinutesFromMidnight: Int = 18 * 60

    /// - Description: Minutes after official session end when diary logging remains allowed (wrap-up window).
    static let diaryLoggingGraceMinutesAfterSessionEnd: Int = 120

    /// - Description: Ordered blocks for a standard session (local times).
    static let defaultBlocks: [NurseryScheduleBlock] = [
        NurseryScheduleBlock(
            id: "breakfast",
            title: "Breakfast",
            kind: .meal(.breakfast),
            startMinutesFromMidnight: 8 * 60,
            endMinutesFromMidnight: 8 * 60 + 45
        ),
        NurseryScheduleBlock(
            id: "morning_welcome",
            title: "Morning welcome & indoor play",
            kind: .activity,
            startMinutesFromMidnight: 8 * 60 + 45,
            endMinutesFromMidnight: 10 * 60
        ),
        NurseryScheduleBlock(
            id: "morning_snack",
            title: "Morning snack",
            kind: .meal(.morningSnack),
            startMinutesFromMidnight: 10 * 60,
            endMinutesFromMidnight: 10 * 60 + 30
        ),
        NurseryScheduleBlock(
            id: "mid_morning",
            title: "Mid-morning activities",
            kind: .activity,
            startMinutesFromMidnight: 10 * 60 + 30,
            endMinutesFromMidnight: 12 * 60
        ),
        NurseryScheduleBlock(
            id: "lunch",
            title: "Lunch",
            kind: .meal(.lunch),
            startMinutesFromMidnight: 12 * 60,
            endMinutesFromMidnight: 13 * 60
        ),
        NurseryScheduleBlock(
            id: "quiet_rest",
            title: "Quiet time & rest",
            kind: .activity,
            startMinutesFromMidnight: 13 * 60,
            endMinutesFromMidnight: 14 * 60 + 30
        ),
        NurseryScheduleBlock(
            id: "afternoon_snack",
            title: "Afternoon snack",
            kind: .meal(.afternoonSnack),
            startMinutesFromMidnight: 14 * 60 + 30,
            endMinutesFromMidnight: 15 * 60
        ),
        NurseryScheduleBlock(
            id: "late_afternoon",
            title: "Late afternoon & pickup",
            kind: .activity,
            startMinutesFromMidnight: 15 * 60,
            endMinutesFromMidnight: 18 * 60
        )
    ]

    // MARK: - Date helpers

    /// - Description: Absolute start of `block` on the same calendar day as `reference`.
    static func startDate(for block: NurseryScheduleBlock, on reference: Date, calendar: Calendar = .current) -> Date {
        date(minutesFromMidnight: block.startMinutesFromMidnight, on: reference, calendar: calendar)
    }

    /// - Description: Absolute end of `block` on the same calendar day as `reference`.
    static func endDate(for block: NurseryScheduleBlock, on reference: Date, calendar: Calendar = .current) -> Date {
        date(minutesFromMidnight: block.endMinutesFromMidnight, on: reference, calendar: calendar)
    }

    private static func date(minutesFromMidnight: Int, on reference: Date, calendar: Calendar) -> Date {
        let startOfDay = calendar.startOfDay(for: reference)
        return calendar.date(byAdding: .minute, value: minutesFromMidnight, to: startOfDay) ?? startOfDay
    }

    /// - Description: Schedule block whose range contains `instant`, if any.
    static func blockContaining(_ instant: Date, on referenceDay: Date, calendar: Calendar = .current) -> NurseryScheduleBlock? {
        let sod = calendar.startOfDay(for: referenceDay)
        guard calendar.isDate(instant, inSameDayAs: sod) else { return nil }
        let mins = minutesFromMidnight(instant, calendar: calendar)
        return defaultBlocks.first { block in
            mins >= block.startMinutesFromMidnight && mins < block.endMinutesFromMidnight
        }
    }

    /// - Description: Minutes since local midnight for `date`.
    static func minutesFromMidnight(_ date: Date, calendar: Calendar = .current) -> Int {
        let sod = calendar.startOfDay(for: date)
        return Int(date.timeIntervalSince(sod) / 60.0)
    }

    /// - Description: Inclusive latest minute-of-day for diary logging: session end plus `diaryLoggingGraceMinutesAfterSessionEnd`.
    private static var diaryLoggingLatestMinuteFromMidnight: Int {
        sessionEndMinutesFromMidnight + diaryLoggingGraceMinutesAfterSessionEnd
    }

    /// - Description: Keyworkers may add diary entries from local session open through the grace period after closing (same calendar day as `reference`).
    static func isDiaryLoggingPermitted(at reference: Date, calendar: Calendar = .current) -> Bool {
        let sod = calendar.startOfDay(for: reference)
        guard calendar.isDate(reference, inSameDayAs: sod) else { return false }
        let mins = minutesFromMidnight(reference, calendar: calendar)
        return mins >= sessionStartMinutesFromMidnight && mins <= diaryLoggingLatestMinuteFromMidnight
    }

    /// - Description: True when `reference` falls in the last `minutes` before the end of any meal/snack block (allergies alert).
    static func isWithinMinutesBeforeAnyMealEnd(
        reference: Date,
        minutes: Int = 10,
        calendar: Calendar = .current
    ) -> Bool {
        let sod = calendar.startOfDay(for: reference)
        guard calendar.isDate(reference, inSameDayAs: sod) else { return false }
        let mins = minutesFromMidnight(reference, calendar: calendar)
        for block in defaultBlocks where block.isMealSlot {
            let end = block.endMinutesFromMidnight
            let windowStart = end - minutes
            if mins >= windowStart && mins < end { return true }
        }
        return false
    }

    /// - Description: True from `minutesBeforeStart` before any meal starts through that meal end (allergy visibility window on child cards).
    static func isWithinMealVisibilityWindow(
        reference: Date,
        minutesBeforeStart: Int = 5,
        calendar: Calendar = .current
    ) -> Bool {
        let sod = calendar.startOfDay(for: reference)
        guard calendar.isDate(reference, inSameDayAs: sod) else { return false }
        let mins = minutesFromMidnight(reference, calendar: calendar)
        for block in defaultBlocks where block.isMealSlot {
            let start = block.startMinutesFromMidnight
            let end = block.endMinutesFromMidnight
            let windowStart = start - minutesBeforeStart
            if mins >= windowStart && mins < end { return true }
        }
        return false
    }

    /// - Description: Human-readable “current activity” for the dashboard (uses sleep intervals from today’s entries when present).
    static func currentActivitySummary(
        referenceNow: Date,
        day: Date,
        sleepIntervals: [(start: Date, end: Date)],
        calendar: Calendar = .current
    ) -> String {
        scheduleOnlyActivitySummary(referenceNow: referenceNow, day: day, sleepIntervals: sleepIntervals, calendar: calendar)
    }

    /// - Description: When `usesAttendanceForActivityLine` is true and today has an attendance row, checkout / missing check-in override the schedule; otherwise behaviour matches `currentActivitySummary` without attendance.
    static func currentActivitySummary(
        referenceNow: Date,
        day: Date,
        sleepIntervals: [(start: Date, end: Date)],
        checkInAt: Date?,
        checkOutAt: Date?,
        usesAttendanceForActivityLine: Bool,
        calendar: Calendar = .current
    ) -> String {
        if usesAttendanceForActivityLine {
            if checkOutAt != nil {
                return "Checked out"
            }
            if checkInAt == nil {
                return "Not checked in"
            }
        }
        return scheduleOnlyActivitySummary(referenceNow: referenceNow, day: day, sleepIntervals: sleepIntervals, calendar: calendar)
    }

    private static func scheduleOnlyActivitySummary(
        referenceNow: Date,
        day: Date,
        sleepIntervals: [(start: Date, end: Date)],
        calendar: Calendar
    ) -> String {
        for interval in sleepIntervals {
            if referenceNow >= interval.start && referenceNow < interval.end {
                return "Sleeping"
            }
        }
        if let block = blockContaining(referenceNow, on: day, calendar: calendar) {
            return "Now: \(block.title)"
        }
        return "Outside nursery hours"
    }
}
