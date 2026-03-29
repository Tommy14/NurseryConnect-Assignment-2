//
//  DiaryEntryDetailView.swift
//  NurseryConnect
//
//  Feature: Daily Diary
//  Role: Keyworker
//  Created: 5 April 2026
//  Description: Read-only diary detail with submission toggle and destructive delete.
//
// -----------------------------------------------------------------
// Date       Name        What has done
// -----------------------------------------------------------------
// 050426     Tommy1914   Created the file with manager toggle, delete alert, and layout.
// -----------------------------------------------------------------

import Combine
import CoreData
import SwiftUI

/// - Description: Full-screen detail for a persisted `DiaryEntry`.
struct DiaryEntryDetailView: View {
    @ObservedObject var entry: DiaryEntry
    @ObservedObject var viewModel: DailyDiaryViewModel

    @Environment(\.dismiss) private var dismiss
    @State private var showDeleteConfirm = false

    private var type: DiaryEntryType {
        DiaryEntryType.fromPersistence(entry.entryType ?? "")
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text((entry.timestamp ?? Date()).formattedTime(style: .medium))
                    .font(AppTheme.greetingRounded())
                typeSpecific
                Toggle("Mark as submitted to room leader", isOn: Binding(
                    get: { entry.isSubmittedToManager },
                    set: { value in
                        Task { await viewModel.updateSubmission(entry, submitted: value) }
                    }
                ))
                // EYFS: Submission flag supports audit trails for handovers to room leadership.
                .tint(Color.ncPrimary)
            }
            .padding()
        }
        .background(Color.ncBackground.ignoresSafeArea())
        .navigationTitle("Diary entry")
        .toolbar {
            ToolbarItem(placement: .bottomBar) {
                Button(role: .destructive) {
                    showDeleteConfirm = true
                } label: {
                    Label("Delete entry", systemImage: "trash")
                }
            }
        }
        .alert("Delete this diary entry?", isPresented: $showDeleteConfirm) {
            Button("Delete", role: .destructive) {
                Task {
                    await viewModel.delete(entry: entry)
                    dismiss()
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This cannot be undone.")
        }
    }

    @ViewBuilder
    private var typeSpecific: some View {
        switch type {
        case .activity, .milestone:
            ActivityLogCard(entry: entry)
        case .sleep:
            SleepLogCard(entry: entry)
        case .meal:
            MealLogCard(entry: entry)
        case .nappy:
            NappyLogCard(entry: entry)
        case .wellbeing:
            WellbeingCard(entry: entry)
        }
    }
}
