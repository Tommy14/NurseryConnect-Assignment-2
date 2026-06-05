//
//  ChildrenSidebarView.swift
//  NurseryConnect
//
//  Feature: Dashboard
//  Role: Keyworker
//  Created: 29 May 2026
//  Description: iPad sidebar listing assigned children grouped by attendance bucket.
//

import Combine
import CoreData
import SwiftUI

/// - Description: Column-one child roster with search and section navigation for iPad.
struct ChildrenSidebarView: View {
    @ObservedObject var viewModel: KeyworkerDashboardViewModel
    @ObservedObject var coordinator: KeyworkerIPadCoordinator
    @Binding var selectedSummary: KeyworkerChildSummary?
    @Binding var incidentComposerPresented: Bool
    @Binding var splitColumnVisibility: NavigationSplitViewVisibility

    @Environment(\.managedObjectContext) private var context
    @State private var childSearchText = ""
    @State private var currentDate = Date()
    @State private var quickCheckInSummary: KeyworkerChildSummary?
    @State private var absentConfirmationSummary: KeyworkerChildSummary?
    @State private var isKeyworkerProfilePresented = false
    @State private var isAbsentSectionCollapsed = false
    @State private var trackedDayStart = Date().startOfDay

    private let chromeButtonWidth: CGFloat = 44
    private let sidebarHorizontalMargin: CGFloat = 12

    var body: some View {
        sidebarList
            .listStyle(.plain)
            .listRowSeparator(.hidden)
            .listSectionSeparator(.hidden)
            .listSectionSpacing(18)
            .contentMargins(.leading, 0, for: .scrollContent)
            .scrollContentBackground(.hidden)
            .background(
                Color(red: 0.90, green: 0.91, blue: 0.96)
                    .ignoresSafeArea()
            )
            .ncRootScrollEdgeEffectForTopNavigation()
            .navigationTitle(AppConstants.navTitleKeyworkerChildrenList)
            .navigationBarTitleDisplayMode(.large)
            .toolbarBackground(.hidden, for: .navigationBar)
            .toolbar { sidebarToolbar }
            .toolbar(removing: .sidebarToggle)
            .blur(radius: isKeyworkerProfilePresented ? 5 : 0)
            .animation(.easeInOut(duration: 0.2), value: isKeyworkerProfilePresented)
            .task { await loadSidebarData() }
            .onReceive(Timer.publish(every: 60, on: .main, in: .common).autoconnect()) { tick in
                currentDate = tick
                let dayStart = tick.startOfDay
                if dayStart != trackedDayStart {
                    trackedDayStart = dayStart
                    isAbsentSectionCollapsed = false
                    Task { await viewModel.reloadChildSummariesFromStore(showLoading: false) }
                }
            }
            .onChange(of: viewModel.hasCheckedInChild) { _, hasCheckedIn in
                Task { await KeyworkerMoodReminderScheduler.registerDailyReminders(hasCheckedInChildren: hasCheckedIn) }
            }
            .onChange(of: coordinator.section) { _, newSection in
                if newSection == .children {
                    Task { await viewModel.reloadChildSummariesFromStore(showLoading: false) }
                }
            }
            .onChange(of: coordinator.dismissAllPresented) { _, shouldDismiss in
                guard shouldDismiss else { return }
                quickCheckInSummary = nil
                absentConfirmationSummary = nil
                isKeyworkerProfilePresented = false
                incidentComposerPresented = false
                coordinator.acknowledgeDismissAllPresented()
            }
            .sheet(isPresented: $isKeyworkerProfilePresented) {
                KeyworkerProfileSheet(assignedRoomName: assignedRoomName)
            }
            .sheet(item: $quickCheckInSummary) { summary in
                quickCheckInSheet(for: summary)
            }
            .alert(absentConfirmationTitle, isPresented: absentConfirmationPresented) {
                Button("No, keep absent", role: .cancel) { absentConfirmationSummary = nil }
                Button("Yes, mark as attending") {
                    guard let summary = absentConfirmationSummary else { return }
                    absentConfirmationSummary = nil
                    Task { await clearAbsentAndOpenCheckIn(for: summary) }
                }
            } message: {
                Text("If attending, we'll clear the absent status and open check-in.")
            }
            .alert("Something went wrong", isPresented: viewModelErrorPresented) {
                Button("OK", role: .cancel) { viewModel.errorMessage = nil }
            } message: {
                Text(viewModel.errorMessage ?? "")
            }
    }

    private var sidebarList: some View {
        List {
            if viewModel.isLoading {
                ProgressView()
                    .tint(Color.ncPrimary)
                    .frame(maxWidth: .infinity)
                    .listRowBackground(Color.clear)
            } else if viewModel.childSummaries.isEmpty {
                ContentUnavailableView(
                    "No children",
                    systemImage: "figure.child",
                    description: Text("Assigned children appear here after the list loads.")
                )
                .listRowBackground(Color.clear)
            } else {
                NCSearchField(text: $childSearchText)
                    .listRowInsets(
                        EdgeInsets(
                            top: 4,
                            leading: sidebarHorizontalMargin,
                            bottom: 4,
                            trailing: sidebarHorizontalMargin
                        )
                    )
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
                childSections
            }
        }
    }

    @ViewBuilder
    private var childSections: some View {
        ForEach(KeyworkerAttendanceBucket.dashboardSectionOrder, id: \.self) { bucket in
            let rows = rows(for: bucket)
            if !rows.isEmpty {
                let canCollapseAbsent = bucket == .absent
                    && NurseryDaySchedule.isAbsentSectionCollapsible(at: currentDate)
                Section {
                    if canCollapseAbsent == false || isAbsentSectionCollapsed == false {
                        ForEach(rows) { summary in
                            childRowButton(for: summary)
                        }
                    }
                } header: {
                    KeyworkerAttendanceSectionHeader(
                        bucket: bucket,
                        rowCount: rows.count,
                        currentDate: currentDate,
                        isAbsentSectionCollapsed: $isAbsentSectionCollapsed
                    )
                    .textCase(nil)
                }
            }
        }
    }

