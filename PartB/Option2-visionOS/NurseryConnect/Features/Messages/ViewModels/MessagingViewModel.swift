//
//  MessagingViewModel.swift
//  NurseryConnect
//
//  Feature: Messages
//  Role: Keyworker
//  Created: 29 May 2026
//  Description: Secure messaging inbox grouping, replies, archive, and GDPR-scoped fetches.
//

import Combine
import CoreData
import Foundation

/// - Description: Manages secure messaging state for the keyworker inbox and thread detail.
@MainActor
final class MessagingViewModel: ObservableObject {
    @Published private(set) var groupedSections: [MessageInboxSectionGroup] = []
    @Published private(set) var unreadCount = 0
    @Published var errorMessage: String?

    private let context: NSManagedObjectContext
    private var assignedChildIDs: [UUID] = []
    private var childNameByID: [UUID: (name: String, initial: String)] = [:]

    init(context: NSManagedObjectContext) {
        self.context = context
    }

    /// - Description: Reloads inbox sections and unread badge count from Core Data.
    func refresh() async {
        context.processPendingChanges()
        do {
            assignedChildIDs = try MessagingGDPRScope.assignedChildIDs(in: context)
            try loadChildDisplayNames()
            unreadCount = try fetchUnreadCount()
            groupedSections = try buildGroupedSections()
        } catch {
            errorMessage = "Could not load messages. Please try again."
            groupedSections = []
            unreadCount = 0
        }
    }

    /// - Description: Archives a thread (swipe action).
    func archiveThread(threadID: UUID) {
        do {
            guard let thread = try fetchThread(id: threadID) else { return }
            thread.isArchived = true
            try context.save()
            Task { await refresh() }
        } catch {
            errorMessage = "Could not archive this conversation."
        }
    }

    /// - Description: Whether the keyworker may reply in this thread.
    func canReply(to thread: MessageThread) -> Bool {
        let role = MessageInitiatorRole.fromPersistence(thread.initiatorRole ?? "")
        return role.allowsKeyworkerReply
    }

