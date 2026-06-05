//
//  ActivityLogCard.swift
//  NurseryConnect
//
//  Feature: Daily Diary
//  Role: Keyworker
//  Created: 4 April 2026
//  Description: Summary card for activity and milestone-style diary rows.
//
// -----------------------------------------------------------------
// Date       Name        What has done
// -----------------------------------------------------------------
// 040426     Tommy1914   Created the file with activity metadata and timestamp.
// 100426     Tommy1914   Studio tint card; conditional notes.
// 140426     Tommy1914   Simpler timeline tile (less chrome).
// 140426     Tommy1914   Field labels for activity, EYFS, notes.
// -----------------------------------------------------------------

import Combine
import CoreData
import SwiftUI

/// - Description: Compact card for activity or milestone entries on the timeline.
struct ActivityLogCard: View {
    @ObservedObject var entry: DiaryEntry

    private var type: DiaryEntryType {
        DiaryEntryType.fromPersistence(entry.entryType ?? "")
    }

    private var tint: Color { AppTheme.diaryColor(for: type) }

    var body: some View {
        let activityText = (entry.activityType ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        let eyfsText = (entry.eyfsArea ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        let noteText = (entry.notes ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        let milestoneImage = entry.milestonePhotoData.flatMap { UIImage(data: $0) }
        let hasMilestonePhoto = milestoneImage != nil
        let isSubmitted = entry.submittedAt != nil

        VStack(alignment: .leading, spacing: 10) {
            DiaryEntryCardHeader(
                title: type == .milestone ? "Milestone" : "Activity",
                systemImage: type == .milestone ? "star.fill" : "figure.play",
                timestamp: entry.timestamp ?? Date(),
                tint: tint
            )
            if !activityText.isEmpty {
                VStack(alignment: .leading, spacing: 3) {
                    Text(type == .milestone ? "Milestone" : "What we did")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                    Text(activityText)
                        .font(.headline.weight(.semibold))
                        .foregroundStyle(.primary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            if !eyfsText.isEmpty {
                VStack(alignment: .leading, spacing: 3) {
                    Text("EYFS area")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                    Text(eyfsText)
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(.primary)
                }
            }
            if !noteText.isEmpty {
                VStack(alignment: .leading, spacing: 3) {
                    Text("Notes")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                    Text(noteText)
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(.primary.opacity(0.92))
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            if type == .milestone, hasMilestonePhoto {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Photo evidence")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                    if isSubmitted {
                        Label("Photo evidence recorded", systemImage: "checkmark.seal.fill")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.primary)
                    } else if let milestoneImage {
                        Image(uiImage: milestoneImage)
                            .resizable()
                            .scaledToFill()
                            .frame(height: 132)
                            .frame(maxWidth: .infinity)
                            .clipped()
                            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    }
                    Text("Blurred faces: \(entry.milestonePhotoBlurredFaceCount)")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .ncDiaryTimelineCard(tint: tint, cornerRadius: 14)
    }
}
