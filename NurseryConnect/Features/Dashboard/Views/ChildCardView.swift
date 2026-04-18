//
//  ChildCardView.swift
//  NurseryConnect
//
//  Feature: Dashboard
//  Role: Keyworker
//  Created: 2 April 2026
//  Description: List row showing a child avatar, name, mood, activity, and diary status capsule.
//
// -----------------------------------------------------------------
// Date       Name        What has done
// -----------------------------------------------------------------
// 020426     Tommy1914   Created the file with avatar, metadata, and status dot.
// 100426     Tommy1914   Let name/age use flexible width so long names wrap cleanly.
// 100426     Tommy1914   Diary status capsule, chevron, gradient card edge (iOS-native patterns).
// 100426     Tommy1914   Denser row height; status on one line to avoid mistaken “bar” when text wraps.
// 100426     Tommy1914   Leading gradient accent for dashboard list styling.
// 140426     Tommy1914   Reverted to single clean row: avatar, text, status, chevron (no banner rail).
// 140426     Tommy1914   Tile shows age only (no gender marker).
// 140426     Tommy1914   Row chrome via `ncCardStyle` (glass plate on iOS 26).
// 140426     Tommy1914   Current activity line, allergies with meal-end alert blink (reduce motion safe).
// -----------------------------------------------------------------

import SwiftUI

/// - Description: One child row inside the keyworker dashboard list.
struct ChildCardView: View {
    let summary: KeyworkerChildSummary
    var currentDate: Date = Date()

    @Environment(\.accessibilityReduceMotion) private var accessibilityReduceMotion

