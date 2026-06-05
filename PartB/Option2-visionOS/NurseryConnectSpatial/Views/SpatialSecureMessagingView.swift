//
//  SpatialSecureMessagingView.swift
//  NurseryConnect Spatial
//
//  Feature: Spatial
//  Created: 4 June 2026
//  Description: Encrypted in-app messaging with thread list, message bubbles, and compose bar.
//

import SwiftUI

struct SpatialSecureMessagingView: View {
    @Environment(\.dismissWindow) private var dismissWindow
    @EnvironmentObject private var dataStore: SpatialDataStore

    @State private var threads: [NCMessageThread] = []
    @State private var selectedThreadID: UUID?
    @State private var searchText = ""

    private var selectedThread: Binding<NCMessageThread>? {
        guard let id = selectedThreadID,
              let idx = threads.firstIndex(where: { $0.id == id }) else { return nil }
        return $threads[idx]
    }

    var body: some View {
        NavigationSplitView {
            sidebar
        } detail: {
            if let thread = selectedThread {
                MessageThreadDetailView(thread: thread)
            } else {
                ContentUnavailableView("Select a conversation", systemImage: "bubble.left.and.bubble.right")
            }
        }
        .task { threads = dataStore.threads }
        .searchable(text: $searchText, placement: .sidebar, prompt: "Search messages")
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Done") { dismissWindow(id: SpatialWindowID.messaging) }
            }
        }
    }

    // MARK: - Sidebar

    private var sidebar: some View {
        List(filteredThreads, id: \.id) { thread in
            Button {
                selectedThreadID = thread.id
            } label: {
                ThreadRowView(thread: thread)
            }
            .buttonStyle(.plain)
            .listRowBackground(
                selectedThreadID == thread.id
                    ? Color.accentColor.opacity(0.15)
                    : Color.clear
            )
        }
        .navigationTitle("Messages")
        .safeAreaInset(edge: .bottom) {
            Text(AppConstants.messagesRetentionFooter)
                .font(.ncCaption2)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(10)
        }
    }

    private var filteredThreads: [NCMessageThread] {
        if searchText.isEmpty { return threads }
        return threads.filter {
            $0.participantName.localizedCaseInsensitiveContains(searchText)
            || ($0.childName ?? "").localizedCaseInsensitiveContains(searchText)
        }
    }
}

// MARK: - Thread row

private struct ThreadRowView: View {
    let thread: NCMessageThread

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(roleColor.opacity(0.2))
                    .frame(width: 44, height: 44)
                Text(thread.participantName.prefix(2).uppercased())
                    .font(.system(.caption, design: .rounded, weight: .bold))
                    .foregroundStyle(roleColor)
            }
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(thread.participantName).font(.ncCaption.weight(.semibold))
                    Spacer()
                    if let last = thread.lastMessage {
                        Text(last.timestamp, style: .relative)
                            .font(.ncCaption2)
                            .foregroundStyle(.tertiary)
                    }
                }
                HStack {
                    Text(thread.lastMessage?.body ?? "")
                        .font(.ncCaption2)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                    Spacer()
                    if thread.unreadCount > 0 {
                        Text("\(thread.unreadCount)")
                            .font(.ncCaption2.weight(.bold))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.ncDanger, in: Capsule())
                    }
                }
                roleBadge
            }
        }
        .padding(.vertical, 4)
    }

    private var roleBadge: some View {
        Text(thread.participantRole.rawValue)
            .font(.ncCaption2.weight(.semibold))
            .foregroundStyle(roleColor)
            .padding(.horizontal, 8)
            .padding(.vertical, 2)
            .background(roleColor.opacity(0.14), in: Capsule())
    }

    private var roleColor: Color {
        switch thread.participantRole {
        case .parent:         return Color.ncPrimary
        case .settingManager: return Color.ncAccentWarm
        case .keyworker:      return Color.ncSecondary
        }
    }
}

// MARK: - Thread detail

private struct MessageThreadDetailView: View {
    @Binding var thread: NCMessageThread
    @State private var draft = ""
    @State private var showsIncidentAttach = false

    var body: some View {
        VStack(spacing: 0) {
            threadHeader
            Divider()
            messagesScrollView
            Divider()
            composeBar
            Text("All messages are encrypted and retained for 3 years per EYFS safeguarding requirements.")
                .font(.ncCaption2)
                .foregroundStyle(.tertiary)
                .padding(.horizontal, 16)
                .padding(.bottom, 8)
        }
        .navigationTitle(thread.participantName)
        .alert("Incident report attached", isPresented: $showsIncidentAttach) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("Reference card added to your message draft.")
        }
    }

    private var threadHeader: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text(thread.participantName).font(.ncHeadline)
                if let child = thread.childName {
                    Text("Re: \(child)").font(.ncCaption).foregroundStyle(.secondary)
                }
            }
            Spacer()
            Text(thread.participantRole.rawValue)
                .font(.ncCaption.weight(.semibold))
                .foregroundStyle(Color.ncPrimary)
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(Color.ncPrimary.opacity(0.12), in: Capsule())
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }

    private var messagesScrollView: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 10) {
                    ForEach(thread.messages) { msg in
                        messageBubble(msg)
                            .id(msg.id)
                    }
                }
                .padding(16)
            }
            .onChange(of: thread.messages.count) { _, _ in
                if let last = thread.messages.last {
                    withAnimation { proxy.scrollTo(last.id, anchor: .bottom) }
                }
            }
        }
    }

    private func messageBubble(_ msg: NCMessage) -> some View {
        let isKeyworker = msg.role == .keyworker
        return HStack {
            if isKeyworker { Spacer(minLength: 60) }
            VStack(alignment: isKeyworker ? .trailing : .leading, spacing: 4) {
                Text(msg.body)
                    .font(.ncBody)
                    .foregroundStyle(isKeyworker ? .white : .primary)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(
                        isKeyworker
                            ? Color.ncPrimary
                            : Color(.systemFill),
                        in: RoundedRectangle(cornerRadius: 18, style: .continuous)
                    )
                Text(msg.timestamp, style: .time)
                    .font(.ncCaption2)
                    .foregroundStyle(.tertiary)
            }
            if !isKeyworker { Spacer(minLength: 60) }
        }
        .frame(maxWidth: .infinity, alignment: isKeyworker ? .trailing : .leading)
    }

    private var composeBar: some View {
        HStack(spacing: 10) {
            Button {
                draft += " [Incident report ref: \(Date().formatted(date: .abbreviated, time: .shortened))]"
                showsIncidentAttach = true
            } label: {
                Image(systemName: "paperclip.circle.fill")
                    .font(.title2)
                    .foregroundStyle(Color.ncPrimary)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Attach incident report")

            TextField("Message…", text: $draft, axis: .vertical)
                .font(.ncBody)
                .lineLimit(1...4)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color(.secondarySystemFill), in: RoundedRectangle(cornerRadius: 18, style: .continuous))

            Button {
                sendMessage()
            } label: {
                Image(systemName: "paperplane.fill")
                    .font(.title3)
                    .foregroundStyle(draft.isEmpty ? Color.secondary : Color.ncPrimary)
            }
            .buttonStyle(.plain)
            .disabled(draft.isEmpty)
            .accessibilityLabel("Send message")
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
    }

    private func sendMessage() {
        guard !draft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        let msg = NCMessage(
            id: UUID(), senderName: AppConstants.keyworkerDisplayName,
            role: .keyworker, body: draft, timestamp: Date(), isRead: true,
            childName: thread.childName
        )
        thread.messages.append(msg)
        draft = ""
    }
}
