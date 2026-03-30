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

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Image(systemName: "figure.play")
                    .foregroundStyle(AppTheme.diaryColor(for: type))
                Text(type == .milestone ? "Milestone" : "Activity")
                    .font(.headline)
                Spacer()
                Text((entry.timestamp ?? Date()).formattedTime())
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            let activityText = entry.activityType ?? ""
            if !activityText.isEmpty {
                Text(activityText)
                    .font(.subheadline.weight(.semibold))
            }
            let eyfsText = entry.eyfsArea ?? ""
            if !eyfsText.isEmpty {
                Text(eyfsText)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
            Text(entry.notes ?? "")
                .font(.footnote)
                .foregroundStyle(.primary)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppTheme.diaryColor(for: type).opacity(0.15))
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
}
