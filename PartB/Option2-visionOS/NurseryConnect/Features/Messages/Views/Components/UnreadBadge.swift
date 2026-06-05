//
//  UnreadBadge.swift
//  NurseryConnect
//
//  Feature: Messages
//  Role: Keyworker
//  Created: 29 May 2026
//  Description: Red capsule showing total unread secure message count.
//

import CoreData
import SwiftUI

/// - Description: Live unread count badge for messaging navigation items.
struct UnreadBadge: View {
    @Environment(\.managedObjectContext) private var context
    @State private var unreadCount = 0

    var body: some View {
        Group {
            if unreadCount > 0 {
                Text(unreadCount > 99 ? "99+" : "\(unreadCount)")
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color.red, in: Capsule())
                    .accessibilityLabel("\(unreadCount) unread messages")
            }
        }
        .task { await refreshCount() }
        .onReceive(NotificationCenter.default.publisher(for: .NSManagedObjectContextObjectsDidChange, object: context)) { _ in
            Task { await refreshCount() }
        }
    }

    @MainActor
    private func refreshCount() async {
        do {
            let childIDs = try MessagingGDPRScope.assignedChildIDs(in: context)
            unreadCount = try MessagingGDPRScope.unreadInboundCount(childIDs: childIDs, in: context)
        } catch {
            unreadCount = 0
        }
    }
}
