//
//  MessagingView.swift
//  NurseryConnect
//
//  Feature: Messages
//  Role: Keyworker
//  Created: 29 May 2026
//  Description: Secure messaging inbox grouped by unread, today, and earlier.
//

import CoreData
import SwiftUI

/// - Description: Controls inbox vs pushed thread detail when embedded in the iPad split view.
enum MessagingPresentationStyle {
    case phoneNavigation
    case splitViewEmbedded
}

/// - Description: Inbox list for secure parent and manager messaging.
struct MessagingView: View {
    @Environment(\.managedObjectContext) private var context
    @Environment(\.usesFloatingTabBarShell) private var usesFloatingTabBarShell

    @StateObject private var viewModel: MessagingViewModel
    @FetchRequest private var activeThreads: FetchedResults<MessageThread>

    /// - Description: iPad split selection; iPhone uses navigation push separately.
    @Binding var selectedThreadID: UUID?
    private let presentationStyle: MessagingPresentationStyle

    init(
        managedObjectContext: NSManagedObjectContext,
        selectedThreadID: Binding<UUID?> = .constant(nil),
        presentationStyle: MessagingPresentationStyle = .phoneNavigation
    ) {
        _viewModel = StateObject(wrappedValue: MessagingViewModel(context: managedObjectContext))
        _selectedThreadID = selectedThreadID
        self.presentationStyle = presentationStyle
        _activeThreads = FetchRequest(
            sortDescriptors: [NSSortDescriptor(keyPath: \MessageThread.createdAt, ascending: false)],
            predicate: NSPredicate(format: "isArchived == NO"),
            animation: .default
        )
    }

    var body: some View {
        Group {
            if isSplitViewEmbedded {
                inboxList
            } else {
                NavigationStack {
                    inboxList
                        .navigationDestination(for: UUID.self) { threadID in
                            ThreadDetailView(threadID: threadID, managedObjectContext: context)
                        }
                }
            }
        }
        .navigationTitle(AppConstants.navTitleKeyworkerMessagesList)
        .navigationBarTitleDisplayMode(.large)
        .task { await viewModel.refresh() }
        .onChange(of: activeThreads.count) { _, _ in
            Task { await viewModel.refresh() }
        }
        .onReceive(NotificationCenter.default.publisher(for: .NSManagedObjectContextObjectsDidChange, object: context)) { _ in
            Task { await viewModel.refresh() }
        }
        .alert("Something went wrong", isPresented: errorPresented) {
            Button("OK", role: .cancel) { viewModel.errorMessage = nil }
        } message: {
            Text(viewModel.errorMessage ?? "")
        }
    }

    private var isSplitViewEmbedded: Bool {
        presentationStyle == .splitViewEmbedded
    }

    private var errorPresented: Binding<Bool> {
        Binding(
            get: { viewModel.errorMessage != nil },
            set: { if !$0 { viewModel.errorMessage = nil } }
        )
    }

    private var inboxList: some View {
        List {
            messageActivitySection
            inboxSections
            retentionFooterSection
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .ncStudioScreenBackdrop()
        .onAppear { selectInitialThreadIfNeeded() }
        .onChange(of: viewModel.groupedSections.count) { _, _ in selectInitialThreadIfNeeded() }
        .safeAreaInset(edge: .bottom) {
            if usesFloatingTabBarShell {
                Color.clear.frame(height: AppConstants.floatingTabBarClearance)
            }
        }
    }

    private var messageActivitySection: some View {
        Section {
            VStack(alignment: .leading, spacing: 8) {
                Text("Parent engagement (7 days)")
                    .font(AppTheme.titleRounded())
                MessageActivityChart()
                Text("Shows parent messages received per day. A sudden drop may indicate reduced engagement and warrant a welfare check-in.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .ncStudioElevatedSurface(cornerRadius: AppConstants.cardCornerRadius)
            .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
            .listRowBackground(Color.clear)
            .listRowSeparator(.hidden)
        }
    }

    @ViewBuilder
    private var inboxSections: some View {
        if viewModel.groupedSections.isEmpty {
            ContentUnavailableView {
                Label("No messages", systemImage: "bubble.left.and.bubble.right")
            } description: {
                Text("Conversations started by parents or your Setting Manager appear here.")
            }
        } else {
            ForEach(viewModel.groupedSections) { group in
                Section {
                    ForEach(group.rows) { row in
                        threadRow(for: row)
                    }
                } header: {
                    sectionHeader(for: group)
                }
            }
        }
    }

    private var retentionFooterSection: some View {
        Section {
            Text(AppConstants.messagesRetentionFooter)
                .font(.caption2)
                .foregroundStyle(.tertiary)
                .frame(maxWidth: .infinity, alignment: .center)
                .listRowBackground(Color.clear)
        }
    }

    @ViewBuilder
    private func threadRow(for row: MessageThreadRow) -> some View {
        if isSplitViewEmbedded {
            ipadThreadRow(for: row)
        } else {
            phoneThreadRow(for: row)
        }
    }

    private func ipadThreadRow(for row: MessageThreadRow) -> some View {
        Button {
            selectedThreadID = row.threadID
        } label: {
            MessageThreadRowView(row: row)
        }
        .buttonStyle(.plain)
        .listRowBackground(
            selectedThreadID == row.threadID
                ? Color.accentColor.opacity(0.18)
                : nil
        )
        .swipeActions(edge: .trailing) {
            Button("Archive") {
                viewModel.archiveThread(threadID: row.threadID)
            }
            .tint(.orange)
        }
    }

    private func phoneThreadRow(for row: MessageThreadRow) -> some View {
        NavigationLink(value: row.threadID) {
            MessageThreadRowView(row: row)
        }
        .swipeActions(edge: .trailing) {
            Button("Archive") {
                viewModel.archiveThread(threadID: row.threadID)
            }
            .tint(.orange)
        }
    }

    private func selectInitialThreadIfNeeded() {
        guard isSplitViewEmbedded else { return }
        let allIDs = Set(viewModel.groupedSections.flatMap(\.rows).map(\.threadID))
        if let current = selectedThreadID, allIDs.contains(current) { return }
        selectedThreadID = viewModel.groupedSections.first?.rows.first?.threadID
    }

    @ViewBuilder
    private func sectionHeader(for group: MessageInboxSectionGroup) -> some View {
        HStack {
            Text(group.section.rawValue)
                .ncSectionOverlineStyle()
            if group.section == .unread, group.unreadCount > 0 {
                Spacer()
                Text("\(group.unreadCount)")
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color.red, in: Capsule())
            }
        }
    }
}
