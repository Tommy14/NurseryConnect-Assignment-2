//
//  WellbeingCard.swift
//  NurseryConnect
//
//  Feature: Daily Diary
//  Role: Keyworker
//  Created: 4 April 2026
//  Description: Summary card for wellbeing observations and mood ratings.
//
// -----------------------------------------------------------------
// Date       Name        What has done
// -----------------------------------------------------------------
// 040426     Tommy1914   Created the file with mood and narrative notes.
// 100426     Tommy1914   Studio tint card; conditional notes.
// 140426     Tommy1914   Inline mood hearts; no extra panels.
// 140426     Tommy1914   Notes label when present.
// -----------------------------------------------------------------

import Combine
import CoreData
import SwiftUI

/// - Description: Timeline card for wellbeing and mood logging.
struct WellbeingCard: View {
    @ObservedObject var entry: DiaryEntry

    private var tint: Color { AppTheme.diaryColor(for: .wellbeing) }

    private var moodStep: Int {
        min(5, max(0, Int(entry.moodRating)))
    }

    var body: some View {
        let noteText = (entry.notes ?? "").trimmingCharacters(in: .whitespacesAndNewlines)

        VStack(alignment: .leading, spacing: 10) {
            DiaryEntryCardHeader(
                title: "Wellbeing",
                systemImage: "heart.text.square.fill",
                timestamp: entry.timestamp ?? Date(),
                tint: tint
            )
            HStack(spacing: 8) {
                Text("Mood")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                HStack(spacing: 4) {
                    ForEach(1 ... 5, id: \.self) { i in
                        Image(systemName: i <= moodStep ? "heart.fill" : "heart")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(i <= moodStep ? tint : Color.secondary.opacity(0.4))
                    }
                }
                Spacer(minLength: 0)
                Text("\(entry.moodRating)/5")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.primary)
                    .monospacedDigit()
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
