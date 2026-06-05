//
//  MessageBubbleView.swift
//  NurseryConnect
//
//  Feature: Messages
//  Role: Keyworker
//  Created: 29 May 2026
//  Description: iMessage-style bubble for secure chat messages.
//

import SwiftUI

struct MessageBubbleView: View {
    let message: Message

    private var senderRole: MessageSenderRole {
        MessageSenderRole.fromPersistence(message.senderRole ?? "")
    }

    private var isKeyworker: Bool {
        senderRole == .keyworker
    }

    var body: some View {
        HStack {
            if isKeyworker { Spacer(minLength: 48) }
            VStack(alignment: isKeyworker ? .trailing : .leading, spacing: 4) {
                if !isKeyworker {
                    Text(message.senderDisplayName ?? "")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                Text(message.body ?? "")
                    .font(.body)
                    .foregroundStyle(isKeyworker ? .white : .primary)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(bubbleColor, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                Text((message.sentAt ?? Date()).formattedTime())
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
            if !isKeyworker { Spacer(minLength: 48) }
        }
    }

    private var bubbleColor: Color {
        isKeyworker
            ? Color(red: 0.2, green: 0.65, blue: 0.62)
            : Color(.systemGray5)
    }
}
