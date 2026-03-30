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
// -----------------------------------------------------------------

import Combine
import CoreData
import SwiftUI

/// - Description: Timeline card for sleep entries including duration and position.
struct SleepLogCard: View {
    @ObservedObject var entry: DiaryEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Image(systemName: "moon.zzz.fill")
                    .foregroundStyle(AppTheme.diaryColor(for: .sleep))
                Text("Sleep")
                    .font(.headline)
                Spacer()
                Text((entry.timestamp ?? Date()).formattedTime())
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Text("Duration: \(entry.duration) minutes")
                .font(.subheadline)
            let positionText = entry.sleepPosition ?? ""
            if !positionText.isEmpty {
                Text("Position: \(positionText)")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
            Text(entry.notes ?? "")
                .font(.footnote)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppTheme.diaryColor(for: .sleep).opacity(0.15))
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
}
