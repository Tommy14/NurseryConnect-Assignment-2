//
//  DiaryEntryDetailView.swift
//  NurseryConnect
//
//  Feature: Daily Diary
//  Role: Keyworker
//  Created: 5 April 2026
//  Description: Diary detail with room-leader handover confirmation and conditional delete.
//
// -----------------------------------------------------------------
// Date       Name        What has done
// -----------------------------------------------------------------
// 050426     Tommy1914   Created the file with manager toggle, delete alert, and layout.
// 100426     Tommy1914   Studio surfaces + atmosphere backdrop (read-only detail polish).
// 140426     Tommy1914   Submit via button + confirm alert; hide delete after handover submitted.
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
    @State private var showSubmitConfirm = false

    private var type: DiaryEntryType {
        DiaryEntryType.fromPersistence(entry.entryType ?? "")
    }

    private var syncState: SyncState {
        viewModel.syncState(for: entry)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                HStack(alignment: .center, spacing: 10) {
                    Label {
                        VStack(alignment: .leading, spacing: 4) {
                            Text((entry.timestamp ?? Date()).formattedTime(style: .medium))
                                .font(AppTheme.headlineRounded())
                            if let submittedAt = entry.submittedAt {
                                Text("Recorded at \(submittedAt.formatted(date: .abbreviated, time: .shortened))")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
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
                    Spacer(minLength: 0)
                    SyncStateBadgeView(state: syncState)
                    if syncState == .failed {
                        Button("Retry") {
                            Task { await viewModel.retrySync(for: entry) }
                        }
                        .font(.caption.weight(.semibold))
                        .buttonStyle(.borderedProminent)
                        .tint(Color.ncDanger)
                    }
                }
                .padding(16)
                .frame(maxWidth: .infinity, alignment: .leading)
                .ncStudioElevatedSurface(cornerRadius: 16)

                if entry.needsLateLogManagerReview {
                    HStack(alignment: .top, spacing: 10) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundStyle(Color.ncDanger)
                            .accessibilityHidden(true)
                        Text("Large gap between event time and save time. This entry is flagged for manager review.")
                            .font(.subheadline)
                            .foregroundStyle(.primary)
                    }
                    .padding(12)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background {
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(Color.ncDanger.opacity(0.12))
                    }
                    .overlay {
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .stroke(Color.ncDanger.opacity(0.25), lineWidth: 1)
                    }
                }

                typeSpecific

                VStack(alignment: .leading, spacing: 12) {
                    Label("Room leader handover", systemImage: "checkmark.seal.fill")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Color.primary)
                    if entry.isSubmittedToManager {
                        HStack(spacing: 10) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.title3)
                                .foregroundStyle(Color.green)
                                .accessibilityHidden(true)
                            Text("Submitted to room leader")
                                .font(.body.weight(.semibold))
                                .foregroundStyle(.primary)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .accessibilityElement(children: .combine)
                    } else {
                        PrimaryButton(title: "Mark as submitted to room leader") {
                            showSubmitConfirm = true
                        }
                    }
                    // EYFS: Submission flag supports audit trails for handovers to room leadership.
                }
                .padding(16)
                .frame(maxWidth: .infinity, alignment: .leading)
                .ncStudioElevatedSurface(cornerRadius: 16)

                if syncState == .failed, let lastSyncError = entry.lastSyncError, !lastSyncError.isEmpty {
                    Text(lastSyncError)
                        .font(.caption)
                        .foregroundStyle(Color.ncDanger)
                        .padding(.horizontal, 2)
                }
            }
            .padding()
        }
        .scrollIndicators(.hidden)
        .background(Color.ncBackground.ignoresSafeArea())
        .navigationTitle("Diary entry")
        .toolbarBackground(Color.ncBackground, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbar {
            if !entry.isSubmittedToManager {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(role: .destructive) {
                        showDeleteConfirm = true
                    } label: {
                        Image(systemName: "trash")
                    }
                    .accessibilityLabel("Delete diary entry")
                }
            }
        }
        .alert("Submit to room leader?", isPresented: $showSubmitConfirm) {
            Button("Submit") {
                Task { await viewModel.updateSubmission(entry, submitted: true) }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("After confirming, this entry is locked and can no longer be deleted.")
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
