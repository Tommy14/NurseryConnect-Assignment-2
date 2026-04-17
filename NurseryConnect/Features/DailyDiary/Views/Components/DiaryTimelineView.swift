//
//  DiaryTimelineView.swift
//  NurseryConnect
//
//  Feature: Daily Diary
//  Role: Keyworker
//  Created: 4 April 2026
//  Description: Vertical timeline merging the nursery schedule with diary entries; past rows collapse.
//
// -----------------------------------------------------------------
// Date       Name        What has done
// -----------------------------------------------------------------
// 040426     Tommy1914   Created the file with grouped sections and connector line.
// 100426     Tommy1914   Time-band headers with index accent for dossier-style timeline.
// 180426     Tommy1914   Sync badge on tile; calmer time-band marker.
// 180426     Tommy1914   Merged schedule + entries; expandable past rows.
// 180426     Tommy1914   Planned sessions nest logs; tap-to-log from session row.
// 180426     Tommy1914   Log UI by phase: big button current only; past small plus; upcoming none.
// -----------------------------------------------------------------

import Combine
import CoreData
import SwiftUI

/// - Description: Renders merged schedule + diary rows with compact past rows.
struct DiaryTimelineView: View {
    let mergedRows: [MergedDiaryTimelineRow]
    @ObservedObject var viewModel: DailyDiaryViewModel
    /// - Description: Reference clock for “past” collapse (parent may tick periodically).
    var now: Date
    /// - Description: Opens add-diary with prefill for this planned session (plus button / “Log observation”).
    var onLogForPlannedSession: ((NurseryScheduleSegment) -> Void)?

