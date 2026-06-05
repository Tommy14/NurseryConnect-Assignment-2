//
//  BroadcastMessageCard.swift
//  NurseryConnect
//
//  Feature: Messages
//  Role: Keyworker
//  Created: 29 May 2026
//  Description: Centred info card for broadcast and incident notification messages.
//

import SwiftUI

struct BroadcastMessageCard: View {
    let message: Message

    private var messageType: MessageType {
        MessageType.fromPersistence(message.messageType ?? "")
    }

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: iconName)
                .font(.title2)
                .foregroundStyle(.orange)
            Text(message.senderDisplayName ?? AppConstants.settingManagerDisplayName)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
            Text(headerTitle)
                .font(.subheadline.weight(.bold))
            Text(message.body ?? "")
                .font(.subheadline)
                .multilineTextAlignment(.center)
                .foregroundStyle(.primary)
            Text((message.sentAt ?? Date()).formattedTime(style: .medium))
                .font(.caption2)
                .foregroundStyle(.tertiary)
        }
        .frame(maxWidth: .infinity)
        .padding(16)
        .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: AppConstants.cardCornerRadius))
        .padding(.horizontal, 8)
    }

    private var iconName: String {
        messageType == .incidentNotification ? "exclamationmark.shield.fill" : "megaphone.fill"
    }

    private var headerTitle: String {
        switch messageType {
        case .incidentNotification: return "Incident notification"
        case .broadcast: return "Setting broadcast"
        default: return "Notice"
        }
    }
}
