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
// -----------------------------------------------------------------

import CoreData
import SwiftUI

/// - Description: Timeline card for wellbeing and mood logging.
struct WellbeingCard: View {
    @ObservedObject var entry: DiaryEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Image(systemName: "face.smiling")
                    .foregroundStyle(AppTheme.diaryColor(for: .wellbeing))
                Text("Wellbeing")
                    .font(.headline)
                Spacer()
                Text((entry.timestamp ?? Date()).formattedTime())
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Text("Mood: \(entry.moodRating)/5")
                .font(.subheadline)
            Text(entry.notes ?? "")
                .font(.footnote)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppTheme.diaryColor(for: .wellbeing).opacity(0.15))
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
}
