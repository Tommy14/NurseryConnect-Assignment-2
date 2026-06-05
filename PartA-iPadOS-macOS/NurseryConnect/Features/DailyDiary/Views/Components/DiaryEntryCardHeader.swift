//
//  DiaryEntryCardHeader.swift
//  NurseryConnect
//
//  Feature: Daily Diary
//  Role: Keyworker
//  Created: 16 April 2026
//  Description: Shared header row for timeline diary tiles (icon, title, time).
//

import SwiftUI

/// - Description: Type-coloured header used on diary timeline cards.
struct DiaryEntryCardHeader: View {
    let title: String
    let systemImage: String
    let timestamp: Date
    let tint: Color

    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            ZStack {
                Circle()
                    .fill(tint.opacity(0.2))
                    .frame(width: 40, height: 40)
                Image(systemName: systemImage)
                    .font(.body.weight(.semibold))
                    .foregroundStyle(tint)
            }
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(.primary)
                HStack(spacing: 6) {
                    Text("Time")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                    Text(timestamp.formattedTime())
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.primary)
                        .monospacedDigit()
                }
            }
            Spacer(minLength: 0)
        }
        .accessibilityElement(children: .combine)
    }
}
