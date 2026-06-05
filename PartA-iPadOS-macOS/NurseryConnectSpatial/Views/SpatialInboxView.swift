//
//  SpatialInboxView.swift
//  NurseryConnect Spatial
//
//  Feature: Spatial
//  Role: Keyworker
//  Created: 30 May 2026
//  Description: Spatial messaging inbox with unread threads, engagement chart, and quick actions.
//

import Combine
import CoreData
import SwiftUI

private enum SpatialChildFilter: String, CaseIterable, Identifiable {
    case all
    case onSite
    case alerts

    var id: String { rawValue }

    var title: String {
        switch self {
        case .all: return "All"
        case .onSite: return "On site"
        case .alerts: return "Alerts"
        }
    }
}

/// - Description: Keyworker spatial workspace for secure messaging and analytics.
struct SpatialInboxView: View {
    @Environment(\.managedObjectContext) private var context
    @Environment(\.dismissWindow) private var dismissWindow
    @Environment(\.openWindow) private var openWindow

    @StateObject private var viewModel: MessagingViewModel
    @StateObject private var dashboardViewModel: SpatialDashboardViewModel
    @State private var selectedChildID: UUID?
    @State private var selectedThreadID: UUID?
    @State private var childFilter: SpatialChildFilter = .all
    @State private var currentDate = Date()
    @State private var showsEndOfDaySheet = false
    @State private var showsThreadDetail = false
    @State private var showsAllMessages = false
    @State private var showsIncidents = false
    @State private var showsNoThreadAlert = false
    @State private var showsDiarySheet = false
    @State private var showsIncidentForm = false

    init(managedObjectContext: NSManagedObjectContext) {
        _viewModel = StateObject(wrappedValue: MessagingViewModel(context: managedObjectContext))
        _dashboardViewModel = StateObject(wrappedValue: SpatialDashboardViewModel(context: managedObjectContext))
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                header
                SpatialTodaySnapshotView(stats: todayStats)
                HStack(alignment: .top, spacing: 20) {
                    unreadPanel
                        .frame(maxWidth: .infinity)
                    engagementPanel
                        .frame(maxWidth: .infinity)
                }
                SpatialRecentIncidentsPanel(nurseryWide: false) {
                    showsIncidents = true
                }
                childPicker
                if let summary = selectedChildSummary {
                    SpatialSelectedChildPanel(summary: summary)
                }
                quickActions
            }
            .padding(28)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background {
            LinearGradient(
                colors: [Color.ncBackground, Color.ncGlowBlue.opacity(0.08)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
        .refreshable {
            await reload()
        }
        .task {
            await reload()
        }
        .onReceive(NotificationCenter.default.publisher(for: .NSManagedObjectContextObjectsDidChange, object: context)) { _ in
            Task { await reload() }
        }
        .onReceive(Timer.publish(every: 60, on: .main, in: .common).autoconnect()) { tick in
            currentDate = tick
        }
        .sheet(isPresented: $showsThreadDetail) {
            if let threadID = selectedThreadID {
                NavigationStack {
                    ThreadDetailView(threadID: threadID, managedObjectContext: context)
                        .toolbar {
                            ToolbarItem(placement: .cancellationAction) {
                                Button("Done") { showsThreadDetail = false }
                            }
                        }
                }
            }
        }
        .sheet(isPresented: $showsAllMessages) {
            NavigationStack {
                MessagingView(managedObjectContext: context)
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) {
                            Button("Done") { showsAllMessages = false }
                        }
                    }
            }
        }
        .sheet(isPresented: $showsIncidents) {
            SpatialIncidentsSheet()
                .environment(\.managedObjectContext, context)
        }
        .sheet(isPresented: $showsEndOfDaySheet) {
            if let summary = selectedChildSummary {
                EndOfDaySummarySheet(
                    childID: summary.id,
                    childDisplayName: summary.preferredName.isEmpty ? summary.firstName : summary.preferredName,
                    managedObjectContext: context
                )
            }
        }
        .sheet(isPresented: $showsDiarySheet) {
            if let summary = selectedChildSummary {
                let child = NCChild(
                    id: summary.id,
                    firstName: summary.firstName, lastName: summary.lastName,
                    preferredName: summary.preferredName,
                    dateOfBirth: Calendar.current.date(byAdding: .year, value: -3, to: Date()) ?? Date(),
                    room: summary.roomName, keyworkerName: AppConstants.keyworkerDisplayName,
                    allergies: [], dietaryRestrictions: [], medicalConditions: [],
                    photoConsent: summary.photoConsent, socialMediaConsent: true,
                    status: .onSite
                )
                SpatialDailyDiaryView(child: child)
            }
        }
        .sheet(isPresented: $showsIncidentForm) {
            SpatialIncidentReportView()
                .environmentObject(SpatialDataStore())
        }
        .alert("Something went wrong", isPresented: errorPresented) {
            Button("OK", role: .cancel) { viewModel.errorMessage = nil }
        } message: {
            Text(viewModel.errorMessage ?? "")
        }
        .alert("No conversation yet", isPresented: $showsNoThreadAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("Open All messages to start a thread when a parent has messaged you.")
        }
    }

