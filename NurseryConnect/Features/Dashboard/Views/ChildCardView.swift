//
//  ChildCardView.swift
//  NurseryConnect
//
//  Feature: Dashboard
//  Role: Keyworker
//  Created: 2 April 2026
//  Description: List row showing a child avatar, name, room, and diary status capsule.
//
// -----------------------------------------------------------------
// Date       Name        What has done
// -----------------------------------------------------------------
// 020426     Tommy1914   Created the file with avatar, metadata, and status dot.
// 120426     Tommy1914   Let name/room use flexible width so long names wrap cleanly.
// 120426     Tommy1914   Diary status capsule, chevron, gradient card edge (iOS-native patterns).
// 120426     Tommy1914   Denser row height; status on one line to avoid mistaken “bar” when text wraps.
// 130426     Tommy1914   Leading gradient accent for dashboard list styling.
// -----------------------------------------------------------------

import SwiftUI

/// - Description: One child row inside the keyworker dashboard list.
struct ChildCardView: View {
    let summary: KeyworkerChildSummary

    private var dotColor: Color {
        switch summary.dot {
        case .complete: return Color.ncSecondary
        case .partial: return Color.ncAccentWarm
        case .none: return Color.ncDanger
        }
    }

    private var diaryStatusTitle: String {
        switch summary.dot {
        case .complete: return "Complete"
        case .partial: return "Partial"
        case .none: return "Needs logs"
        }
    }

    var body: some View {
        HStack(alignment: .center, spacing: 10) {
            ChildAvatarView(
                firstName: summary.firstName,
                lastName: summary.lastName,
                childId: summary.id,
                showsAccentRing: true,
                dimension: 40
            )
            VStack(alignment: .leading, spacing: 3) {
                Text("\(summary.firstName) \(summary.lastName)")
                    .font(.body.weight(.semibold))
                    .foregroundStyle(Color.primary)
                    .lineLimit(1)
                    .truncationMode(.tail)
                HStack(spacing: 4) {
                    Image(systemName: "door.left.hand.open")
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(.tertiary)
                    Text(summary.roomName)
                        .font(.caption.weight(.medium))
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .layoutPriority(1)

            HStack(spacing: 6) {
                Text(diaryStatusTitle)
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(dotColor)
                    .lineLimit(1)
                    .minimumScaleFactor(0.85)
                    .fixedSize(horizontal: true, vertical: false)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        Capsule(style: .continuous)
                            .fill(dotColor.opacity(0.14))
                    )
                    .accessibilityLabel(diaryDotAccessibilityLabel)
                Image(systemName: "chevron.right")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(.tertiary)
            }
            .layoutPriority(2)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background {
            RoundedRectangle(cornerRadius: AppConstants.cardCornerRadius, style: .continuous)
                .fill(Color.ncCardSurface)
                .shadow(color: Color.black.opacity(0.06), radius: 10, x: 0, y: 5)
        }
        .overlay {
            RoundedRectangle(cornerRadius: AppConstants.cardCornerRadius, style: .continuous)
                .stroke(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(0.65),
                            Color.ncPrimary.opacity(0.18),
                            Color.cyan.opacity(0.12)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
                .allowsHitTesting(false)
        }
        .overlay(alignment: .leading) {
            RoundedRectangle(cornerRadius: 2, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [Color.ncPrimary.opacity(0.95), Color.cyan.opacity(0.45)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(width: 3)
                .padding(.vertical, 10)
                .padding(.leading, 3)
                .allowsHitTesting(false)
        }
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
