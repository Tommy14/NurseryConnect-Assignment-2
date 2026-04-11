//
//  MealLogCard.swift
//  NurseryConnect
//
//  Feature: Daily Diary
//  Role: Keyworker
//  Created: 4 April 2026
//  Description: Summary card for meals and snacks including fluid intake.
//
// -----------------------------------------------------------------
// Date       Name        What has done
// -----------------------------------------------------------------
// 040426     Tommy1914   Created the file with consumption and fluid summary.
// 100426     Tommy1914   Studio tint card; hide empty lines.
// 180426     Tommy1914   Flat meta lines; explicit labels (Food, Amount eaten, Fluids, Notes; Time in header).
// -----------------------------------------------------------------

import Combine
import CoreData
import SwiftUI

/// - Description: Timeline card for meal entries with consumption and fluids.
struct MealLogCard: View {
    @ObservedObject var entry: DiaryEntry

    private var tint: Color { AppTheme.diaryColor(for: .meal) }

    var body: some View {
        let desc = (entry.mealDescription ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        let noteText = (entry.notes ?? "").trimmingCharacters(in: .whitespacesAndNewlines)

        VStack(alignment: .leading, spacing: 10) {
            DiaryEntryCardHeader(
                title: "Meal",
                systemImage: "fork.knife",
                timestamp: entry.timestamp ?? Date(),
                tint: tint
            )
            if !desc.isEmpty {
                VStack(alignment: .leading, spacing: 3) {
                    Text("Food")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                    Text(desc)
                        .font(.headline.weight(.semibold))
                        .foregroundStyle(.primary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            VStack(alignment: .leading, spacing: 3) {
                Text("Amount eaten")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                Text(entry.mealConsumed ?? "—")
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.primary)
            }
            VStack(alignment: .leading, spacing: 3) {
                Text("Fluids")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                Text("\(entry.fluidIntake) ml (\(entry.fluidType ?? "—"))")
                    .font(.subheadline.weight(.medium))
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
