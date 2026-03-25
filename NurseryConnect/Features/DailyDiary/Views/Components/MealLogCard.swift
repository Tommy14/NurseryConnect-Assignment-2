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
// -----------------------------------------------------------------

import CoreData
import SwiftUI

/// - Description: Timeline card for meal entries with consumption and fluids.
struct MealLogCard: View {
    @ObservedObject var entry: DiaryEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Image(systemName: "fork.knife")
                    .foregroundStyle(AppTheme.diaryColor(for: .meal))
                Text("Meal")
                    .font(.headline)
                Spacer()
                Text((entry.timestamp ?? Date()).formattedTime())
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Text(entry.mealDescription ?? "")
                .font(.subheadline.weight(.semibold))
            Text("Consumed: \(entry.mealConsumed)")
                .font(.footnote)
            Text("Fluids: \(entry.fluidIntake) ml (\(entry.fluidType))")
                .font(.footnote)
                .foregroundStyle(.secondary)
            Text(entry.notes ?? "")
                .font(.footnote)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppTheme.diaryColor(for: .meal).opacity(0.15))
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
}
