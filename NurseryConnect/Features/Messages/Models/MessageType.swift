//
//  MessageType.swift
//  NurseryConnect
//
//  Feature: Messages
//  Role: Keyworker
//  Created: 29 May 2026
//  Description: Message kinds persisted on Message.messageType.
//

import Foundation

/// - Description: Classification of a secure message (`Message.messageType` in Core Data).
enum MessageType: String, CaseIterable, Identifiable {
    case message
    case endOfDaySummary = "end_of_day_summary"
    case broadcast
    case incidentNotification = "incident_notification"

    var id: String { rawValue }

    var persistenceValue: String { rawValue }

    /// - Description: Renders as a centred info card instead of a chat bubble.
    var usesInfoCardLayout: Bool {
        switch self {
        case .broadcast, .incidentNotification: return true
        case .message, .endOfDaySummary: return false
        }
    }

    static func fromPersistence(_ raw: String) -> MessageType {
        MessageType(rawValue: raw) ?? .message
    }
}