    private var allergiesTrimmed: String {
        summary.allergies.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    /// - Description: Secondary line under the attendance capsule; avoids implying the child is in-session when they are awaiting check-in or absent.
    private var activitySubtitle: String {
        switch summary.attendanceBucket {
        case .absent:
            return "Absent today — not on site"
        case .departed:
            return "Left for the day"
        case .awaiting:
            if summary.usesAttendanceForActivityLine {
                return NurseryDaySchedule.currentActivitySummary(
                    referenceNow: currentDate,
                    day: currentDate,
                    sleepIntervals: summary.sleepIntervals.map { ($0.start, $0.end) },
                    checkInAt: summary.checkInAt,
                    checkOutAt: summary.checkOutAt,
                    usesAttendanceForActivityLine: true
                )
            }
            return "Awaiting check-in"
        case .onSite:
            return NurseryDaySchedule.currentActivitySummary(
                referenceNow: currentDate,
                day: currentDate,
                sleepIntervals: summary.sleepIntervals.map { ($0.start, $0.end) },
                checkInAt: summary.checkInAt,
                checkOutAt: summary.checkOutAt,
                usesAttendanceForActivityLine: summary.usesAttendanceForActivityLine
            )
        }
    }

    private var attendanceCapsuleTint: Color {
        switch summary.attendanceBucket {
        case .onSite: return Color.ncSecondary
        case .awaiting: return Color.ncAccentWarm
        case .absent: return Color.ncDanger
        case .departed: return Color.secondary
        }
    }

    private var shouldFlashAllergies: Bool {
        !allergiesTrimmed.isEmpty && NurseryDaySchedule.isWithinMinutesBeforeAnyMealEnd(reference: currentDate)
    }

    private var shouldShowAllergies: Bool {
        !allergiesTrimmed.isEmpty && NurseryDaySchedule.isWithinMealVisibilityWindow(reference: currentDate, minutesBeforeStart: 5)
    }

    private var dotColor: Color {
        switch summary.dot {
        case .complete: return Color.ncSecondary
        case .partial: return Color.ncAccentWarm
        case .none: return Color.ncDanger
        }
    }

    /// - Description: Short on-card label; full detail is in `diaryDotAccessibilityLabel`.
    private var diaryStatusTitle: String {
        switch summary.dot {
        case .complete: return "Complete"
        case .partial: return "Partial"
        case .none: return "No logs"
        }
    }

    private var moodTint: Color { AppTheme.diaryColor(for: .wellbeing) }

    private var moodStep: Int {
        guard let r = summary.latestMoodRating else { return 0 }
        return min(5, max(0, Int(r)))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .center, spacing: 12) {
                ChildAvatarView(
                    firstName: summary.firstName,
                    lastName: summary.lastName,
                    childId: summary.id,
                    showsAccentRing: true,
                    dimension: 44
                )

                VStack(alignment: .leading, spacing: 5) {
                    HStack(alignment: .firstTextBaseline, spacing: 8) {
                        Text("\(summary.firstName) \(summary.lastName)")
                            .font(.headline)
                            .foregroundStyle(.primary)
                            .lineLimit(1)
                            .truncationMode(.tail)
                        if summary.hasOpenIncident {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(Color.ncDanger)
                                .accessibilityLabel("Open incident")
                        }
                    }

                    if moodStep > 0 {
                        HStack(spacing: 6) {
                            Text("Mood")
                                .font(.caption2.weight(.semibold))
                                .foregroundStyle(.secondary)
                            HStack(spacing: 3) {
                                ForEach(1 ... 5, id: \.self) { i in
                                    Image(systemName: i <= moodStep ? "heart.fill" : "heart")
                                        .font(.caption2.weight(.semibold))
                                        .foregroundStyle(i <= moodStep ? moodTint : Color.secondary.opacity(0.4))
                                }
                            }
                            Text("\(moodStep)/5")
                                .font(.caption2.weight(.semibold))
                                .foregroundStyle(.secondary)
                                .monospacedDigit()
                        }
                        .accessibilityElement(children: .combine)
                        .accessibilityLabel("Mood \(moodStep) of 5, higher is better wellbeing")
                    }

                    HStack(spacing: 8) {
                        Text(summary.attendanceBucket.cardTitle)
                            .font(.caption2.weight(.bold))
                            .lineLimit(1)
                            .minimumScaleFactor(0.85)
                            .foregroundStyle(attendanceCapsuleTint)
                            .padding(.horizontal, 9)
                            .padding(.vertical, 4)
                            .background(Capsule(style: .continuous).fill(attendanceCapsuleTint.opacity(0.14)))
                            .accessibilityLabel("Attendance: \(summary.attendanceBucket.sectionTitle)")

                        Text(activitySubtitle)
                            .font(.caption2.weight(.medium))
                            .foregroundStyle(.secondary)
                            .lineLimit(2)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .accessibilityElement(children: .combine)
                    .accessibilityIdentifier(AppConstants.AccessibilityID.childCardCurrentActivity)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                VStack(alignment: .trailing, spacing: 6) {
                    if shouldShowAllergies {
                        allergyIndicator
                    }

                    HStack(spacing: 4) {
                        if summary.dot == .partial {
                            Image(systemName: "list.clipboard.fill")
                                .font(.caption2.weight(.semibold))
                                .accessibilityHidden(true)
                        }
                        Text(diaryStatusTitle)
                            .font(.caption.weight(.semibold))
                            .lineLimit(1)
                            .minimumScaleFactor(0.85)
                    }
                    .foregroundStyle(dotColor)
                    .padding(.horizontal, summary.dot == .partial ? 8 : 9)
                    .padding(.vertical, 5)
                    .background(Capsule(style: .continuous).fill(dotColor.opacity(0.14)))
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel(diaryDotAccessibilityLabel)

                    Image(systemName: "chevron.right")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.tertiary)
                }
            }

            if !summary.photoConsent {
                photoConsentWarningBanner
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .ncCardStyle(radius: AppConstants.cardCornerRadius)
        .accessibilityElement(children: .combine)
        .accessibilityHint(
            {
                switch summary.attendanceBucket {
                case .awaiting:
                    return "Opens check-in. Enter who dropped the child off; arrival time is recorded automatically."
                case .absent, .onSite, .departed:
                    return "Opens today’s diary for this child."
                }
            }()
        )
    }

    private var allergyIndicator: some View {
        let urgent = shouldFlashAllergies
        let animating = urgent && !accessibilityReduceMotion
        return TimelineView(.animation(minimumInterval: animating ? 0.05 : 60, paused: !animating)) { context in
            let pulse: Double = {
                if !animating { return 1 }
                let t = context.date.timeIntervalSince1970
                return 0.5 + 0.5 * (0.5 + 0.5 * sin(t * 5))
            }()
            Text("⚠️ Allergy")
                .font(.caption2.weight(.bold))
                .foregroundStyle(Color.red.opacity(urgent ? (animating ? 0.7 + 0.3 * pulse : 1) : 1))
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(
                    Capsule(style: .continuous)
                        .fill(Color.red.opacity(urgent ? 0.16 : 0.10))
                )
                .overlay(
                    Capsule(style: .continuous)
                        .stroke(Color.red.opacity(urgent ? 0.45 : 0.3), lineWidth: 1)
                )
                .accessibilityIdentifier(AppConstants.AccessibilityID.childCardAllergies)
        }
    }

    private var diaryDotAccessibilityLabel: String {
        switch summary.dot {
        case .complete: return "Diary completeness: every planned session has a log today"
        case .partial: return "Diary completeness: some planned sessions still need a log"
        case .none: return "Diary completeness: no observations logged yet today"
        }
    }

    private var photoConsentWarningBanner: some View {
        HStack(alignment: .center, spacing: 6) {
            Image(systemName: "camera.fill")
                .font(.caption.weight(.semibold))
                .foregroundStyle(Color.red)
            Text("NO PHOTOGRAPHY CONSENT")
                .font(.caption2.weight(.black))
                .foregroundStyle(Color.red)
                .lineLimit(nil)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 5)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(Color.red.opacity(0.12))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(Color.red.opacity(0.45), lineWidth: 1.2)
        )
    }
}

#Preview {
    ChildCardView(
        summary: KeyworkerChildSummary(
            id: UUID(),
            firstName: "Emma",
            lastName: "Wilson",
            roomName: "Sunshine Room",
            keyworkerName: "Alex Keyworker",
            allergies: "Peanuts",
            photoConsent: false,
            dateOfBirth: Date(),
            dot: .partial,
            sleepIntervals: [],
            checkInAt: nil,
            checkOutAt: nil,
            usesAttendanceForActivityLine: false,
            attendanceBucket: .awaiting,
            latestMoodRating: 4,
            hasOpenIncident: true
        )
    )
    .padding()
    .background(Color.ncBackground)
}