    /// - Description: Marks inbound unread messages in a thread as read when opened.
    func markThreadAsRead(threadID: UUID) {
        do {
            let request: NSFetchRequest<Message> = Message.fetchRequest()
            request.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [
                NSPredicate(format: "threadID == %@", threadID as CVarArg),
                NSPredicate(format: "isRead == NO"),
                NSPredicate(format: "senderRole != %@", MessageSenderRole.keyworker.persistenceValue)
            ])
            let unread = try context.fetch(request)
            guard !unread.isEmpty else { return }
            for message in unread {
                message.isRead = true
            }
            try context.save()
            Task { await refresh() }
        } catch {
            errorMessage = "Could not update read status."
        }
    }

    /// - Description: Sends a keyworker reply when the thread allows replies.
    func sendReply(threadID: UUID, body: String) throws {
        try ensureCohortLoaded()
        let trimmed = body.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        guard trimmed.count <= AppConstants.messageBodyMaxLength else { return }
        guard let thread = try fetchThread(id: threadID), canReply(to: thread) else {
            throw MessagingError.replyNotPermitted
        }

        let message = Message(context: context)
        message.id = UUID()
        message.threadID = threadID
        message.senderRole = MessageSenderRole.keyworker.persistenceValue
        message.senderDisplayName = AppConstants.keyworkerDisplayName
        message.body = trimmed
        message.sentAt = Date()
        message.isRead = true
        message.messageType = MessageType.message.persistenceValue
        try context.save()
    }

    /// - Description: Sends an end-of-day summary into the child's parent thread (or creates one).
    func sendEndOfDaySummary(childID: UUID, body: String) throws {
        try ensureCohortLoaded()
        let trimmed = body.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        guard assignedChildIDs.contains(childID) else {
            throw MessagingError.childNotInCohort
        }
        guard !EndOfDaySummaryAvailability.hasSentToday(childID: childID, in: context) else {
            throw MessagingError.summaryAlreadySentToday
        }

        let thread = try findOrCreateParentThread(childID: childID)
        let message = Message(context: context)
        message.id = UUID()
        message.threadID = thread.id
        message.senderRole = MessageSenderRole.keyworker.persistenceValue
        message.senderDisplayName = AppConstants.keyworkerDisplayName
        message.body = trimmed
        message.sentAt = Date()
        message.isRead = true
        message.messageType = MessageType.endOfDaySummary.persistenceValue
        try context.save()
    }

    /// - Description: Resolves display metadata for a thread row.
    func displayInfo(for thread: MessageThread) -> (childName: String, initial: String) {
        guard let childID = thread.childID, let info = childNameByID[childID] else {
            return ("Child", "?")
        }
        return (childName: info.name, initial: info.initial)
    }

    // MARK: - Private

    private func loadChildDisplayNames() throws {
        let request: NSFetchRequest<Child> = Child.fetchRequest()
        request.predicate = NSPredicate(format: "id IN %@", assignedChildIDs)
        let children = try context.fetch(request)
        var map: [UUID: (name: String, initial: String)] = [:]
        for child in children {
            guard let id = child.id else { continue }
            let display = child.fullDisplayName
            let initial = PersonNameFormatting.givenNameInitial(first: child.firstName)
            map[id] = (display, initial)
        }
        childNameByID = map
    }

    private func fetchUnreadCount() throws -> Int {
        try MessagingGDPRScope.unreadInboundCount(childIDs: assignedChildIDs, in: context)
    }

    private func buildGroupedSections() throws -> [MessageInboxSectionGroup] {
        let request: NSFetchRequest<MessageThread> = MessageThread.fetchRequest()
        request.predicate = MessagingGDPRScope.threadPredicate(childIDs: assignedChildIDs)
        request.sortDescriptors = [NSSortDescriptor(keyPath: \MessageThread.createdAt, ascending: false)]
        let threads = try context.fetch(request)
        let previews = try latestMessagesByThreadID()

        var unreadRows: [MessageThreadRow] = []
        var todayRows: [MessageThreadRow] = []
        var earlierRows: [MessageThreadRow] = []
        let now = Date()

        for thread in threads {
            guard let threadID = thread.id, let childID = thread.childID else { continue }
            let preview = previews[threadID]
            let lastAt = preview?.sentAt ?? thread.createdAt ?? .distantPast
            let hasUnread = preview?.hasUnread ?? false
            let info = childNameByID[childID] ?? ("Child", "?")
            let role = MessageInitiatorRole.fromPersistence(thread.initiatorRole ?? "")
            let row = MessageThreadRow(
                id: threadID,
                threadID: threadID,
                childID: childID,
                childDisplayName: info.name,
                childInitial: info.initial,
                subject: thread.subject ?? "Conversation",
                lastMessagePreview: preview?.body ?? "",
                lastMessageAt: lastAt,
                hasUnread: hasUnread,
                isBroadcast: role == .broadcast,
                initiatorRole: role
            )
            if hasUnread {
                unreadRows.append(row)
            } else if lastAt.isSameDay(as: now) {
                todayRows.append(row)
            } else {
                earlierRows.append(row)
            }
        }

        let sort: (MessageThreadRow, MessageThreadRow) -> Bool = { $0.lastMessageAt > $1.lastMessageAt }
        unreadRows.sort(by: sort)
        todayRows.sort(by: sort)
        earlierRows.sort(by: sort)

        var groups: [MessageInboxSectionGroup] = []
        if !unreadRows.isEmpty {
            groups.append(MessageInboxSectionGroup(section: .unread, rows: unreadRows))
        }
        if !todayRows.isEmpty {
            groups.append(MessageInboxSectionGroup(section: .today, rows: todayRows))
        }
        if !earlierRows.isEmpty {
            groups.append(MessageInboxSectionGroup(section: .earlier, rows: earlierRows))
        }
        return groups
    }

    private struct ThreadPreview {
        let body: String
        let sentAt: Date
        let hasUnread: Bool
    }

    private func latestMessagesByThreadID() throws -> [UUID: ThreadPreview] {
        let request: NSFetchRequest<Message> = Message.fetchRequest()
        let threadIDs = try MessagingGDPRScope.assignedThreadIDs(childIDs: assignedChildIDs, in: context)
        if threadIDs.isEmpty {
            return [:]
        }
        request.predicate = NSPredicate(format: "threadID IN %@", threadIDs)
        request.sortDescriptors = [NSSortDescriptor(keyPath: \Message.sentAt, ascending: false)]
        let messages = try context.fetch(request)

        var map: [UUID: ThreadPreview] = [:]
        var unreadByThread: [UUID: Bool] = [:]

        for message in messages {
            guard let threadID = message.threadID else { continue }
            if map[threadID] == nil {
                map[threadID] = ThreadPreview(
                    body: message.body ?? "",
                    sentAt: message.sentAt ?? .distantPast,
                    hasUnread: false
                )
            }
            if message.isRead == false,
               MessageSenderRole.fromPersistence(message.senderRole ?? "") != .keyworker {
                unreadByThread[threadID] = true
            }
        }

        for (threadID, _) in map {
            if unreadByThread[threadID] == true, var preview = map[threadID] {
                preview = ThreadPreview(body: preview.body, sentAt: preview.sentAt, hasUnread: true)
                map[threadID] = preview
            }
        }
        return map
    }

    private func ensureCohortLoaded() throws {
        if assignedChildIDs.isEmpty {
            assignedChildIDs = try MessagingGDPRScope.assignedChildIDs(in: context)
        }
    }

    private func fetchThread(id: UUID) throws -> MessageThread? {
        try ensureCohortLoaded()
        let request: NSFetchRequest<MessageThread> = MessageThread.fetchRequest()
        request.fetchLimit = 1
        request.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [
            NSPredicate(format: "id == %@", id as CVarArg),
            NSPredicate(format: "childID IN %@", assignedChildIDs)
        ])
        return try context.fetch(request).first
    }

    private func findOrCreateParentThread(childID: UUID) throws -> MessageThread {
        let request: NSFetchRequest<MessageThread> = MessageThread.fetchRequest()
        request.fetchLimit = 1
        request.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [
            NSPredicate(format: "childID == %@", childID as CVarArg),
            NSPredicate(format: "initiatorRole == %@", MessageInitiatorRole.parent.persistenceValue),
            NSPredicate(format: "isArchived == NO")
        ])
        request.sortDescriptors = [NSSortDescriptor(keyPath: \MessageThread.createdAt, ascending: false)]
        if let existing = try context.fetch(request).first, existing.id != nil {
            return existing
        }

        let thread = MessageThread(context: context)
        thread.id = UUID()
        thread.childID = childID
        thread.initiatorRole = MessageInitiatorRole.parent.persistenceValue
        thread.subject = "End of day updates"
        thread.createdAt = Date()
        thread.isArchived = false
        return thread
    }
}