    private var header: some View {
        HStack(alignment: .top, spacing: 16) {
            VStack(alignment: .leading, spacing: 6) {
                Text("Keyworker dashboard")
                    .font(.largeTitle.weight(.bold))
                Text(greetingText)
                    .font(.title3.weight(.medium))
                    .foregroundStyle(.secondary)
                Text("\(AppConstants.keyworkerDisplayName) · \(AppConstants.nurseryDisplayName)")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Text(currentDate.formattedMediumDate())
                    .font(.caption.weight(.medium).monospacedDigit())
                    .foregroundStyle(Color.ncPrimary)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(Color.ncPrimary.opacity(0.12), in: Capsule())
            }
            Spacer(minLength: 0)
            HStack(spacing: 8) {
                Button {
                    Task { await reload() }
                } label: {
                    Image(systemName: "arrow.clockwise")
                        .font(.body.weight(.semibold))
                        .frame(width: 40, height: 40)
                }
                .buttonStyle(.bordered)
                .accessibilityLabel("Refresh dashboard")
                Button("Done") {
                    dismissWindow(id: SpatialWindowID.keyworkerDashboard)
                }
                .buttonStyle(.bordered)
            }
        }
    }

    private var todayStats: [SpatialSnapshotStat] {
        let summaries = dashboardViewModel.childSummaries
        let onSite = summaries.filter { $0.attendanceBucket == .onSite }.count
        let awaiting = summaries.filter { $0.attendanceBucket == .awaiting }.count
        let openIncidents = summaries.filter(\.hasOpenIncident).count
        let diaryGaps = summaries.filter { $0.attendanceBucket != .absent && $0.dot != .complete }.count
        return [
            SpatialSnapshotStat(
                id: "onSite",
                title: "On site now",
                value: "\(onSite)",
                systemImage: "figure.and.child.holdinghands",
                tint: Color.ncSecondary
            ),
            SpatialSnapshotStat(
                id: "awaiting",
                title: "Awaiting check-in",
                value: "\(awaiting)",
                systemImage: "clock.badge.questionmark",
                tint: Color.ncAccentWarm
            ),
            SpatialSnapshotStat(
                id: "incidents",
                title: "Open incidents",
                value: "\(openIncidents)",
                systemImage: "exclamationmark.shield.fill",
                tint: Color.ncDanger
            ),
            SpatialSnapshotStat(
                id: "diary",
                title: "Diary incomplete",
                value: "\(diaryGaps)",
                systemImage: "book.closed.fill",
                tint: Color.ncPrimary
            )
        ]
    }

