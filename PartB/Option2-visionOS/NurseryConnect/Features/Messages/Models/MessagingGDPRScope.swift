//
//  MessagingGDPRScope.swift
//  NurseryConnect
//
//  Feature: Messages
//  Role: Keyworker
//  Created: 29 May 2026
//  Description: GDPR cohort scoping for secure messaging fetches.
//

import CoreData
import Foundation

/// - Description: Resolves which child IDs the logged-in keyworker may access in messaging.
enum MessagingGDPRScope {
    /// - Description: Fetches UUIDs for children assigned to the demo keyworker account.
    /// - Parameters:
    ///   - context: Core Data context.
    /// - Returns: Child identifiers for predicate filtering.
    static func assignedChildIDs(in context: NSManagedObjectContext) throws -> [UUID] {
        let request: NSFetchRequest<Child> = Child.fetchRequest()
        request.predicate = NSPredicate(format: "keyworkerName == %@", AppConstants.keyworkerDisplayName)
        request.propertiesToFetch = ["id"]
        let children = try context.fetch(request)
        return children.compactMap(\.id)
    }

    /// - Description: Fetches active thread IDs for the assigned child cohort (SQL-safe; no SUBQUERY).
    static func assignedThreadIDs(childIDs: [UUID], in context: NSManagedObjectContext) throws -> [UUID] {
        guard !childIDs.isEmpty else { return [] }
        let request: NSFetchRequest<MessageThread> = MessageThread.fetchRequest()
        request.predicate = threadPredicate(childIDs: childIDs)
        request.propertiesToFetch = ["id"]
        return try context.fetch(request).compactMap(\.id)
    }

    /// - Description: Predicate limiting threads to the keyworker's assigned cohort.
    static func threadPredicate(childIDs: [UUID]) -> NSPredicate {
        guard !childIDs.isEmpty else {
            return NSPredicate(value: false)
        }
        return NSCompoundPredicate(andPredicateWithSubpredicates: [
            NSPredicate(format: "isArchived == NO"),
            NSPredicate(format: "childID IN %@", childIDs)
        ])
    }

    /// - Description: Predicate for unread inbound messages within known thread IDs.
    static func unreadInboundPredicate(threadIDs: [UUID]) -> NSPredicate {
        guard !threadIDs.isEmpty else {
            return NSPredicate(value: false)
        }
        return NSCompoundPredicate(andPredicateWithSubpredicates: [
            NSPredicate(format: "isRead == NO"),
            NSPredicate(format: "senderRole != %@", MessageSenderRole.keyworker.persistenceValue),
            NSPredicate(format: "threadID IN %@", threadIDs)
        ])
    }

    /// - Description: Counts unread inbound messages for the keyworker cohort using two simple fetches.
    static func unreadInboundCount(childIDs: [UUID], in context: NSManagedObjectContext) throws -> Int {
        let threadIDs = try assignedThreadIDs(childIDs: childIDs, in: context)
        guard !threadIDs.isEmpty else { return 0 }
        let request: NSFetchRequest<Message> = Message.fetchRequest()
        request.predicate = unreadInboundPredicate(threadIDs: threadIDs)
        return try context.count(for: request)
    }
}
