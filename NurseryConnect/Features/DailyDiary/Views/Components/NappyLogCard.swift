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
// -----------------------------------------------------------------

import Combine
import CoreData
import SwiftUI

/// - Description: Timeline card for nappy observations.
struct NappyLogCard: View {
    @ObservedObject var entry: DiaryEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Image(systemName: "drop.fill")
                    .foregroundStyle(AppTheme.diaryColor(for: .nappy))
                Text("Nappy")
                    .font(.headline)
                Spacer()
                Text((entry.timestamp ?? Date()).formattedTime())
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Text("Type: \(entry.nappyType ?? "")")
                .font(.subheadline)
            Text(entry.notes ?? "")
                .font(.footnote)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppTheme.diaryColor(for: .nappy).opacity(0.15))
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
}
