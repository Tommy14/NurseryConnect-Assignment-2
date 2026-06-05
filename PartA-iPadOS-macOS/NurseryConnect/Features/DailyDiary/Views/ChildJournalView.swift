//
//  ChildJournalView.swift
//  NurseryConnect
//
//  Feature: Daily Diary
//  Role: Keyworker
//  Created: 29 May 2026
//  Description: iPad content column hosting journal, milestones, or charts for one child.
//

import CoreData
import SwiftUI

/// - Description: Hosts the selected child's diary content with iPad toolbar chrome.
struct ChildJournalView: View {
    let summary: KeyworkerChildSummary?
    @ObservedObject var dashboardViewModel: KeyworkerDashboardViewModel
    /// - Description: When true, the iPad shell renders `ChildJournalSegmentBar` above this column.
    var usesExternalSegmentBar = false
    @Binding var selectedSummary: KeyworkerChildSummary?
    @Binding var segmentBarSyncStatus: String

    @Environment(\.managedObjectContext) private var context
    @EnvironmentObject private var coordinator: KeyworkerIPadCoordinator
    @State private var externalAddSheetTrigger = false
    @StateObject private var diaryViewModel: DailyDiaryViewModel

    init(
        summary: KeyworkerChildSummary?,
        managedObjectContext: NSManagedObjectContext,
        dashboardViewModel: KeyworkerDashboardViewModel,
        usesExternalSegmentBar: Bool = false,
        selectedSummary: Binding<KeyworkerChildSummary?> = .constant(nil),
        segmentBarSyncStatus: Binding<String> = .constant("Synced")
    ) {
        self.summary = summary
        self.dashboardViewModel = dashboardViewModel
        self.usesExternalSegmentBar = usesExternalSegmentBar
        _selectedSummary = selectedSummary
        _segmentBarSyncStatus = segmentBarSyncStatus
        let childID = summary?.id ?? UUID()
        _diaryViewModel = StateObject(
            wrappedValue: DailyDiaryViewModel(childID: childID, context: managedObjectContext)
        )
    }

    var body: some View {
        Group {
            if let summary {
                journalSegmentBody(for: summary)
                    .task(id: summary.id) {
                        await diaryViewModel.loadEntries()
                        publishSegmentBarSyncStatus()
                    }
                    .onChange(of: diaryViewModel.entries) { _, _ in
                        publishSegmentBarSyncStatus()
                    }
                    .onChange(of: coordinator.requestNewDiaryEntry) { _, shouldOpen in
                        guard shouldOpen, coordinator.journalContentSegment == .journal else { return }
                        externalAddSheetTrigger = true
                        coordinator.acknowledgeNewDiaryEntryRequest()
                    }
                    .onChange(of: coordinator.journalContentSegment) { _, newSegment in
                        if newSegment != .charts {
                            coordinator.journalEntryTypeFilter = nil
                        }
                    }
            } else {
                ContentUnavailableView {
                    Label("Select a child", systemImage: "figure.child")
                } description: {
                    Text("Choose a child from the sidebar to view their journal.")
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .ncStudioScreenBackdrop()
            }
        }
        .onChange(of: coordinator.requestNewDiaryEntry) { _, shouldOpen in
            guard shouldOpen, summary != nil else { return }
            if coordinator.journalContentSegment != .journal {
                coordinator.journalContentSegment = .journal
            }
        }
    }

    @ViewBuilder
    private func journalSegmentBody(for summary: KeyworkerChildSummary) -> some View {
        let content = segmentContent(for: summary)
            .id(coordinator.journalContentSegment)
            .animation(.easeInOut(duration: 0.22), value: coordinator.journalContentSegment)
            .modifier(ChildJournalNavigationChrome(
                summary: summary,
                usesExternalSegmentBar: usesExternalSegmentBar,
                syncStatusLabel: syncStatusLabel,
                journalContentSegment: coordinator.journalContentSegment,
                journalContentSegmentBinding: $coordinator.journalContentSegment
            ))

        if usesExternalSegmentBar {
            content.childJournalSegmentSwipe(selection: $coordinator.journalContentSegment)
        } else {
            content
        }
    }

    @ViewBuilder
    private func segmentContent(for summary: KeyworkerChildSummary) -> some View {
        switch coordinator.journalContentSegment {
        case .journal:
            DailyDiaryListView(
                summary: summary,
                managedObjectContext: context,
                presentationStyle: .splitViewEmbedded,
                externalAddSheetTrigger: $externalAddSheetTrigger,
                highlightedEntryType: coordinator.journalEntryTypeFilter,
                showsAnalyticsSummary: true
            )
        case .charts:
            ChildAnalyticsDashboardView(
                childID: summary.id,
                childDisplayName: summary.fullName,
                managedObjectContext: context
            )
        case .milestones:
            MilestoneEntriesView(viewModel: diaryViewModel)
        }
    }

    private var syncStatusLabel: String {
        ChildJournalSyncLabel.text(for: diaryViewModel.entries)
    }

    private func publishSegmentBarSyncStatus() {
        guard usesExternalSegmentBar else { return }
        segmentBarSyncStatus = syncStatusLabel
    }
}

/// - Description: Applies navigation chrome for phone vs iPad workspace embedding.
private struct ChildJournalNavigationChrome: ViewModifier {
    let summary: KeyworkerChildSummary
    let usesExternalSegmentBar: Bool
    let syncStatusLabel: String
    let journalContentSegment: ChildJournalSegment
    @Binding var journalContentSegmentBinding: ChildJournalSegment

    func body(content: Content) -> some View {
        if usesExternalSegmentBar {
            content
                .toolbar(.hidden, for: .navigationBar)
        } else {
            content
                .navigationTitle(summary.fullName)
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .principal) {
                        Picker("Content", selection: $journalContentSegmentBinding) {
                            ForEach(ChildJournalSegment.allCases) { segment in
                                Text(segment.title).tag(segment)
                            }
                        }
                        .pickerStyle(.segmented)
                        .frame(maxWidth: 320)
                    }
                    if journalContentSegment != .charts {
                        ToolbarItem(placement: .topBarTrailing) {
                            Text(syncStatusLabel)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
        }
    }
}

/// - Description: Read-only sync summary for the journal toolbar.
enum ChildJournalSyncLabel {
    static func text(for entries: [DiaryEntry]) -> String {
        guard !entries.isEmpty else { return "Synced" }

        if entries.contains(where: { SyncState.fromPersistence($0.syncState) == .failed }) {
            return "Sync failed"
        }
        if entries.contains(where: { SyncState.fromPersistence($0.syncState) == .pending }) {
            return "Sync pending"
        }
        if let latest = entries.compactMap(\.syncEnqueuedAt).max() {
            return "Synced \(latest.formatted(.relative(presentation: .named)))"
        }
        return "Synced"
    }
}
