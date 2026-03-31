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
// 120426     Tommy1914   Studio tint card; conditional notes.
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

        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [tint.opacity(0.5), tint.opacity(0.2)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 40, height: 40)
                    Image(systemName: type == .milestone ? "star.fill" : "figure.play")
                        .font(.body.weight(.semibold))
                        .foregroundStyle(.white)
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text(type == .milestone ? "Milestone" : "Activity")
                        .font(.headline)
                    Text((entry.timestamp ?? Date()).formattedTime())
                        .font(.caption.weight(.medium))
                        .foregroundStyle(.secondary)
                }
                Spacer(minLength: 0)
            }
            if !activityText.isEmpty {
                Text(activityText)
                    .font(.subheadline.weight(.semibold))
            }
            if !eyfsText.isEmpty {
                Text(eyfsText)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
            if !noteText.isEmpty {
                Text(noteText)
                    .font(.footnote)
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .ncStudioTintedCard(tint: tint, cornerRadius: 16)
    }
}
