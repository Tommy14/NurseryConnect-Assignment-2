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
// 120426     Tommy1914   Studio tint card; conditional notes.
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
                    Image(systemName: "moon.zzz.fill")
                        .font(.body.weight(.semibold))
                        .foregroundStyle(.white)
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text("Sleep")
                        .font(.headline)
                    Text((entry.timestamp ?? Date()).formattedTime())
                        .font(.caption.weight(.medium))
                        .foregroundStyle(.secondary)
                }
                Spacer(minLength: 0)
            }
            Text("Duration: \(entry.duration) minutes")
                .font(.subheadline.weight(.medium))
            if !positionText.isEmpty {
                Text("Position: \(positionText)")
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
