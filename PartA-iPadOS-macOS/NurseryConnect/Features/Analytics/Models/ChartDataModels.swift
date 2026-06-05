//
//  ChartDataModels.swift
//  NurseryConnect
//
//  Feature: Analytics
//  Role: Keyworker
//  Created: 29 May 2026
//  Description: Value types for Swift Charts series and aggregates.
//

import Foundation

/// - Description: One day's averaged wellbeing mood for the mood trend chart.
struct MoodTrendPoint: Identifiable, Hashable {
    let day: Date
    let score: Double

    var id: Date { day }
}

/// - Description: Diary entry count for one type in the weekly activity chart.
struct WeeklyActivityCount: Identifiable, Hashable {
    let type: DiaryEntryType
    let count: Int

    var id: String { type.rawValue }
}

/// - Description: Attendance outcome for one calendar day in a child's monthly chart.
enum ChildAttendanceDayStatus: String, Hashable {
    case present
    case absent
    case unrecorded
}

/// - Description: One day's attendance status for the child monthly attendance timeline.
struct ChildMonthlyAttendanceDay: Identifiable, Hashable {
    let day: Date
    let status: ChildAttendanceDayStatus

    var id: Date { day }
}

/// - Description: Inbound message count for one day in the messaging sparkline.
struct MessageDayCount: Identifiable, Hashable {
    let day: Date
    let count: Int

    var id: Date { day }
}
