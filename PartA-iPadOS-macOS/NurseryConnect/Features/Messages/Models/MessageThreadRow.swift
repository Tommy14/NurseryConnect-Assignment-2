//
//  MessageThreadRow.swift
//  NurseryConnect
//
//  Feature: Messages
//  Role: Keyworker
//  Created: 29 May 2026
//  Description: Presentation model for one row in the secure messaging inbox.
//

import Foundation

/// - Description: Inbox row derived from a MessageThread and its latest message.
struct MessageThreadRow: Identifiable, Hashable {
    let id: UUID
    let threadID: UUID
    let childID: UUID
    let childDisplayName: String
    let childInitial: String
    let subject: String
    let lastMessagePreview: String
    let lastMessageAt: Date
    let hasUnread: Bool
    let isBroadcast: Bool
    let initiatorRole: MessageInitiatorRole
}

/// - Description: Grouping bucket for the messaging inbox list.
enum MessageInboxSection: String, CaseIterable, Identifiable {
    case unread = "UNREAD"
    case today = "TODAY"
    case earlier = "EARLIER"

    var id: String { rawValue }
}

/// - Description: One inbox section with its thread rows.
struct MessageInboxSectionGroup: Identifiable {
    let section: MessageInboxSection
    let rows: [MessageThreadRow]

    var id: String { section.rawValue }

    var unreadCount: Int {
        rows.filter(\.hasUnread).count
    }
}
