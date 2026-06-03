//
//  SpatialSelectedChildPanel.swift
//  NurseryConnect Spatial
//
//  Feature: Spatial
//  Role: Keyworker
//  Created: 2 June 2026
//  Description: Selected-child summary with attendance, diary, mood, and safeguarding flags.
//

import SwiftUI

/// - Description: Detail card for the child currently selected on the spatial dashboard.
struct SpatialSelectedChildPanel: View {
    let summary: SpatialChildSummary

    private var attendanceTint: Color {
        switch summary.attendanceBucket {
        case .onSite: return Color.ncSecondary
        case .awaiting: return Color.ncAccentWarm
        case .absent: return Color.ncDanger
        case .departed: return Color.secondary
        }
    }

    private var diaryTint: Color {
        switch summary.dot {
        case .complete: return Color.ncSecondary
        case .partial: return Color.ncAccentWarm
        case .none: return Color.ncDanger
        }
    }

    private var diaryTitle: String {
        switch summary.dot {
        case .complete: return "Diary complete"
        case .partial: return "Diary partial"
        case .none: return "No logs today"
        }
    }

    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            ChildAvatarView(
                firstName: summary.firstName,
                lastName: summary.lastName,
                childId: summary.id,
                showsAccentRing: false,
                dimension: 52
            )

            VStack(alignment: .leading, spacing: 8) {
                Text(summary.preferredName.isEmpty ? summary.firstName : summary.preferredName)
                    .font(.title3.weight(.semibold))
                if !summary.roomName.isEmpty {
                    Text(summary.roomName)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                HStack(spacing: 8) {
                    statusPill(summary.attendanceBucket.cardTitle, tint: attendanceTint)
                    if summary.attendanceBucket != .absent {
                        statusPill(diaryTitle, tint: diaryTint)
                    }
                    if let mood = summary.latestMoodRating, mood > 0 {
                        statusPill("Mood \(mood)/5", tint: Color.ncPrimary)
                    }
                }

                if summary.hasOpenIncident {
                    Label("Open incident needs follow-up", systemImage: "exclamationmark.shield.fill")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(Color.ncDanger)
                }

                if summary.attendanceBucket == .onSite, !summary.photoConsent {
                    Label("No photography consent", systemImage: "camera.fill")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(Color.ncDanger)
                }

                let allergy = summary.allergies.trimmingCharacters(in: .whitespacesAndNewlines)
                if !allergy.isEmpty {
                    Label(allergy, systemImage: "allergens")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(16)
        .glassBackgroundEffect(in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private func statusPill(_ title: String, tint: Color) -> some View {
        Text(title)
            .font(.caption.weight(.semibold))
            .foregroundStyle(tint)
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(tint.opacity(0.14), in: Capsule())
    }
}
