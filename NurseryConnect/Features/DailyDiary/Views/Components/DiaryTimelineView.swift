//
//  DiaryTimelineView.swift
//  NurseryConnect
//
//  Feature: Daily Diary
//  Role: Keyworker
//  Created: 4 April 2026
//  Description: Vertical timeline of today’s diary entries with type-coloured nodes.
//
// -----------------------------------------------------------------
// Date       Name        What has done
// -----------------------------------------------------------------
// 040426     Tommy1914   Created the file with grouped sections and connector line.
// 130426     Tommy1914   Time-band headers with index accent for dossier-style timeline.
// -----------------------------------------------------------------

import Combine
import CoreData
import SwiftUI

/// - Description: Renders a chronological timeline for the supplied diary rows.
struct DiaryTimelineView: View {
    let entries: [DiaryEntry]
    @ObservedObject var viewModel: DailyDiaryViewModel

    private var grouped: [(key: String, value: [DiaryEntry])] {
        let formatter = DateFormatter()
        formatter.dateStyle = .none
        formatter.timeStyle = .short
        let dict = Dictionary(grouping: entries) { entry in
            let hour = Calendar.current.component(.hour, from: entry.timestamp ?? Date())
            return String(format: "%02d:00", hour)
        }
        return dict.keys.sorted().map { key in
            (key, dict[key] ?? [])
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ForEach(grouped, id: \.key) { group in
                HStack(spacing: 10) {
                    RoundedRectangle(cornerRadius: 2, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [Color.ncPrimary.opacity(0.85), Color.cyan.opacity(0.45)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .frame(width: 3, height: 14)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Time segment")
                            .font(.caption2.weight(.bold))
                            .tracking(0.4)
                            .foregroundStyle(.tertiary)
                        Text("Around \(group.key)")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.secondary)
                    }
                    Spacer(minLength: 0)
                }
                .padding(.bottom, 8)
                ForEach(Array(group.value.enumerated()), id: \.element.objectID) { index, entry in
                    let type = DiaryEntryType.fromPersistence(entry.entryType ?? "")
                    HStack(alignment: .top, spacing: 12) {
                        VStack {
                            Circle()
                                .fill(AppTheme.diaryColor(for: type))
                                .frame(width: 14, height: 14)
                                .overlay(
                                    Circle()
                                        .stroke(Color.ncCardSurface, lineWidth: 2)
                                )
                            if index < group.value.count - 1 {
                                Rectangle()
                                    .fill(Color.secondary.opacity(0.25))
                                    .frame(width: 2)
                                    .frame(maxHeight: .infinity)
                            } else {
                                Spacer(minLength: 0)
                            }
                        }
                        .frame(width: 18)

                        NavigationLink {
                            DiaryEntryDetailView(entry: entry, viewModel: viewModel)
                        } label: {
                            VStack(alignment: .leading, spacing: 8) {
                                SyncStateBadgeView(state: viewModel.syncState(for: entry))
                                diaryCard(for: entry, type: type)
                            }
                        }
                        .buttonStyle(.plain)
                        .transition(.move(edge: .trailing).combined(with: .opacity))
                    }
                    .padding(.bottom, 12)
                }
            }
        }
    }

    @ViewBuilder
    private func diaryCard(for entry: DiaryEntry, type: DiaryEntryType) -> some View {
        switch type {
        case .activity:
            ActivityLogCard(entry: entry)
        case .sleep:
            SleepLogCard(entry: entry)
        case .meal:
            MealLogCard(entry: entry)
        case .nappy:
            NappyLogCard(entry: entry)
        case .wellbeing:
            WellbeingCard(entry: entry)
        case .milestone:
            ActivityLogCard(entry: entry)
        }
    }
}
