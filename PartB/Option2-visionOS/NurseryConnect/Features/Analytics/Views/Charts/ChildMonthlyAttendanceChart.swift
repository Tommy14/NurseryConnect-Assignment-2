//
//  ChildMonthlyAttendanceChart.swift
//  NurseryConnect
//
//  Feature: Analytics
//  Role: Keyworker
//  Created: 29 May 2026
//  Description: Calendar dot-grid of daily attendance for a single child in the current month.
//

import CoreData
import SwiftUI

/// - Description: Calendar-style dot grid showing each day's attendance status for the current month.
struct ChildMonthlyAttendanceChart: View {
    let childID: UUID
    let childDisplayName: String

    @FetchRequest private var attendanceRecords: FetchedResults<AttendanceRecord>

    init(childID: UUID, childDisplayName: String) {
        self.childID = childID
        self.childDisplayName = childDisplayName
        _attendanceRecords = FetchRequest(
            sortDescriptors: [NSSortDescriptor(keyPath: \AttendanceRecord.dayStart, ascending: true)],
            predicate: AnalyticsDataService.attendanceCurrentMonthPredicate(childID: childID),
            animation: .default
        )
    }

    private var days: [ChildMonthlyAttendanceDay] {
        AnalyticsDataService.childMonthlyAttendanceDays(from: Array(attendanceRecords))
    }

    private var summary: (present: Int, absent: Int) {
        AnalyticsDataService.childMonthlyAttendanceSummary(from: days)
    }

    private static let weekdayHeaders = ["M", "T", "W", "T", "F", "S", "S"]

    var body: some View {
        Group {
            if days.isEmpty {
                emptyState
            } else {
                VStack(alignment: .leading, spacing: 12) {
                    HStack(spacing: 16) {
                        summaryPill(label: "Present", count: summary.present, color: Color(.systemGreen))
                        summaryPill(label: "Absent",  count: summary.absent,  color: Color(.systemRed))
                    }

                    calendarGrid
                    legendRow
                }
                .animation(.spring(response: 0.4, dampingFraction: 0.85), value: days.count)
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel(accessibilitySummary)
    }

    // MARK: - Calendar grid

    private var calendarGrid: some View {
        let leadingBlanks = leadingBlankCount
        let columns = Array(repeating: GridItem(.flexible(minimum: 20, maximum: 38), spacing: 4), count: 7)

        return LazyVGrid(columns: columns, spacing: 4) {
            // Weekday headers in the same grid so columns stay aligned
            ForEach(0..<7, id: \.self) { i in
                Text(Self.weekdayHeaders[i])
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(.tertiary)
                    .frame(maxWidth: .infinity)
            }

            // Leading blank cells
            ForEach(0..<leadingBlanks, id: \.self) { _ in
                Color.clear.aspectRatio(1, contentMode: .fit)
            }

            // Day dots
            ForEach(days) { day in
                dayDot(day)
            }
        }
    }

    private func dayDot(_ day: ChildMonthlyAttendanceDay) -> some View {
        let cal = Calendar.current
        let isToday = cal.isDateInToday(day.day)
        let isFuture = day.day > cal.startOfDay(for: Date())
        let dotColor = color(for: day.status)
        let dayNumber = cal.component(.day, from: day.day)

        return ZStack {
            Circle()
                .fill(dotColor.opacity(
                    isFuture              ? 0.0 :
                    day.status == .unrecorded ? 0.12 : 0.88
                ))
            if isToday {
                Circle().strokeBorder(Color.ncPrimary, lineWidth: 1.5)
            }
            Text("\(dayNumber)")
                .font(.system(size: 11, weight: .bold, design: .rounded))
                .foregroundStyle(
                    isFuture              ? Color(.tertiaryLabel) :
                    day.status == .unrecorded ? Color.primary.opacity(0.55) :
                    Color.white
                )
        }
        .aspectRatio(1, contentMode: .fit)
        .accessibilityLabel(dotAccessibilityLabel(day))
    }

    // MARK: - Helpers

    private var leadingBlankCount: Int {
        guard let firstDay = days.first?.day else { return 0 }
        var weekday = Calendar.current.component(.weekday, from: firstDay)
        // Convert Sun=1…Sat=7 → Mon=0…Sun=6
        weekday = (weekday + 5) % 7
        return weekday
    }

    private func color(for status: ChildAttendanceDayStatus) -> Color {
        switch status {
        case .present:    return Color(.systemGreen)
        case .absent:     return Color(.systemRed)
        case .unrecorded: return Color(.tertiaryLabel)
        }
    }

    private var emptyState: some View {
        VStack(spacing: 8) {
            Image(systemName: "calendar")
                .font(.largeTitle)
                .foregroundStyle(.tertiary)
            Text("No attendance data")
                .font(.headline)
                .foregroundStyle(.secondary)
            Text("Days in \(childDisplayName)'s attendance record for this month will appear here.")
                .font(.caption)
                .foregroundStyle(.tertiary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 180)
        .padding()
    }

    private func summaryPill(label: String, count: Int, color: Color) -> some View {
        HStack(spacing: 6) {
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)
            Text("\(label): \(count)")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
        }
    }

    private var legendRow: some View {
        HStack(spacing: 14) {
            legendItem(label: "Present",   color: Color(.systemGreen))
            legendItem(label: "Absent",    color: Color(.systemRed))
            legendItem(label: "No record", color: Color(.tertiaryLabel))
        }
        .font(.caption2)
        .foregroundStyle(.secondary)
    }

    private func legendItem(label: String, color: Color) -> some View {
        HStack(spacing: 4) {
            Circle().fill(color).frame(width: 6, height: 6)
            Text(label)
        }
    }

    private func dotAccessibilityLabel(_ day: ChildMonthlyAttendanceDay) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        let dateStr = formatter.string(from: day.day)
        let isFuture = day.day > Calendar.current.startOfDay(for: Date())
        switch day.status {
        case .present:    return "\(dateStr): present"
        case .absent:     return "\(dateStr): absent"
        case .unrecorded: return isFuture ? "\(dateStr): upcoming" : "\(dateStr): no record"
        }
    }

    private var accessibilitySummary: String {
        "Monthly attendance for \(childDisplayName). \(summary.present) present, \(summary.absent) absent this month."
    }
}
