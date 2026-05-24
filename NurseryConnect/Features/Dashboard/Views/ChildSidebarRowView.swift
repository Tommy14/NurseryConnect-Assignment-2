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

    private var allergiesTrimmed: String {
        summary.allergies.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var shouldShowAttendanceWarnings: Bool {
        summary.attendanceBucket == .onSite
    }

    private var shouldFlashAllergies: Bool {
        !allergiesTrimmed.isEmpty && NurseryDaySchedule.isWithinMinutesBeforeAnyMealEnd(reference: currentDate)
    }

    private var shouldShowAllergies: Bool {
        shouldShowAttendanceWarnings
            && !allergiesTrimmed.isEmpty
            && NurseryDaySchedule.isWithinMealVisibilityWindow(reference: currentDate, minutesBeforeStart: 5)
    }

    private var moodTint: Color { AppTheme.diaryColor(for: .wellbeing) }

    private var moodStep: Int {
        guard let rating = summary.latestMoodRating, rating > 0 else { return 0 }
        return min(5, max(1, Int(rating)))
    }

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

    private var shouldShowDiaryStatusCapsule: Bool {
        !(summary.dot == .none && summary.attendanceBucket != .onSite)
    }

    private var cardShape: RoundedRectangle {
        RoundedRectangle(cornerRadius: AppConstants.cardCornerRadius, style: .continuous)
    }

    var body: some View {
        HStack(spacing: 0) {
            accentRail

            VStack(alignment: .leading, spacing: 8) {
                HStack(alignment: .center, spacing: 10) {
                    ChildAvatarView(
                        firstName: summary.firstName,
                        lastName: summary.lastName,
                        childId: summary.id,
                        showsAccentRing: isSelected,
                        dimension: 40
                    )

                    VStack(alignment: .leading, spacing: 4) {
                        Text(summary.fullName)
                            .font(.subheadline.weight(.bold))
                            .foregroundStyle(.primary)
                            .lineLimit(2)
                            .minimumScaleFactor(0.85)
                            .multilineTextAlignment(.leading)

                        if moodStep > 0 {
                            moodHeartRow
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)

                    VStack(alignment: .trailing, spacing: 5) {
                        statusBadge

                        if shouldShowDiaryStatusCapsule {
                            diaryStatusPill
                        }

                        if shouldShowAllergies || (shouldShowAttendanceWarnings && summary.hasOpenIncident) {
                            HStack(spacing: 6) {
                                if shouldShowAllergies {
                                    Image(systemName: "exclamationmark.triangle.fill")
                                        .font(.caption.weight(.bold))
                                        .foregroundStyle(Color.red.opacity(shouldFlashAllergies ? 1 : 0.88))
                                        .accessibilityLabel("Allergy alert")
                                }

                                if shouldShowAttendanceWarnings && summary.hasOpenIncident {
                                    Image(systemName: "exclamationmark.octagon.fill")
                                        .font(.caption.weight(.bold))
                                        .foregroundStyle(Color.ncDanger)
                                        .accessibilityLabel("Open incident")
                                }
                            }
                        }
                    }
                }
                .accessibilityElement(children: .ignore)
                .accessibilityLabel(sidebarRowAccessibilityLabel)

                if shouldShowAttendanceWarnings && !summary.photoConsent {
                    photoConsentWarningBanner
                }
            }
            .padding(.leading, 12)
            .padding(.trailing, 12)
            .padding(.vertical, 11)
        }
        .background { tileBackground }
        .overlay { tileBorderOverlay }
        .clipShape(cardShape)
        .listRowBackground(Color.clear)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

    private var tileBorderOverlay: some View {
        ZStack {
            cardShape
                .strokeBorder(
                    tileBorderGradient,
                    lineWidth: isSelected ? 2.5 : 2
                )
            cardShape
                .strokeBorder(
                    Color.ncGlassHighlight(lightOpacity: isSelected ? 0.55 : 0.42),
                    lineWidth: 1
                )
                .padding(1)
        }
    }

    private var tileBorderGradient: LinearGradient {
        if isSelected {
            return LinearGradient(
                colors: [
                    Color.ncPrimary,
                    Color.ncGlowBlue.opacity(0.85),
                    Color.ncGlowViolet.opacity(0.75)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
        return LinearGradient(
            colors: [
                attendanceCapsuleTint.opacity(0.72),
                Color.ncGlowBlue.opacity(0.55),
                attendanceCapsuleTint.opacity(0.62)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    private var tileBackground: some View {
        ZStack {
            cardShape
                .fill(Color.ncCardSurface)
            cardShape
                .fill(attendanceCapsuleTint.opacity(isSelected ? 0.07 : 0.05))
        }
    }

    private var accentRail: some View {
        Rectangle()
            .fill(
                LinearGradient(
                    colors: [attendanceCapsuleTint, attendanceCapsuleTint.opacity(0.72)],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .frame(width: 5)
    }

    private var statusBadge: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(attendanceCapsuleTint)
                .frame(width: 6, height: 6)
            Text(summary.attendanceBucket.cardTitle)
                .font(.caption2.weight(.bold))
                .lineLimit(1)
        }
        .foregroundStyle(attendanceCapsuleTint)
        .padding(.horizontal, 8)
        .padding(.vertical, 5)
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
        Text(diaryStatusTitle)
            .font(.caption2.weight(.semibold))
            .foregroundStyle(dotColor)
            .padding(.horizontal, 7)
            .padding(.vertical, 3)
            .background(Capsule(style: .continuous).fill(dotColor.opacity(0.14)))
    }

    private var moodHeartRow: some View {
        HStack(spacing: 3) {
            ForEach(1 ... 5, id: \.self) { index in
                Image(systemName: index <= moodStep ? "heart.fill" : "heart")
                    .font(.system(size: 8, weight: .semibold))
                    .foregroundStyle(index <= moodStep ? moodTint : Color.secondary.opacity(0.35))
            }
        }
        .accessibilityHidden(true)
    }

    private var sidebarRowAccessibilityLabel: String {
        var parts = [summary.fullName, summary.attendanceBucket.cardTitle]
        if moodStep > 0 { parts.append("Mood \(moodStep) of 5") }
        if shouldShowDiaryStatusCapsule { parts.append("Diary \(diaryStatusTitle.lowercased())") }
        if shouldShowAllergies { parts.append("Allergy alert") }
        if summary.hasOpenIncident { parts.append("Open incident") }
        return parts.joined(separator: ", ")
    }

    private var photoConsentWarningBanner: some View {
        HStack(spacing: 6) {
            Image(systemName: "camera.fill")
                .font(.caption2.weight(.semibold))
            Text("NO PHOTOGRAPHY")
                .font(.caption2.weight(.heavy))
                .lineLimit(1)
        }
        .foregroundStyle(Color.red.opacity(0.96))
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .frame(maxWidth: .infinity)
        .background(
            Capsule(style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [Color.red.opacity(0.16), Color.red.opacity(0.1)],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
        )
        .overlay(
            Capsule(style: .continuous)
                .stroke(Color.red.opacity(0.4), lineWidth: 1)
        )
    }
}
