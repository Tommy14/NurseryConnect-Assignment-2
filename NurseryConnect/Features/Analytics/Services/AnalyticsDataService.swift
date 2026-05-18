//
//  AnalyticsDataService.swift
//  NurseryConnect
//
//  Feature: Analytics
//  Role: Keyworker
//  Created: 29 May 2026
//  Description: Aggregates Core Data rows into chart-ready value types.
//

import CoreData
import Foundation

/// - Description: Pure helpers for grouping diary, attendance, and message data for charts.
enum AnalyticsDataService {
    // MARK: - Mood trend

    /// - Description: Averages wellbeing mood ratings per calendar day over the last seven days.
    static func moodTrendPoints(from entries: [DiaryEntry], reference: Date = Date()) -> [MoodTrendPoint] {
        let days = Date.lastSevenCalendarDays(endingOn: reference)
        let cal = Calendar.current
        var ratingsByDay: [Date: [Int]] = [:]

        for entry in entries {
            guard DiaryEntryType.fromPersistence(entry.entryType ?? "") == .wellbeing,
                  entry.moodRating > 0,
                  let timestamp = entry.timestamp else { continue }
            let day = timestamp.startOfDay
            ratingsByDay[day, default: []].append(Int(entry.moodRating))
        }

        return days.compactMap { day in
            guard let ratings = ratingsByDay[day], !ratings.isEmpty else { return nil }
            let average = Double(ratings.reduce(0, +)) / Double(ratings.count)
            return MoodTrendPoint(day: day, score: average)
        }
    }

    /// - Description: Mean mood score across available trend points (for welfare threshold checks).
    static func averageMoodScore(from points: [MoodTrendPoint]) -> Double? {
        guard !points.isEmpty else { return nil }
        return points.map(\.score).reduce(0, +) / Double(points.count)
    }

    // MARK: - Weekly activity

    /// - Description: Counts diary entries by type for the current calendar week.
    static func weeklyActivityCounts(from entries: [DiaryEntry]) -> [WeeklyActivityCount] {
        DiaryEntryType.allCases.map { type in
            let count = entries.filter { DiaryEntryType.fromPersistence($0.entryType ?? "") == type }.count
            return WeeklyActivityCount(type: type, count: count)
        }
    }

    // MARK: - Monthly attendance

    /// - Description: Calendar-day attendance status for one child from month start through today.
    static func childMonthlyAttendanceDays(
        from records: [AttendanceRecord],
        reference: Date = Date()
    ) -> [ChildMonthlyAttendanceDay] {
        let cal = Calendar.current
        let monthStart = reference.startOfMonth
        let today = reference.startOfDay
        var recordByDay: [Date: AttendanceRecord] = [:]

        for record in records {
            guard let dayStart = record.dayStart?.startOfDay,
                  dayStart >= monthStart,
                  dayStart < reference.endOfMonth else { continue }
            recordByDay[dayStart] = record
        }

        var days: [ChildMonthlyAttendanceDay] = []
        var cursor = monthStart
        while cursor <= today {
            let status: ChildAttendanceDayStatus
            if let record = recordByDay[cursor] {
                if record.markedAbsent {
                    status = .absent
                } else if record.checkInAt != nil {
                    status = .present
                } else {
                    status = .unrecorded
                }
            } else {
                status = .unrecorded
            }
            days.append(ChildMonthlyAttendanceDay(day: cursor, status: status))
            guard let next = cal.date(byAdding: .day, value: 1, to: cursor) else { break }
            cursor = next.startOfDay
        }
        return days
    }

    /// - Description: Present and absent day totals from a child's monthly day series.
    static func childMonthlyAttendanceSummary(from days: [ChildMonthlyAttendanceDay]) -> (present: Int, absent: Int) {
        var present = 0
        var absent = 0
        for day in days {
            switch day.status {
            case .present: present += 1
            case .absent: absent += 1
            case .unrecorded: break
            }
        }
        return (present, absent)
    }

    // MARK: - Message activity

    /// - Description: Inbound (non-keyworker) message counts per day for the last seven days.
    static func messageDayCounts(from messages: [Message], reference: Date = Date()) -> [MessageDayCount] {
        let days = Date.lastSevenCalendarDays(endingOn: reference)
        let cal = Calendar.current
        var countsByDay: [Date: Int] = [:]

        for message in messages {
            guard let sentAt = message.sentAt else { continue }
            let day = sentAt.startOfDay
            guard days.contains(where: { cal.isDate($0, inSameDayAs: day) }) else { continue }
            countsByDay[day, default: 0] += 1
        }

        return days.map { day in
            MessageDayCount(day: day, count: countsByDay[day, default: 0])
        }
    }

    // MARK: - Predicates

    /// - Description: Fetch predicate for wellbeing entries in the last seven days for one child.
    static func wellbeingLastSevenDaysPredicate(childID: UUID, reference: Date = Date()) -> NSPredicate {
        let sevenDaysAgo = Calendar.current.date(byAdding: .day, value: -6, to: reference.startOfDay) ?? reference.startOfDay
        return NSCompoundPredicate(andPredicateWithSubpredicates: [
            NSPredicate(format: "child.id == %@", childID as CVarArg),
            NSPredicate(format: "entryType == %@", DiaryEntryType.wellbeing.persistenceValue),
            NSPredicate(format: "moodRating > 0"),
            NSPredicate(format: "timestamp >= %@", sevenDaysAgo as NSDate)
        ])
    }

    /// - Description: Fetch predicate for diary entries in the current calendar week for one child.
    static func diaryCurrentWeekPredicate(childID: UUID, reference: Date = Date()) -> NSPredicate {
        NSCompoundPredicate(andPredicateWithSubpredicates: [
            NSPredicate(format: "child.id == %@", childID as CVarArg),
            NSPredicate(format: "timestamp >= %@", reference.startOfWeek as NSDate),
            NSPredicate(format: "timestamp < %@", reference.endOfWeek as NSDate)
        ])
    }

    /// - Description: Fetch predicate for one child's attendance records in the current month.
    static func attendanceCurrentMonthPredicate(childID: UUID, reference: Date = Date()) -> NSPredicate {
        NSCompoundPredicate(andPredicateWithSubpredicates: [
            NSPredicate(format: "child.id == %@", childID as CVarArg),
            NSPredicate(format: "dayStart >= %@", reference.startOfMonth as NSDate),
            NSPredicate(format: "dayStart < %@", reference.endOfMonth as NSDate)
        ])
    }
}
