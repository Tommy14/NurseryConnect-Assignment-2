//
//  NappyLogCard.swift
//  NurseryConnect
//
//  Feature: Daily Diary
//  Role: Keyworker
//  Created: 4 April 2026
//  Description: Summary card for nappy changes and hygiene notes.
//
// -----------------------------------------------------------------
// Date       Name        What has done
// -----------------------------------------------------------------
// 040426     Tommy1914   Created the file with type and notes summary.
// 100426     Tommy1914   Studio tint card; conditional notes.
// 180426     Tommy1914   Simpler headline + notes.
// 180426     Tommy1914   Labels for type and notes.
// -----------------------------------------------------------------

import Combine
import CoreData
import SwiftUI

/// - Description: Timeline card for nappy observations.
struct NappyLogCard: View {
    @ObservedObject var entry: DiaryEntry

    private var tint: Color { AppTheme.diaryColor(for: .nappy) }

    var body: some View {
        let noteText = (entry.notes ?? "").trimmingCharacters(in: .whitespacesAndNewlines)

        VStack(alignment: .leading, spacing: 10) {
            DiaryEntryCardHeader(
                title: "Nappy",
                systemImage: "drop.fill",
                timestamp: entry.timestamp ?? Date(),
                tint: tint
            )
            VStack(alignment: .leading, spacing: 3) {
                Text("Type")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                Text(entry.nappyType ?? "—")
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(.primary)
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
