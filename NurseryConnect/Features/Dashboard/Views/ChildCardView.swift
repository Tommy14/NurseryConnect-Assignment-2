//
//  ChildCardView.swift
//  NurseryConnect
//
//  Feature: Dashboard
//  Role: Keyworker
//  Created: 2 April 2026
//  Description: List row showing a child avatar, name, age, and diary status capsule.
//
// -----------------------------------------------------------------
// Date       Name        What has done
// -----------------------------------------------------------------
// 020426     Tommy1914   Created the file with avatar, metadata, and status dot.
// 100426     Tommy1914   Let name/age use flexible width so long names wrap cleanly.
// 100426     Tommy1914   Diary status capsule, chevron, gradient card edge (iOS-native patterns).
// 100426     Tommy1914   Denser row height; status on one line to avoid mistaken “bar” when text wraps.
// 100426     Tommy1914   Leading gradient accent for dashboard list styling.
// 180426     Tommy1914   Reverted to single clean row: avatar, text, status, chevron (no banner rail).
// -----------------------------------------------------------------

import SwiftUI

/// - Description: One child row inside the keyworker dashboard list.
struct ChildCardView: View {
    let summary: KeyworkerChildSummary

    private var ageText: String {
        Date.earlyYearsAgeDescription(dateOfBirth: summary.dateOfBirth)
    }

    private var genderTitle: String {
        switch summary.genderTag {
        case .male: return "Boy"
        case .female: return "Girl"
        case .unspecified: return "Unspecified"
        }
    }

    private var genderSymbol: String {
        switch summary.genderTag {
        case .male: return "mars"
        case .female: return "venus"
        case .unspecified: return "person.fill.questionmark"
        }
    }

    private var genderColor: Color {
        switch summary.genderTag {
        case .male: return .blue
        case .female: return .pink
        case .unspecified: return .secondary
        }
    }

    private var genderBadge: some View {
        HStack(alignment: .center, spacing: 4) {
            Image(systemName: genderSymbol)
                .font(.caption2.weight(.semibold))
            Text(genderTitle)
                .font(.caption2.weight(.semibold))
        }
        .foregroundStyle(genderColor)
        .padding(.horizontal, 8)
        .padding(.vertical, 3)
        .background(
            Capsule(style: .continuous)
                .fill(genderColor.opacity(0.12))
        )
    }

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
        HStack(alignment: .center, spacing: 12) {
            ChildAvatarView(
                firstName: summary.firstName,
                lastName: summary.lastName,
                childId: summary.id,
                showsAccentRing: true,
                dimension: 44
            )

            VStack(alignment: .leading, spacing: 5) {
                Text("\(summary.firstName) \(summary.lastName)")
                    .font(.headline)
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                    .truncationMode(.tail)

                HStack(spacing: 6) {
                    Text(ageText)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Text("·")
                        .foregroundStyle(.tertiary)
                    genderBadge
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            VStack(alignment: .trailing, spacing: 6) {
                Text(diaryStatusTitle)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(dotColor)
                    .padding(.horizontal, 9)
                    .padding(.vertical, 5)
                    .background(Capsule(style: .continuous).fill(dotColor.opacity(0.14)))
                    .accessibilityLabel(diaryDotAccessibilityLabel)

                Image(systemName: "chevron.right")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.tertiary)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background {
            RoundedRectangle(cornerRadius: AppConstants.cardCornerRadius, style: .continuous)
                .fill(Color.ncCardSurface)
        }
        .overlay {
            RoundedRectangle(cornerRadius: AppConstants.cardCornerRadius, style: .continuous)
                .stroke(Color.primary.opacity(0.06), lineWidth: 1)
        }
        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 3)
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
            genderTag: .female,
            dot: .partial
        )
    )
    .padding()
    .background(Color.ncBackground)
}
