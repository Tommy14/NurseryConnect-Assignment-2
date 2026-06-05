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

    @State private var showSubmitConfirm = false
    @State private var showCorrectionSheet = false

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

                if entry.hasCorrections {
                    correctionSummaryCard
                    originalSnapshotCard
                    correctionHistoryCard
                }

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
            .padding(.bottom, 96)
        }
        .blur(radius: showCorrectionSheet ? 7 : 0)
        .animation(.easeInOut(duration: 0.2), value: showCorrectionSheet)
        .scrollIndicators(.hidden)
        .background(Color.ncBackground.ignoresSafeArea())
        .navigationTitle("Diary entry")
        .toolbarBackground(Color.ncBackground, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Correct log") {
                    showCorrectionSheet = true
                }
                .font(.subheadline.weight(.semibold))
            }
        }
        .alert("Submit to room leader?", isPresented: $showSubmitConfirm) {
            Button("Submit") {
                Task { await viewModel.updateSubmission(entry, submitted: true) }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("After confirming, this entry is locked for handover but corrections remain available with an audit reason.")
        }
        .sheet(isPresented: $showCorrectionSheet) {
            AddDiaryEntryView(
                childID: entry.child?.id ?? UUID(),
                viewModel: viewModel,
                childAllergies: entry.child?.allergies ?? "",
                childPhotoConsent: entry.child?.photoConsent ?? false,
                mode: .correction(existingEntry: entry)
            )
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

    private var correctionSummaryCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("Corrected log", systemImage: "checkmark.seal.fill")
                .font(.subheadline.weight(.semibold))
            Text("Timeline shows this corrected version.")
                .font(.footnote)
                .foregroundStyle(.secondary)
            if let lastCorrectedAt = entry.lastCorrectedAt {
                Text("Last corrected at \(lastCorrectedAt.formatted(date: .abbreviated, time: .shortened))")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .ncStudioElevatedSurface(cornerRadius: 16)
    }

    private var originalSnapshotCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("Original log", systemImage: "doc.text.magnifyingglass")
                .font(.subheadline.weight(.semibold))
            if let snapshot = entry.decodedOriginalSnapshot {
                keyValue("Type", DiaryEntryType.fromPersistence(snapshot.entryType).title)
                keyValue("Time", (snapshot.timestamp ?? Date()).formattedTime(style: .medium))
                keyValue("Notes", snapshot.notes)
                if !snapshot.activityType.isEmpty { keyValue("Activity", snapshot.activityType) }
                if !snapshot.eyfsArea.isEmpty { keyValue("EYFS area", snapshot.eyfsArea) }
                if !snapshot.mealDescription.isEmpty { keyValue("Meal", snapshot.mealDescription) }
                if !snapshot.nappyType.isEmpty { keyValue("Nappy", snapshot.nappyType) }
                if snapshot.moodRating != 0 { keyValue("Mood", "\(snapshot.moodRating)/5") }
            } else {
                Text("Original details are unavailable for this record.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .ncStudioElevatedSurface(cornerRadius: 16)
    }

    private var correctionHistoryCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Correction history", systemImage: "list.bullet.rectangle.portrait")
                .font(.subheadline.weight(.semibold))
            ForEach(groupedCorrections.indices, id: \.self) { idx in
                let group = groupedCorrections[idx]
                VStack(alignment: .leading, spacing: 8) {
                    Text(group.correctedAt.formatted(date: .abbreviated, time: .shortened))
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                    Text("Reason: \(group.reason)")
                        .font(.footnote.weight(.semibold))
                    ForEach(group.changes, id: \.objectID) { change in
                        VStack(alignment: .leading, spacing: 2) {
                            Text(change.fieldName ?? "field")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(.secondary)
                            Text("\(change.oldValue ?? "") -> \(change.newValue ?? "")")
                                .font(.footnote)
                        }
                    }
                }
                if idx < groupedCorrections.count - 1 {
                    Divider()
                }
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .ncStudioElevatedSurface(cornerRadius: 16)
    }

    private var groupedCorrections: [CorrectionGroup] {
        let ordered = entry.sortedCorrections
        var groups: [CorrectionGroup] = []
        for correction in ordered {
            if let last = groups.last, last.correctedAt == correction.correctedAt, last.reason == correction.reason {
                groups[groups.count - 1].changes.append(correction)
            } else {
                groups.append(
                    CorrectionGroup(
                        correctedAt: correction.correctedAt ?? .distantPast,
                        reason: correction.reason ?? "",
                        changes: [correction]
                    )
                )
            }
        }
        return groups.reversed()
    }

    private func keyValue(_ title: String, _ value: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
            Text(value.isEmpty ? "—" : value)
                .font(.footnote)
        }
    }
}

private struct CorrectionGroup {
    let correctedAt: Date
    let reason: String
    var changes: [DiaryEntryCorrection]
}
