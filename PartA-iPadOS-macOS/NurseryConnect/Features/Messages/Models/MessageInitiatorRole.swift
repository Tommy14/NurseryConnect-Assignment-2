//
//  MessageInitiatorRole.swift
//  NurseryConnect
//
//  Feature: Messages
//  Role: Keyworker
//  Created: 29 May 2026
//  Description: Thread initiator roles persisted on MessageThread.initiatorRole.
//

import Foundation

/// - Description: Who started a secure message thread (`MessageThread.initiatorRole` in Core Data).
enum MessageInitiatorRole: String, CaseIterable, Identifiable {
    case parent
    case manager
    case broadcast

    var id: String { rawValue }

    var persistenceValue: String { rawValue }

    /// - Description: Whether the keyworker may reply in this thread.
    var allowsKeyworkerReply: Bool {
        switch self {
        case .parent, .manager: return true
        case .broadcast: return false
        }
    }

    static func fromPersistence(_ raw: String) -> MessageInitiatorRole {
        MessageInitiatorRole(rawValue: raw) ?? .parent
    }
}
