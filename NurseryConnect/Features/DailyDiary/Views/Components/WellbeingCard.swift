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
// 120426     Tommy1914   Studio tint card; conditional notes.
// -----------------------------------------------------------------

import Combine
import CoreData
import SwiftUI

/// - Description: Timeline card for wellbeing and mood logging.
struct WellbeingCard: View {
    @ObservedObject var entry: DiaryEntry

    private var tint: Color { AppTheme.diaryColor(for: .wellbeing) }

    var body: some View {
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
                    Image(systemName: "heart.text.square.fill")
                        .font(.body.weight(.semibold))
                        .foregroundStyle(.white)
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text("Wellbeing")
                        .font(.headline)
                    Text((entry.timestamp ?? Date()).formattedTime())
                        .font(.caption.weight(.medium))
                        .foregroundStyle(.secondary)
                }
                Spacer(minLength: 0)
            }
            Text("Mood: \(entry.moodRating)/5")
                .font(.subheadline.weight(.medium))
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
