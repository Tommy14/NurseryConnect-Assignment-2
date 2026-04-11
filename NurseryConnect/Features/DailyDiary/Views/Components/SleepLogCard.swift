//
//  SleepLogCard.swift
//  NurseryConnect
//
//  Feature: Daily Diary
//  Role: Keyworker
//  Created: 4 April 2026
//  Description: Summary card for sleep and rest observations.
//
// -----------------------------------------------------------------
// Date       Name        What has done
// -----------------------------------------------------------------
// 040426     Tommy1914   Created the file with duration and position summary.
// 100426     Tommy1914   Studio tint card; conditional notes.
// 180426     Tommy1914   Simpler layout; no inset panels.
// 180426     Tommy1914   Labels for duration and notes.
// -----------------------------------------------------------------

import Combine
import CoreData
import SwiftUI

/// - Description: Timeline card for sleep entries including duration and position.
struct SleepLogCard: View {
    @ObservedObject var entry: DiaryEntry

    private var tint: Color { AppTheme.diaryColor(for: .sleep) }

    var body: some View {
        let positionText = (entry.sleepPosition ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        let noteText = (entry.notes ?? "").trimmingCharacters(in: .whitespacesAndNewlines)

        VStack(alignment: .leading, spacing: 10) {
            DiaryEntryCardHeader(
                title: "Sleep",
                systemImage: "moon.zzz.fill",
                timestamp: entry.timestamp ?? Date(),
                tint: tint
            )
            VStack(alignment: .leading, spacing: 3) {
                Text("Duration")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                Text("\(entry.duration) minutes")
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(.primary)
            }
            if !positionText.isEmpty {
                VStack(alignment: .leading, spacing: 3) {
                    Text("Position")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                    Text(positionText)
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
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .ncDiaryTimelineCard(tint: tint, cornerRadius: 14)
    }
}
