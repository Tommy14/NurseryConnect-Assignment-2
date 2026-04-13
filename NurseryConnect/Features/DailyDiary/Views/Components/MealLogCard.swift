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
// 120426     Tommy1914   Studio tint card; hide empty lines.
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
                    Image(systemName: "fork.knife")
                        .font(.body.weight(.semibold))
                        .foregroundStyle(.white)
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text("Meal")
                        .font(.headline)
                    Text((entry.timestamp ?? Date()).formattedTime())
                        .font(.caption.weight(.medium))
                        .foregroundStyle(.secondary)
                }
                Spacer(minLength: 0)
            }
            if !desc.isEmpty {
                Text(desc)
                    .font(.subheadline.weight(.semibold))
            }
            Text("Consumed: \(entry.mealConsumed ?? "—")")
                .font(.footnote.weight(.medium))
            Text("Fluids: \(entry.fluidIntake) ml (\(entry.fluidType ?? "—"))")
                .font(.footnote)
                .foregroundStyle(.secondary)
            if !noteText.isEmpty {
                Text(noteText)
                    .font(.footnote)
                    .foregroundStyle(.primary)
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .ncStudioTintedCard(tint: tint, cornerRadius: 16)
    }
}
