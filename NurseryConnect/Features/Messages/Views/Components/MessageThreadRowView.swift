//
//  MessageThreadRowView.swift
//  NurseryConnect
//
//  Feature: Messages
//  Role: Keyworker
//  Created: 29 May 2026
//  Description: Inbox row for one secure message thread.
//

import SwiftUI

struct MessageThreadRowView: View {
    let row: MessageThreadRow

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            ZStack {
                Circle()
                    .fill(Color.ncPrimary.opacity(0.15))
                    .frame(width: 44, height: 44)
                Text(row.childInitial)
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(Color.ncPrimary)
            }

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    if row.isBroadcast {
                        Image(systemName: "megaphone.fill")
                            .font(.caption)
                            .foregroundStyle(.orange)
                    }
                    Text(row.isBroadcast ? "From: Setting Manager" : row.childDisplayName)
                        .font(.subheadline.weight(.semibold))
                        .lineLimit(1)
                    Spacer(minLength: 8)
                    Text(MessageFormatting.relativeTime(from: row.lastMessageAt))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Text(row.subject)
                    .font(.subheadline)
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                Text(row.lastMessagePreview)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }

            if row.hasUnread {
                Circle()
                    .fill(Color.red)
                    .frame(width: 10, height: 10)
                    .padding(.top, 6)
            }
        }
        .padding(.vertical, 4)
        .accessibilityIdentifier("\(AppConstants.AccessibilityID.messageThreadRowPrefix)\(row.threadID.uuidString)")
    }
}
