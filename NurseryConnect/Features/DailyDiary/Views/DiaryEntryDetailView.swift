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
// 120426     Tommy1914   Studio surfaces + atmosphere backdrop (read-only detail polish).
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

    private var syncState: SyncState {
        viewModel.syncState(for: entry)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                Label {
                    Text((entry.timestamp ?? Date()).formattedTime(style: .medium))
                        .font(AppTheme.headlineRounded())
                } icon: {
                    Image(systemName: "clock.fill")
                        .foregroundStyle(
                            LinearGradient(
                                colors: [Color.ncPrimary, Color.cyan.opacity(0.85)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                }
                .padding(16)
                .frame(maxWidth: .infinity, alignment: .leading)
                .ncStudioElevatedSurface(cornerRadius: 16)

                typeSpecific

                VStack(alignment: .leading, spacing: 10) {
                    Label("Sync status", systemImage: "icloud")
                        .font(.subheadline.weight(.semibold))
                    SyncStateBadgeView(state: syncState)
                    if syncState == .failed {
                        Button("Retry sync") {
                            Task { await viewModel.retrySync(for: entry) }
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(Color.ncDanger)
                        if let lastSyncError = entry.lastSyncError, !lastSyncError.isEmpty {
                            Text(lastSyncError)
                                .font(.caption)
                                .foregroundStyle(Color.ncDanger)
                        }
                    }
                }
                .padding(16)
                .frame(maxWidth: .infinity, alignment: .leading)
                .ncStudioElevatedSurface(cornerRadius: 16)

                VStack(alignment: .leading, spacing: 10) {
                    Label("Room leader handover", systemImage: "checkmark.seal.fill")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Color.primary)
                    Toggle("Mark as submitted to room leader", isOn: Binding(
                        get: { entry.isSubmittedToManager },
                        set: { value in
                            Task { await viewModel.updateSubmission(entry, submitted: value) }
                        }
                    ))
                    // EYFS: Submission flag supports audit trails for handovers to room leadership.
                    .tint(Color.ncPrimary)
                }
                .padding(16)
                .frame(maxWidth: .infinity, alignment: .leading)
                .ncStudioElevatedSurface(cornerRadius: 16)
            }
            .padding()
        }
        .scrollIndicators(.hidden)
        .background(Color.ncBackground.ignoresSafeArea())
        .navigationTitle("Diary entry")
        .toolbarBackground(.hidden, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button(role: .destructive) {
                    showDeleteConfirm = true
                } label: {
                    Image(systemName: "trash")
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