    private var unreadPanel: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label("Unread messages", systemImage: "envelope.badge")
                    .font(.headline)
                Spacer()
                if viewModel.unreadCount > 0 {
                    Text("\(viewModel.unreadCount)")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(Color.red, in: Capsule())
                }
                Button("See all") {
                    showsAllMessages = true
                }
                .font(.caption.weight(.semibold))
            }

            if unreadRows.isEmpty {
                VStack(spacing: 0) {
                    Spacer(minLength: 0)
                    ContentUnavailableView {
                        Label("All caught up", systemImage: "checkmark.message")
                    } description: {
                        Text("No unread messages from parents or your Setting Manager.")
                    }
                    .multilineTextAlignment(.center)
                    Spacer(minLength: 0)
                }
                .frame(maxWidth: .infinity, minHeight: 240)
            } else {
                ScrollView {
                    LazyVStack(spacing: 8) {
                        ForEach(unreadRows) { row in
                            Button {
                                selectedThreadID = row.threadID
                                viewModel.markThreadAsRead(threadID: row.threadID)
                                showsThreadDetail = true
                            } label: {
                                MessageThreadRowView(row: row)
                                    .padding(12)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                .frame(minHeight: 180, maxHeight: 280)
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity, minHeight: 300, alignment: .top)
        .glassBackgroundEffect(in: RoundedRectangle(cornerRadius: 20, style: .continuous))
    }

    private var engagementPanel: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Parent engagement (7 days)")
                .font(.headline)
            MessageActivityChart()
            Text("Shows parent messages received per day. A sudden drop may indicate reduced engagement.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(20)
        .frame(maxWidth: .infinity, minHeight: 300, alignment: .top)
        .glassBackgroundEffect(in: RoundedRectangle(cornerRadius: 20, style: .continuous))
    }

    private var childPicker: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Assigned children")
                    .font(.headline)
                Spacer()
                Text("\(filteredSummaries.count) shown")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Picker("Filter", selection: $childFilter) {
                ForEach(SpatialChildFilter.allCases) { filter in
                    Text(filter.title).tag(filter)
                }
            }
            .pickerStyle(.segmented)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(filteredSummaries) { summary in
                        let isSelected = selectedChildID == summary.id
                        Button {
                            selectedChildID = summary.id
                        } label: {
                            HStack(spacing: 6) {
                                if summary.hasOpenIncident {
                                    Image(systemName: "exclamationmark.circle.fill")
                                        .font(.caption2)
                                        .foregroundStyle(Color.ncDanger)
                                }
                                Text(compactName(for: summary))
                                    .font(.subheadline.weight(isSelected ? .semibold : .regular))
                            }
                            .padding(.horizontal, 14)
                            .padding(.vertical, 8)
                            .background(
                                isSelected ? Color.ncPrimary.opacity(0.2) : Color(.tertiarySystemFill),
                                in: Capsule()
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
        .padding(20)
        .glassBackgroundEffect(in: RoundedRectangle(cornerRadius: 20, style: .continuous))
    }

    private var quickActions: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Quick actions")
                .font(.headline)
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                Button {
                    showsEndOfDaySheet = selectedChildSummary != nil
                } label: {
                    Label("Log End of Day Summary", systemImage: "paperplane.fill")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .tint(Color.ncPrimary)
                .disabled(selectedChildSummary == nil)

                Button {
                    openMoodChartWindow()
                } label: {
                    moodChartButtonLabel
                }
                .buttonStyle(.bordered)
                .disabled(selectedChildSummary == nil)

                Button {
                    openParentThread()
                } label: {
                    Label("Message parent", systemImage: "bubble.left.and.bubble.right.fill")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .disabled(selectedChildSummary == nil)

                Button {
                    showsIncidents = true
                } label: {
                    Label("View incidents", systemImage: "exclamationmark.shield.fill")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)

                Button {
                    showsDiarySheet = selectedChildSummary != nil
                } label: {
                    Label("View daily diary", systemImage: "book.fill")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .disabled(selectedChildSummary == nil)

                Button {
                    showsIncidentForm = true
                } label: {
                    Label("Log incident", systemImage: "bandage.fill")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
            }
        }
    }

    private var unreadRows: [MessageThreadRow] {
        viewModel.groupedSections
            .filter { $0.section == .unread || $0.rows.contains(where: \.hasUnread) }
            .flatMap(\.rows)
            .filter(\.hasUnread)
    }

    private var filteredSummaries: [SpatialChildSummary] {
        let all = dashboardViewModel.childSummaries
        switch childFilter {
        case .all:
            return all
        case .onSite:
            return all.filter { $0.attendanceBucket == .onSite }
        case .alerts:
            return all.filter { summary in
                summary.hasOpenIncident
                    || (summary.attendanceBucket == .onSite && summary.dot == .none)
                    || (summary.attendanceBucket == .onSite && !summary.photoConsent)
            }
        }
    }

    private var selectedChildSummary: SpatialChildSummary? {
        if let selectedChildID,
           let match = dashboardViewModel.childSummaries.first(where: { $0.id == selectedChildID }) {
            return match
        }
        return dashboardViewModel.childSummaries.first
    }

    private var errorPresented: Binding<Bool> {
        Binding(
            get: { viewModel.errorMessage != nil },
            set: { if !$0 { viewModel.errorMessage = nil } }
        )
    }

    private var greetingText: String {
        let hour = Calendar.current.component(.hour, from: currentDate)
        switch hour {
        case 5..<12: return "Good morning"
        case 12..<17: return "Good afternoon"
        case 17..<22: return "Good evening"
        default: return "Good night"
        }
    }

    @MainActor
    private func reload() async {
        await dashboardViewModel.refresh()
        await viewModel.refresh()
        if selectedChildID == nil {
            selectedChildID = dashboardViewModel.childSummaries.first?.id
        }
    }

    private func compactName(for summary: SpatialChildSummary) -> String {
        let first = summary.preferredName.isEmpty ? summary.firstName : summary.preferredName
        let initial = summary.lastName.trimmingCharacters(in: .whitespacesAndNewlines).prefix(1)
        guard !initial.isEmpty else { return first }
        return "\(first) \(initial)."
    }

    private var moodChartButtonLabel: some View {
        Label("Open Mood Chart 3D", systemImage: "chart.bar.fill")
            .frame(maxWidth: .infinity)
    }

    private func openMoodChartWindow() {
        guard let childID = selectedChildSummary?.id else { return }
        let windowValue = MoodChartWindowID(childID: childID)
        Task { @MainActor in
            openWindow(id: "mood-chart", value: windowValue)
        }
    }

    private func openParentThread() {
        guard let childID = selectedChildSummary?.id else { return }
        if let threadID = viewModel.groupedSections.flatMap(\.rows).first(where: { $0.childID == childID })?.threadID {
            selectedThreadID = threadID
            viewModel.markThreadAsRead(threadID: threadID)
            showsThreadDetail = true
        } else {
            showsNoThreadAlert = true
        }
    }
}
