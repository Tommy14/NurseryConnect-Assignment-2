//
//  ChildSidebarRowView.swift
//  NurseryConnect
//
//  Feature: Dashboard
//  Role: Keyworker
//  Created: 29 May 2026
//  Description: Compact sidebar row for assigned children on iPad.
//

import SwiftUI

/// - Description: One child row in the iPad children sidebar.
struct ChildSidebarRowView: View {
    let summary: KeyworkerChildSummary
    var isSelected: Bool = false
    var currentDate: Date = Date()

    private var attendanceCapsuleTint: Color {
        switch summary.attendanceBucket {
        case .onSite: return Color.ncSecondary
        case .awaiting: return Color.ncAccentWarm
        case .absent: return Color.ncDanger
        case .departed: return Color.secondary
        }
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
        case .none: return "No logs"
        }
    }

    private var shouldShowNoLogsWarning: Bool {
        summary.attendanceBucket != .absent && summary.dot == .none
    }

    private var shouldShowNoPhotographyWarning: Bool {
        summary.attendanceBucket == .onSite && !summary.photoConsent
    }

    private var shouldShowDiaryStatusPill: Bool {
        summary.attendanceBucket != .absent
    }

    private var cardShape: RoundedRectangle {
        RoundedRectangle(cornerRadius: AppConstants.cardCornerRadius, style: .continuous)
    }

    var body: some View {
        HStack(alignment: .center, spacing: 8) {
            ChildAvatarView(
                firstName: summary.firstName,
                lastName: summary.lastName,
                childId: summary.id,
                showsAccentRing: false,
                dimension: 36
            )

            VStack(alignment: .leading, spacing: 5) {
                Text(compactDisplayName)
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                    .truncationMode(.tail)

                if shouldShowNoPhotographyWarning {
                    noPhotographyIconPill(tint: Color.ncDanger)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            VStack(alignment: .trailing, spacing: 5) {
                statusBadge
                HStack(spacing: 6) {
                    if shouldShowDiaryStatusPill {
                        diaryStatusPill
                    }
                }
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background { tileBackground }
        .overlay { tileBorderOverlay }
        .clipShape(cardShape)
        .shadow(
            color: isSelected ? Color.ncPrimary.opacity(0.2) : Color.clear,
            radius: isSelected ? 10 : 0,
            x: 0,
            y: isSelected ? 5 : 0
        )
        .listRowBackground(Color.clear)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilityLabel)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

    private var compactDisplayName: String {
        let first = summary.firstName.trimmingCharacters(in: .whitespacesAndNewlines)
        let fallbackFirst = first.isEmpty ? summary.preferredName.trimmingCharacters(in: .whitespacesAndNewlines) : first
        let baseFirst = fallbackFirst.isEmpty ? "Child" : fallbackFirst
        let lastInitial = summary.lastName
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .first
            .map { "\($0)." } ?? ""
        return lastInitial.isEmpty ? baseFirst : "\(baseFirst) \(lastInitial)"
    }

    private var tileBorderOverlay: some View {
        cardShape
            .strokeBorder(
                isSelected ? Color.ncPrimary.opacity(0.65) : Color.secondary.opacity(0.14),
                lineWidth: isSelected ? 2 : 1
            )
    }

    private var tileBackground: some View {
        cardShape
            .fill(isSelected ? Color.ncPrimary.opacity(0.08) : Color.white)
    }

    private var statusBadge: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(attendanceCapsuleTint)
                .frame(width: 5, height: 5)
            Text(summary.attendanceBucket.cardTitle)
                .font(.caption2.weight(.bold))
                .lineLimit(1)
        }
        .foregroundStyle(attendanceCapsuleTint)
        .padding(.horizontal, 7)
        .padding(.vertical, 4)
        .background(
            Capsule(style: .continuous)
                .fill(attendanceCapsuleTint.opacity(0.16))
        )
        .overlay {
            Capsule(style: .continuous)
                .strokeBorder(attendanceCapsuleTint.opacity(0.28), lineWidth: 1)
        }
    }

    private var diaryStatusPill: some View {
        HStack(spacing: 5) {
            Image(systemName: "exclamationmark.circle.fill")
                .font(.caption2.weight(.bold))
            Text(diaryStatusTitle)
                .font(.caption2.weight(.bold))
                .lineLimit(1)
        }
        .foregroundStyle(dotColor)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(
            Capsule(style: .continuous)
                .fill(dotColor.opacity(0.14))
        )
        .overlay {
            Capsule(style: .continuous)
                .strokeBorder(dotColor.opacity(0.24), lineWidth: 1)
        }
    }

    private func noPhotographyIconPill(tint: Color) -> some View {
        ZStack {
            Image(systemName: "camera.fill")
                .font(.caption2.weight(.bold))
                .foregroundStyle(Color.primary.opacity(0.92))
            Rectangle()
                .fill(tint)
                .frame(width: 11, height: 1.8)
                .rotationEffect(.degrees(-35))
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(
            Capsule(style: .continuous)
                .fill(tint.opacity(0.14))
        )
        .overlay {
            Capsule(style: .continuous)
                .strokeBorder(tint.opacity(0.24), lineWidth: 1)
        }
        .accessibilityLabel("No photography warning")
    }

    private var accessibilityLabel: String {
        var parts = ["\(summary.fullName), \(summary.attendanceBucket.cardTitle)"]
        if shouldShowNoLogsWarning { parts.append("No logs warning") }
        if shouldShowNoPhotographyWarning { parts.append("No photography warning") }
        return parts.joined(separator: ", ")
    }
}