    @ToolbarContentBuilder
    private var sidebarToolbar: some ToolbarContent {
        ToolbarItem(placement: .topBarLeading) {
            Image("NurseryConnectNavLogo")
                .resizable()
                .scaledToFit()
                .frame(width: 36, height: 36)
                .accessibilityLabel("NurseryConnect")
        }

        ToolbarItemGroup(placement: .topBarTrailing) {
            Button {
                isKeyworkerProfilePresented = true
            } label: {
                Image(systemName: "person.crop.circle.fill")
                    .font(.body.weight(.medium))
                    .foregroundStyle(Color.ncPrimary)
                    .frame(width: chromeButtonWidth, height: chromeButtonWidth)
            }
            .accessibilityLabel("My profile")
            .accessibilityIdentifier(AppConstants.AccessibilityID.keyworkerProfileButton)

            Button(action: hideSidebarColumn) {
                Image(systemName: "sidebar.leading")
                    .font(.body.weight(.semibold))
                    .foregroundStyle(Color.ncPrimary)
                    .frame(width: chromeButtonWidth, height: chromeButtonWidth)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Hide children list")
        }
    }

    private func hideSidebarColumn() {
        withAnimation(.easeInOut(duration: 0.25)) {
            splitColumnVisibility = .detailOnly
        }
    }

    private func childRowButton(for summary: KeyworkerChildSummary) -> some View {
        Button {
            handleChildTap(summary)
        } label: {
            ChildSidebarRowView(
                summary: summary,
                isSelected: selectedSummary?.id == summary.id,
                currentDate: currentDate
            )
        }
        .buttonStyle(.plain)
        .listRowInsets(
            EdgeInsets(
                top: 8,
                leading: sidebarHorizontalMargin,
                bottom: 8,
                trailing: sidebarHorizontalMargin
            )
        )
        .listRowSeparator(.hidden)
        .id(summary.dashboardRowIdentity)
    }

    private func quickCheckInSheet(for summary: KeyworkerChildSummary) -> some View {
        DashboardQuickCheckInSheet(
            summary: summary,
            context: context,
            onSuccess: {
                let childID = summary.id
                quickCheckInSummary = nil
                Task {
                    await Task.yield()
                    await viewModel.reloadChildSummariesFromStore(showLoading: false)
                    if let updated = viewModel.childSummaries.first(where: { $0.id == childID }) {
                        selectedSummary = updated
                        coordinator.section = .children
                    }
                }
            },
            onCancel: { quickCheckInSummary = nil }
        )
    }

    private func rows(for bucket: KeyworkerAttendanceBucket) -> [KeyworkerChildSummary] {
        filteredChildSummaries
            .filter { $0.attendanceBucket == bucket }
            .sorted { $0.fullName.localizedCaseInsensitiveCompare($1.fullName) == .orderedAscending }
    }

    private var filteredChildSummaries: [KeyworkerChildSummary] {
        let query = childSearchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else { return viewModel.childSummaries }
        return viewModel.childSummaries.filter { summary in
            let ageText = Date.earlyYearsAgeDescription(dateOfBirth: summary.dateOfBirth)
            return summary.fullName.localizedCaseInsensitiveContains(query)
                || summary.preferredName.localizedCaseInsensitiveContains(query)
                || summary.roomName.localizedCaseInsensitiveContains(query)
                || ageText.localizedCaseInsensitiveContains(query)
        }
    }

    private var assignedRoomName: String {
        let firstNonEmpty = viewModel.childSummaries
            .map(\.roomName)
            .first { $0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false }
        return firstNonEmpty ?? "Unassigned room"
    }

    private var absentConfirmationTitle: String {
        "Is \(absentConfirmationSummary?.fullName ?? "this child") attending today?"
    }

    private var absentConfirmationPresented: Binding<Bool> {
        Binding(
            get: { absentConfirmationSummary != nil },
            set: { if !$0 { absentConfirmationSummary = nil } }
        )
    }

    private var viewModelErrorPresented: Binding<Bool> {
        Binding(
            get: { viewModel.errorMessage != nil },
            set: { if !$0 { viewModel.errorMessage = nil } }
        )
    }

    private func loadSidebarData() async {
        await viewModel.refresh()
        await KeyworkerMoodReminderScheduler.registerDailyReminders(
            hasCheckedInChildren: viewModel.hasCheckedInChild
        )
    }

    private func handleChildTap(_ summary: KeyworkerChildSummary) {
        coordinator.section = .children
        switch summary.attendanceBucket {
        case .awaiting:
            quickCheckInSummary = summary
        case .absent:
            absentConfirmationSummary = summary
        case .onSite, .departed:
            selectedSummary = summary
        }
    }

    @MainActor
    private func clearAbsentAndOpenCheckIn(for summary: KeyworkerChildSummary) async {
        let attendance = AttendanceViewModel(childID: summary.id, context: context)
        await attendance.clearMarkedAbsent()
        if let error = attendance.errorMessage {
            viewModel.errorMessage = error
            return
        }

        await viewModel.reloadChildSummariesFromStore(showLoading: false)
        if let updated = viewModel.childSummaries.first(where: { $0.id == summary.id }) {
            quickCheckInSummary = updated
        } else {
            quickCheckInSummary = summary
        }
    }
}
