//
//  ThreadDetailView.swift
//  NurseryConnect
//
//  Feature: Messages
//  Role: Keyworker
//  Created: 29 May 2026
//  Description: Thread detail with chat bubbles and reply bar.
//

import CoreData
import SwiftUI

/// - Description: Conversation detail for one secure message thread.
struct ThreadDetailView: View {
    let threadID: UUID

    @Environment(\.managedObjectContext) private var context
    @StateObject private var viewModel: MessagingViewModel
    @FetchRequest private var messages: FetchedResults<Message>

    @State private var draftText = ""
    @State private var thread: MessageThread?

    init(threadID: UUID, managedObjectContext: NSManagedObjectContext) {
        self.threadID = threadID
        _viewModel = StateObject(wrappedValue: MessagingViewModel(context: managedObjectContext))
        _messages = FetchRequest(
            sortDescriptors: [NSSortDescriptor(keyPath: \Message.sentAt, ascending: true)],
            predicate: NSPredicate(format: "threadID == %@", threadID as CVarArg),
            animation: .default
        )
    }

    private var initiatorRole: MessageInitiatorRole {
        MessageInitiatorRole.fromPersistence(thread?.initiatorRole ?? "")
    }

    private var isBroadcast: Bool {
        initiatorRole == .broadcast
    }

    private var canReply: Bool {
        guard let thread else { return false }
        return viewModel.canReply(to: thread)
    }

    var body: some View {
        VStack(spacing: 0) {
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(messages) { message in
                            messageView(for: message)
                                .id(message.id)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                }
                .onChange(of: messages.count) { _, _ in
                    scrollToBottom(proxy: proxy)
                }
                .onAppear {
                    scrollToBottom(proxy: proxy)
                }
            }

            if !isBroadcast {
                MessageReplyBar(
                    canReply: canReply,
                    disabledNotice: AppConstants.messagingRepliesOnlyNotice,
                    draftText: $draftText,
                    onSend: sendReply
                )
            }
        }
        .ncStudioScreenBackdrop()
        .navigationTitle(threadTitle)
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await loadThread()
            viewModel.markThreadAsRead(threadID: threadID)
        }
        .alert("Something went wrong", isPresented: errorPresented) {
            Button("OK", role: .cancel) { viewModel.errorMessage = nil }
        } message: {
            Text(viewModel.errorMessage ?? "")
        }
    }

    private var threadTitle: String {
        if isBroadcast { return "Broadcast" }
        guard let thread, let childID = thread.childID else { return "Messages" }
        let info = viewModel.displayInfo(for: thread)
        return info.childName
    }

    private var errorPresented: Binding<Bool> {
        Binding(
            get: { viewModel.errorMessage != nil },
            set: { if !$0 { viewModel.errorMessage = nil } }
        )
    }

    @ViewBuilder
    private func messageView(for message: Message) -> some View {
        let type = MessageType.fromPersistence(message.messageType ?? "")
        if type.usesInfoCardLayout {
            BroadcastMessageCard(message: message)
        } else {
            MessageBubbleView(message: message)
        }
    }

    private func loadThread() async {
        let request: NSFetchRequest<MessageThread> = MessageThread.fetchRequest()
        request.fetchLimit = 1
        request.predicate = NSPredicate(format: "id == %@", threadID as CVarArg)
        thread = try? context.fetch(request).first
    }

    private func sendReply() {
        do {
            try viewModel.sendReply(threadID: threadID, body: draftText)
            draftText = ""
        } catch {
            viewModel.errorMessage = error.localizedDescription
        }
    }

    private func scrollToBottom(proxy: ScrollViewProxy) {
        guard let last = messages.last?.id else { return }
        DispatchQueue.main.async {
            proxy.scrollTo(last, anchor: .bottom)
        }
    }
}
