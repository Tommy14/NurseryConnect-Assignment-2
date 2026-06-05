//
//  KeyworkerAttendanceBucket.swift
//  NurseryConnect
//
//  Feature: Dashboard
//  Role: Keyworker
//  Created: 16 April 2026
//  Description: Derives today’s attendance grouping for dashboard sections and child cards.
//

import Foundation

/// - Description: One of four mutually exclusive buckets for a child’s attendance today (priority: departed → absent → on site → awaiting).
enum KeyworkerAttendanceBucket: Int, CaseIterable, Hashable, Sendable {
    case onSite
    case awaiting
    case absent
    case departed

    /// - Description: Stable section order on the dashboard (on site first for operational focus).
    static let dashboardSectionOrder: [KeyworkerAttendanceBucket] = [.onSite, .awaiting, .absent, .departed]

    /// - Description: Resolves bucket from today’s `AttendanceRecord` fields (see `AttendanceViewModel` invariants).
    /// - Parameters:
    ///   - checkOutAt: Departure time when set.
    ///   - checkInAt: Arrival time when set.
    ///   - markedAbsent: Persisted “not attending today” flag.
    static func resolve(checkOutAt: Date?, checkInAt: Date?, markedAbsent: Bool) -> KeyworkerAttendanceBucket {
        if checkOutAt != nil { return .departed }
        if markedAbsent { return .absent }
        if checkInAt != nil { return .onSite }
        return .awaiting
    }

    /// - Description: Section heading on the keyworker child list.
    var sectionTitle: String {
        switch self {
        case .onSite: return "On site"
        case .awaiting: return "Expecting children"
        case .absent: return "Absent children"
        case .departed: return "Left for the day"
        }
    }

    /// - Description: Short label for the child card capsule.
    var cardTitle: String {
        switch self {
        case .onSite: return "On site"
        case .awaiting: return "Awaiting check-in"
        case .absent: return "Absent"
        case .departed: return "Left"
        }
    }
}
