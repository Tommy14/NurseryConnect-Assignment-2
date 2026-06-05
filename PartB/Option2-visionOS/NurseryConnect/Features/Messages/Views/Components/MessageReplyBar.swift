//
//  MessageReplyBar.swift
//  NurseryConnect
//
//  Feature: Messages
//  Role: Keyworker
//  Created: 29 May 2026
//  Description: Reply composer with character limit and send action.
//

import SwiftUI

struct MessageReplyBar: View {
    let canReply: Bool
    let disabledNotice: String
    @Binding var draftText: String
    let onSend: () -> Void

    private var showCounter: Bool {
        draftText.count >= AppConstants.messageBodyCounterThreshold
    }

    private var remainingCharacters: Int {
        AppConstants.messageBodyMaxLength - draftText.count
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if !canReply {
                Text(disabledNotice)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            HStack(alignment: .bottom, spacing: 10) {
                TextField("Reply…", text: $draftText, axis: .vertical)
                    .lineLimit(1...4)
                    .disabled(!canReply)
                    .onChange(of: draftText) { _, newValue in
                        if newValue.count > AppConstants.messageBodyMaxLength {
                            draftText = String(newValue.prefix(AppConstants.messageBodyMaxLength))
                        }
                    }

                Button(action: onSend) {
                    Image(systemName: "paperplane.fill")
                        .font(.body.weight(.semibold))
                        .foregroundStyle(.white)
                        .frame(width: 40, height: 40)
                        .background(canSend ? Color.ncPrimary : Color.gray.opacity(0.4), in: Circle())
                }
                .disabled(!canSend)
                .accessibilityIdentifier(AppConstants.AccessibilityID.sendMessageButton)
            }

            if showCounter && canReply {
                Text("\(remainingCharacters) characters remaining")
                    .font(.caption2)
                    .foregroundStyle(remainingCharacters < 50 ? .orange : .secondary)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(.bar)
    }

    private var canSend: Bool {
        canReply && !draftText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
}
