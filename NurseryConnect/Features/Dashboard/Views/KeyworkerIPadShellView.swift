//
//  KeyworkerIPadShellView.swift
//  NurseryConnect
//
//  Feature: Dashboard
//  Role: Keyworker
//  Created: 29 May 2026
//  Description: iPad keyworker shell with sidebar plus a composite main area (journal + fixed profile strip).
//

import CoreData
import SwiftUI

private enum KeyworkerIPadTrailingPanel {
    static let profileWidth: CGFloat = 400
    static let messageThreadWidth: CGFloat = 400
}

/// - Description: Regular-width root presenting sidebar and a main workspace (content + optional trailing panel).
struct KeyworkerIPadShellView: View {
    @Environment(\.managedObjectContext) private var context
    @EnvironmentObject private var coordinator: KeyworkerIPadCoordinator
    @StateObject private var dashboardViewModel: KeyworkerDashboardViewModel
    @State private var selectedSummary: KeyworkerChildSummary?
    @State private var selectedMessageThreadID: UUID?
    @State private var incidentComposerPresented = false
    @State private var journalSyncStatusLabel = "Synced"
    @State private var splitColumnVisibility: NavigationSplitViewVisibility = .all
    @State private var isProfilePanelCollapsed = false
    @State private var incidentsNavigationResetID = UUID()
    @StateObject private var incidentComposerViewModel: IncidentViewModel

    init(managedObjectContext: NSManagedObjectContext) {
        _dashboardViewModel = StateObject(wrappedValue: KeyworkerDashboardViewModel(context: managedObjectContext))
        _incidentComposerViewModel = StateObject(wrappedValue: IncidentViewModel(context: managedObjectContext))
    }

    var body: some View {
        ZStack {
            NavigationSplitView(columnVisibility: $splitColumnVisibility) {
                ChildrenSidebarView(
                    viewModel: dashboardViewModel,
                    coordinator: coordinator,
                    selectedSummary: $selectedSummary,
                    incidentComposerPresented: $incidentComposerPresented,
                    splitColumnVisibility: $splitColumnVisibility
                )
                .navigationSplitViewColumnWidth(min: 240, ideal: 280, max: 320)
            } detail: {
                Group {
                    if coordinator.section == .children {
                        childrenWorkspace
                    } else {
                        standardWorkspace
                    }
                }
                .environment(\.keyworkerSidebarHidden, isChildrenSidebarHidden)
                .environment(\.keyworkerRevealSidebar, showChildrenSidebar)
                .ncStudioScreenBackdrop()
            }
            .environment(\.usesFloatingTabBarShell, true)
            .safeAreaInset(edge: .bottom, spacing: 0) {
                if !incidentComposerPresented {
                    KeyworkerIPadBottomDock(
                        section: Binding(
                            get: { coordinator.section },
                            set: { newSection in
                                selectSection(newSection)
                            }
                        )
                    )
                }
            }

            if incidentComposerPresented {
                IncidentComposerOverlay(
                    viewModel: incidentComposerViewModel,
                    isPresented: $incidentComposerPresented
                )
                .transition(.opacity)
                .zIndex(1)
            }
        }
        .animation(.easeInOut(duration: 0.22), value: incidentComposerPresented)
        .onChange(of: coordinator.section) { oldSection, newSection in
            if newSection != .incidents {
                resetIncidentsNavigation()
                incidentComposerPresented = false
            }
            if newSection != .messages {
                selectedMessageThreadID = nil
            }
            if newSection != oldSection, newSection == .incidents, coordinator.requestNewIncident {
                incidentComposerPresented = true
                coordinator.acknowledgeNewIncidentRequest()
            }
        }
        .onChange(of: coordinator.incidentsNavigationResetToken) { _, _ in
            resetIncidentsNavigation()
            incidentComposerPresented = false
        }
        .onChange(of: coordinator.requestNewIncident) { _, shouldOpen in
            guard shouldOpen else { return }
            coordinator.section = .incidents
            incidentComposerPresented = true
            coordinator.acknowledgeNewIncidentRequest()
        }
        .onChange(of: coordinator.dismissAllPresented) { _, shouldDismiss in
            guard shouldDismiss else { return }
            incidentComposerPresented = false
            coordinator.acknowledgeDismissAllPresented()
        }
    }

    private var standardWorkspace: some View {
        HStack(spacing: 0) {
            contentColumn
                .frame(maxWidth: .infinity, maxHeight: .infinity)

            if let trailingPanelWidth {
                Divider()
                trailingPanel
                    .frame(width: trailingPanelWidth)
                    .frame(maxHeight: .infinity)
                    .clipped()
            }
        }
    }