/// - Description: Messaging-specific errors surfaced to the UI.
enum MessagingError: LocalizedError {
    case replyNotPermitted
    case childNotInCohort
    case summaryAlreadySentToday

    var errorDescription: String? {
        switch self {
        case .replyNotPermitted:
            return "You can only reply to conversations started by a parent or the Setting Manager."
        case .childNotInCohort:
            return "This child is not in your assigned group."
        case .summaryAlreadySentToday:
            return "An end-of-day summary has already been sent for this child today."
        }
    }
}

/// - Description: End-of-day summary button visibility rules.
enum EndOfDaySummaryAvailability {
    static func isAfterThreePM(at date: Date = Date()) -> Bool {
        Calendar.current.component(.hour, from: date) >= AppConstants.endOfDaySummaryEarliestHour
    }

    static func hasSentToday(childID: UUID, in context: NSManagedObjectContext) -> Bool {
        let start = Date().startOfDay
        let threadRequest: NSFetchRequest<MessageThread> = MessageThread.fetchRequest()
        threadRequest.predicate = NSPredicate(format: "childID == %@", childID as CVarArg)
        guard let threadIDs = try? context.fetch(threadRequest).compactMap(\.id), !threadIDs.isEmpty else {
            return false
        }
        let request: NSFetchRequest<Message> = Message.fetchRequest()
        request.fetchLimit = 1
        request.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [
            NSPredicate(format: "messageType == %@", MessageType.endOfDaySummary.persistenceValue),
            NSPredicate(format: "sentAt >= %@", start as NSDate),
            NSPredicate(format: "threadID IN %@", threadIDs)
        ])
        return (try? context.count(for: request)) ?? 0 > 0
    }

    static func shouldShowButton(childID: UUID, in context: NSManagedObjectContext, at date: Date = Date()) -> Bool {
        isAfterThreePM(at: date) && !hasSentToday(childID: childID, in: context)
    }
}
