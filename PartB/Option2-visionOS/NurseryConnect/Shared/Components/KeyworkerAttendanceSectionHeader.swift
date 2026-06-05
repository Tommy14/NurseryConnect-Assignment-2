//
//  KeyworkerAttendanceSectionHeader.swift
//  NurseryConnect
//
//  Feature: Dashboard
//  Role: Keyworker
//  Created: 29 May 2026
//  Description: Section title for attendance buckets; absent list collapses after 9 AM.
//

import SwiftUI

/// - Description: Overline section header with optional collapse control for the absent children bucket.
struct KeyworkerAttendanceSectionHeader: View {
    let bucket: KeyworkerAttendanceBucket
    let rowCount: Int
    var currentDate: Date = Date()
    @Binding var isAbsentSectionCollapsed: Bool

    private var canCollapseAbsent: Bool {
        bucket == .absent && NurseryDaySchedule.isAbsentSectionCollapsible(at: currentDate)
    }

    var body: some View {
        if canCollapseAbsent {
            Button {
                withAnimation(.easeInOut(duration: 0.22)) {
                    isAbsentSectionCollapsed.toggle()
                }
            } label: {
                HStack(spacing: 8) {
                    Text(bucket.sectionTitle)
                        .ncSectionOverlineStyle()
                    Text("\(rowCount)")
                        .font(.caption2.weight(.bold))
                        .foregroundStyle(Color.ncDanger)
                        .padding(.horizontal, 7)
                        .padding(.vertical, 3)
                        .background(Capsule(style: .continuous).fill(Color.ncDanger.opacity(0.14)))
                    Spacer(minLength: 0)
                    Image(systemName: isAbsentSectionCollapsed ? "chevron.down" : "chevron.up")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel(absentHeaderAccessibilityLabel)
            .accessibilityAddTraits(.isButton)
        } else {
            Text(bucket.sectionTitle)
                .ncSectionOverlineStyle()
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private var absentHeaderAccessibilityLabel: String {
        if isAbsentSectionCollapsed {
            return "Absent children, \(rowCount), collapsed. Double tap to expand."
        }
        return "Absent children, \(rowCount), expanded. Double tap to collapse."
    }
}