    private var childrenWorkspace: some View {
        VStack(spacing: 0) {
            if let selectedSummary {
                ChildJournalSegmentBar(
                    selection: $coordinator.journalContentSegment,
                    childDisplayName: selectedSummary.fullName,
                    syncStatusLabel: coordinator.journalContentSegment == .charts
                        ? nil
                        : journalSyncStatusLabel,
                    showsSidebarToggle: isChildrenSidebarHidden,
                    onShowSidebar: showChildrenSidebar,
                    isProfilePanelCollapsed: isProfilePanelCollapsed,
                    onToggleProfile: toggleProfilePanel
                )
            } else if isChildrenSidebarHidden {
                childrenEmptyChromeBar
            }

            HStack(spacing: 0) {
                ChildJournalView(
                    summary: selectedSummary,
                    managedObjectContext: context,
                    dashboardViewModel: dashboardViewModel,
                    usesExternalSegmentBar: true,
                    selectedSummary: $selectedSummary,
                    segmentBarSyncStatus: $journalSyncStatusLabel
                )
                .id(selectedSummary?.id)
                .frame(maxWidth: .infinity, maxHeight: .infinity)

                if let selectedSummary, !isProfilePanelCollapsed {
                    childProfilePanel(for: selectedSummary)
                        .transition(.move(edge: .trailing).combined(with: .opacity))
                }
            }
        }
        .animation(.easeInOut(duration: 0.25), value: isProfilePanelCollapsed)
        .environment(\.keyworkerChildWorkspace, true)
        .onChange(of: selectedSummary?.id) { _, _ in
            isProfilePanelCollapsed = false
        }
    }

    private func childProfilePanel(for summary: KeyworkerChildSummary) -> some View {
        VStack(spacing: 0) {
            NCPanelHeader(title: "Profile")
            ChildProfileView(childId: summary.id, context: context, embedsInPanel: true)
        }
        .frame(width: KeyworkerIPadTrailingPanel.profileWidth)
        .frame(maxHeight: .infinity)
        .overlay(alignment: .leading) {
            Divider()
        }
        .id(summary.id)
    }

    private func toggleProfilePanel() {
        withAnimation(.easeInOut(duration: 0.25)) {
            isProfilePanelCollapsed.toggle()
        }
    }

    private var isChildrenSidebarHidden: Bool {
        splitColumnVisibility == .detailOnly
    }

    private func showChildrenSidebar() {
        withAnimation(.easeInOut(duration: 0.25)) {
            splitColumnVisibility = .all
        }
    }

    private var childrenEmptyChromeBar: some View {
        HStack(spacing: 0) {
            Button(action: showChildrenSidebar) {
                Image(systemName: "sidebar.leading")
                    .font(.body.weight(.semibold))
                    .foregroundStyle(Color.ncPrimary)
                    .frame(width: 44, height: 44)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Show children list")
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 16)
        .padding(.top, 12)
        .padding(.bottom, 4)
    }

    private func selectSection(_ newSection: KeyworkerIPadSection) {
        if coordinator.section == newSection {
            switch newSection {
            case .incidents:
                coordinator.requestIncidentsNavigationReset()
            case .messages:
                selectedMessageThreadID = nil
            case .children:
                break
            }
        }
        withAnimation(.easeInOut(duration: 0.22)) {
            coordinator.section = newSection
        }
    }

    private func resetIncidentsNavigation() {
        incidentsNavigationResetID = UUID()
    }

    @ViewBuilder
    private var contentColumn: some View {
        switch coordinator.section {
        case .children:
            EmptyView()
        case .incidents:
            NavigationStack {
                IncidentListView(
                    managedObjectContext: context,
                    composerPresented: $incidentComposerPresented
                )
                .keyworkerSidebarRevealToolbar()
            }
            .id(incidentsNavigationResetID)
        case .messages:
            NavigationStack {
                MessagingView(
                    managedObjectContext: context,
                    selectedThreadID: $selectedMessageThreadID,
                    presentationStyle: .splitViewEmbedded
                )
                .keyworkerSidebarRevealToolbar()
            }
        }
    }

    private var trailingPanelWidth: CGFloat? {
        switch coordinator.section {
        case .messages:
            return selectedMessageThreadID == nil
                ? nil
                : KeyworkerIPadTrailingPanel.messageThreadWidth
        case .children:
            return nil
        case .incidents:
            return nil
        }
    }

    @ViewBuilder
    private var trailingPanel: some View {
        if coordinator.section == .messages, let threadID = selectedMessageThreadID {
            ThreadDetailView(threadID: threadID, managedObjectContext: context)
                .id(threadID)
        } else {
            ContentUnavailableView {
                Label("No detail", systemImage: "sidebar.right")
            } description: {
                Text(
                    coordinator.section == .messages
                        ? "Select a conversation to read messages."
                        : "Select a child to view their profile and analytics."
                )
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .ncStudioScreenBackdrop()
        }
    }
}
