//
//  ChildMonthlyAttendanceChart.swift
//  NurseryConnect
//
//  Feature: Analytics
//  Role: Keyworker
//  Created: 29 May 2026
//  Description: Daily present/absent timeline for one child in the current month.
//

import Charts
import CoreData
import SwiftUI

/// - Description: Bar chart of each day's attendance status for a single assigned child.
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

    private var hasRecordedDays: Bool {
        days.contains { $0.status != .unrecorded }
    }

    var body: some View {
        Group {
            if days.isEmpty {
                ContentUnavailableView {
                    Label("No attendance data", systemImage: "calendar")
                } description: {
                    Text("Days in \(childDisplayName)'s attendance record for this month will appear here.")
                }
                .frame(height: 220)
            } else {
                VStack(alignment: .leading, spacing: 10) {
                    HStack(spacing: 16) {
                        summaryPill(label: "Present", count: summary.present, color: Color(.systemGreen))
                        summaryPill(label: "Absent", count: summary.absent, color: Color.ncAccentWarm)
                    }

                    Chart(days) { dayPoint in
                        BarMark(
                            x: .value("Day", dayPoint.day, unit: .day),
                            y: .value("Recorded", 1)
                        )
                        .foregroundStyle(color(for: dayPoint.status))
                        .cornerRadius(2)
                    }
                    .chartYAxis(.hidden)
                    .chartYScale(domain: 0...1)
                    .chartXAxis {
                        AxisMarks(values: .stride(by: .day, count: 7)) { value in
                            AxisGridLine()
                            AxisValueLabel(format: .dateTime.day())
                        }
                    }
                    .chartLegend(.hidden)
                    .frame(height: 200)

                    HStack(spacing: 14) {
                        legendItem(label: "Present", color: Color(.systemGreen))
                        legendItem(label: "Absent", color: Color.ncAccentWarm)
                        legendItem(label: "No record", color: Color(.tertiaryLabel))
                    }
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                }
                .animation(.easeInOut, value: days)
                .transition(.opacity.combined(with: .scale(scale: 0.98)))
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel(accessibilitySummary)
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

    private func legendItem(label: String, color: Color) -> some View {
        HStack(spacing: 4) {
            Circle()
                .fill(color)
                .frame(width: 6, height: 6)
            Text(label)
        }
    }

    private func color(for status: ChildAttendanceDayStatus) -> Color {
        switch status {
        case .present: return Color(.systemGreen)
        case .absent: return Color.ncAccentWarm
        case .unrecorded: return Color(.tertiaryLabel).opacity(0.35)
        }
    }

    private var accessibilitySummary: String {
        if !hasRecordedDays {
            return "Monthly attendance for \(childDisplayName). No present or absent days recorded yet this month."
        }
        return "Monthly attendance for \(childDisplayName). \(summary.present) present days and \(summary.absent) absent days this month."
    }
}
