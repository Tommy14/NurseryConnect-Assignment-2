//
//  ChildCardView.swift
//  NurseryConnect
//
//  Feature: Dashboard
//  Role: Keyworker
//  Created: 2 April 2026
//  Description: Grid tile showing a child avatar, name, room, and diary completeness dot.
//
// -----------------------------------------------------------------
// Date       Name        What has done
// -----------------------------------------------------------------
// 020426     Tommy1914   Created the file with avatar, metadata, and status dot.
// -----------------------------------------------------------------

import SwiftUI

/// - Description: One child tile inside the keyworker dashboard grid.
struct ChildCardView: View {
    let summary: KeyworkerChildSummary

    private var dotColor: Color {
        switch summary.dot {
        case .complete: return Color.ncSecondary
        case .partial: return Color.ncAccentWarm
        case .none: return Color.ncDanger
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .center, spacing: 12) {
                ChildAvatarView(firstName: summary.firstName, lastName: summary.lastName, childId: summary.id)
                VStack(alignment: .leading, spacing: 4) {
                    Text("\(summary.firstName) \(summary.lastName)")
                        .font(.headline)
                        .foregroundStyle(Color.primary)
                    Text(summary.roomName)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                Spacer(minLength: 0)
                Circle()
                    .fill(dotColor)
                    .frame(width: 12, height: 12)
                    .accessibilityLabel(diaryDotAccessibilityLabel)
            }
        }
        .padding(12)
        .ncCardStyle()
        .accessibilityElement(children: .combine)
        .accessibilityHint("Opens today’s diary for this child.")
    }

    private var diaryDotAccessibilityLabel: String {
        switch summary.dot {
        case .complete: return "Diary completeness: complete for today"
        case .partial: return "Diary completeness: partially logged today"
        case .none: return "Diary completeness: nothing logged yet today"
        }
    }
}

#Preview {
    ChildCardView(
        summary: KeyworkerChildSummary(
            id: UUID(),
            firstName: "Emma",
            lastName: "Wilson",
            roomName: "Sunshine Room",
            allergies: "Peanuts",
            dateOfBirth: Date(),
            dot: .partial
        )
    )
    .padding()
    .background(Color.ncBackground)
}