    @State private var expandedRowIDs: Set<String> = []

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ForEach(Array(mergedRows.enumerated()), id: \.element.id) { index, row in
                let past = isPast(row)
                let expanded = expandedRowIDs.contains(row.id) || !past
                HStack(alignment: .top, spacing: 12) {
                    VStack {
                        Circle()
                            .fill(nodeColor(for: row))
                            .frame(width: 14, height: 14)
                            .overlay(
                                Circle()
                                    .stroke(Color.ncCardSurface, lineWidth: 2)
                            )
                        if index < mergedRows.count - 1 {
                            Rectangle()
                                .fill(Color.secondary.opacity(0.25))
                                .frame(width: 2)
                                .frame(maxHeight: .infinity)
                        } else {
                            Spacer(minLength: 0)
                        }
                    }
                    .frame(width: 18)

                    rowContent(for: row, past: past, expanded: expanded)
                        .padding(.bottom, 18)
                }
            }
        }
    }

    private func isPast(_ row: MergedDiaryTimelineRow) -> Bool {
        row.intervalEnd < now
    }

    private func nodeColor(for row: MergedDiaryTimelineRow) -> Color {
        switch row {
        case .plannedSession:
            return Color.ncPrimary.opacity(0.55)
        case .sleep:
            return AppTheme.diaryColor(for: .sleep)
        case .orphanDiary(let entry):
            return AppTheme.diaryColor(for: DiaryEntryType.fromPersistence(entry.entryType ?? ""))
        }
    }

    @ViewBuilder
    private func rowContent(for row: MergedDiaryTimelineRow, past: Bool, expanded: Bool) -> some View {
        switch row {
        case .plannedSession(let segment, let nested):
            let phase = plannedSessionPhase(segment: segment)
            let sessionEnded = (phase == .past)
            let sessionExpanded = expandedRowIDs.contains(row.id) || !sessionEnded
            plannedSessionBlock(
                segment: segment,
                nested: nested,
                phase: phase,
                expanded: sessionExpanded,
                rowId: row.id
            )
        case .sleep(let entry):
            diaryBlock(entry: entry, type: .sleep, past: past, expanded: expanded, rowId: row.id)
        case .orphanDiary(let entry):
            let type = DiaryEntryType.fromPersistence(entry.entryType ?? "")
            diaryBlock(entry: entry, type: type, past: past, expanded: expanded, rowId: row.id)
        }
    }

    /// - Description: Where “now” sits relative to the planned window `[start, end)` (half-open).
    private func plannedSessionPhase(segment: NurseryScheduleSegment) -> PlannedSessionPhase {
        if now < segment.start { return .upcoming }
        if now < segment.end { return .current }
        return .past
    }

    private enum PlannedSessionPhase {
        case upcoming
        case current
        case past
    }

    private func plannedSessionSubtitle(nestedCount: Int) -> String {
        if nestedCount == 0 { return "Planned" }
        return "Planned · \(nestedCount) log\(nestedCount == 1 ? "" : "s")"
    }

    private func plannedSessionBlock(
        segment: NurseryScheduleSegment,
        nested: [DiaryEntry],
        phase: PlannedSessionPhase,
        expanded: Bool,
        rowId: String
    ) -> some View {
        let timeText = "\(segment.start.formattedTime()) – \(segment.end.formattedTime())"
        return Group {
            if phase == .past && !expanded {
                HStack(alignment: .center, spacing: 10) {
                    Button {
                        _ = expandedRowIDs.insert(rowId)
                    } label: {
                        collapsedLabel(
                            timeText: timeText,
                            title: segment.block.title,
                            subtitle: plannedSessionSubtitle(nestedCount: nested.count),
                            systemImage: "calendar"
                        )
                    }
                    .buttonStyle(.plain)
                    if let onLog = onLogForPlannedSession {
                        Button {
                            onLog(segment)
                        } label: {
                            Image(systemName: "plus.circle.fill")
                                .font(.title2)
                                .foregroundStyle(Color.ncPrimary)
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("Log observation for this planned session")
                    }
                }
            } else {
                VStack(alignment: .leading, spacing: 10) {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack(alignment: .top, spacing: 10) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(timeText)
                                    .font(.caption.weight(.semibold))
                                    .foregroundStyle(.secondary)
                                    .monospacedDigit()
                                Text(segment.block.title)
                                    .font(.headline.weight(.semibold))
                                    .foregroundStyle(.primary)
                                Text("Planned session")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer(minLength: 0)
                            if phase == .past {
                                HStack(spacing: 10) {
                                    if let onLog = onLogForPlannedSession {
                                        Button {
                                            onLog(segment)
                                        } label: {
                                            Image(systemName: "plus.circle.fill")
                                                .font(.title2)
                                                .foregroundStyle(Color.ncPrimary)
                                        }
                                        .buttonStyle(.plain)
                                        .accessibilityLabel("Log observation for this planned session")
                                    }
                                    Button {
                                        expandedRowIDs.remove(rowId)
                                    } label: {
                                        Image(systemName: "chevron.up.circle.fill")
                                            .font(.body)
                                            .foregroundStyle(.tertiary)
                                    }
                                    .buttonStyle(.plain)
                                    .accessibilityLabel("Collapse")
                                }
                            }
                        }
                        if phase == .current, let onLog = onLogForPlannedSession {
                            Button {
                                onLog(segment)
                            } label: {
                                Label("Log observation", systemImage: "plus.circle.fill")
                                    .font(.subheadline.weight(.semibold))
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 10)
                            }
                            .buttonStyle(.borderedProminent)
                            .tint(Color.ncPrimary)
                            .accessibilityIdentifier("planned_session_log_observation")
                        }
                    }
                    .padding(14)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background {
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .fill(Color.ncPrimary.opacity(0.06))
                    }
                    .overlay {
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .stroke(Color.ncPrimary.opacity(0.2), lineWidth: 1)
                    }
                    .contentShape(Rectangle())
                    .onTapGesture {
                        guard phase == .past else { return }
                        expandedRowIDs.remove(rowId)
                    }

                    if !nested.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            ForEach(nested, id: \.objectID) { entry in
                                let type = DiaryEntryType.fromPersistence(entry.entryType ?? "")
                                ZStack(alignment: .topTrailing) {
                                    Group {
                                        if phase == .past {
                                            Button {
                                                expandedRowIDs.remove(rowId)
                                            } label: {
                                                diaryCard(for: entry, type: type)
                                            }
                                            .buttonStyle(.plain)
                                            .accessibilityLabel("Collapse planned session")
                                        } else {
                                            NavigationLink {
                                                DiaryEntryDetailView(entry: entry, viewModel: viewModel)
                                            } label: {
                                                diaryCard(for: entry, type: type)
                                            }
                                            .buttonStyle(.plain)
                                        }
                                    }
                                    if entry.needsLateLogManagerReview {
                                        lateLogBadge
                                            .padding(8)
                                            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
                                            .padding(.top, 40)
                                    }
                                    SyncStateBadgeView(state: viewModel.syncState(for: entry))
                                        .padding(8)
                                }
                                .padding(.leading, 10)
                                .overlay(alignment: .leading) {
                                    Rectangle()
                                        .fill(Color.ncPrimary.opacity(0.35))
                                        .frame(width: 3)
                                        .padding(.leading, 0)
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    private func diaryBlock(entry: DiaryEntry, type: DiaryEntryType, past: Bool, expanded: Bool, rowId: String) -> some View {
        Group {
            if past && !expanded {
                Button {
                    _ = expandedRowIDs.insert(rowId)
                } label: {
                    collapsedLabel(
                        timeText: (entry.timestamp ?? Date()).formattedTime(),
                        title: collapsedTitle(for: entry, type: type),
                        subtitle: diaryTypeLabel(type),
                        systemImage: iconName(for: type)
                    )
                }
                .buttonStyle(.plain)
            } else {
                VStack(alignment: .leading, spacing: 0) {
                    ZStack(alignment: .topTrailing) {
                        Group {
                            if past {
                                Button {
                                    expandedRowIDs.remove(rowId)
                                } label: {
                                    diaryCard(for: entry, type: type)
                                }
                                .buttonStyle(.plain)
                                .accessibilityLabel("Collapse diary entry")
                            } else {
                                NavigationLink {
                                    DiaryEntryDetailView(entry: entry, viewModel: viewModel)
                                } label: {
                                    diaryCard(for: entry, type: type)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        if entry.needsLateLogManagerReview {
                            lateLogBadge
                                .padding(8)
                                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
                                .padding(.top, 40)
                        }
                        SyncStateBadgeView(state: viewModel.syncState(for: entry))
                            .padding(8)
                    }
                    if past {
                        HStack {
                            Spacer(minLength: 0)
                            Button {
                                expandedRowIDs.remove(rowId)
                            } label: {
                                Label("Show less", systemImage: "chevron.up")
                                    .font(.caption.weight(.semibold))
                                    .foregroundStyle(.tertiary)
                            }
                            .buttonStyle(.plain)
                        }
                        .padding(.top, 4)
                    }
                }
            }
        }
    }

    private func collapsedLabel(timeText: String, title: String, subtitle: String, systemImage: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: systemImage)
                .font(.caption.weight(.semibold))
                .foregroundStyle(Color.ncPrimary.opacity(0.85))
                .frame(width: 18)
            VStack(alignment: .leading, spacing: 2) {
                Text(timeText)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .monospacedDigit()
                Text(title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.primary)
                    .lineLimit(2)
                Text(subtitle)
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
            Spacer(minLength: 0)
            Image(systemName: "chevron.down.circle")
                .font(.body)
                .foregroundStyle(.tertiary)
        }
        .padding(10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color.primary.opacity(0.04))
        }
        .accessibilityHint("Double tap to expand")
    }

    private func collapsedTitle(for entry: DiaryEntry, type: DiaryEntryType) -> String {
        switch type {
        case .meal:
            return entry.activityType ?? "Meal"
        case .activity:
            return entry.activityType ?? "Activity"
        case .sleep:
            return "Sleep (\(entry.duration) min)"
        case .nappy:
            return entry.nappyType ?? "Nappy"
        case .wellbeing:
            return "Wellbeing"
        case .milestone:
            return entry.activityType ?? "Milestone"
        }
    }

    private func diaryTypeLabel(_ type: DiaryEntryType) -> String {
        switch type {
        case .activity: return "Activity"
        case .sleep: return "Sleep"
        case .meal: return "Meal"
        case .nappy: return "Nappy"
        case .wellbeing: return "Wellbeing"
        case .milestone: return "Milestone"
        }
    }

    private func iconName(for type: DiaryEntryType) -> String {
        switch type {
        case .activity: return "figure.play"
        case .sleep: return "bed.double.fill"
        case .meal: return "fork.knife"
        case .nappy: return "drop.fill"
        case .wellbeing: return "heart.fill"
        case .milestone: return "star.fill"
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

    private var lateLogBadge: some View {
        Label("Review", systemImage: "exclamationmark.triangle.fill")
            .font(.caption2.weight(.semibold))
            .foregroundStyle(Color.ncDanger)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(
                Capsule(style: .continuous)
                    .fill(Color.ncDanger.opacity(0.14))
            )
    }
}
