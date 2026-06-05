//
//  MessageSenderRole.swift
//  NurseryConnect
//
//  Feature: Messages
//  Role: Keyworker
//  Created: 29 May 2026
//  Description: Sender roles persisted on Message.senderRole.
//

import Foundation

/// - Description: Role of the author of a single message (`Message.senderRole` in Core Data).
enum MessageSenderRole: String, CaseIterable, Identifiable {
    case keyworker
    case parent
    case manager

    var id: String { rawValue }

    var persistenceValue: String { rawValue }

    static func fromPersistence(_ raw: String) -> MessageSenderRole {
        MessageSenderRole(rawValue: raw) ?? .keyworker
    }
}
