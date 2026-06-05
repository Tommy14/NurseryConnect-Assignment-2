//
//  EmptyStateView.swift
//  NurseryConnect
//
//  Feature: Shared UI
//  Role: Keyworker
//  Created: 30 March 2026
//  Description: Empty-state layout wrapping ContentUnavailableView with an optional CTA.
//

import SwiftUI

/// - Description: Presents a native empty state using ContentUnavailableView with an optional primary action.
struct EmptyStateView: View {
    let symbolName: String
    let title: String
    let message: String
    var actionTitle: String? = nil
    var action: (() -> Void)? = nil

    var body: some View {
        ContentUnavailableView {
            Label(title, systemImage: symbolName)
        } description: {
            Text(message)
        } actions: {
            if let actionTitle, let action {
                Button(actionTitle, action: action)
                    .buttonStyle(.borderedProminent)
                    .tint(Color.ncPrimary)
            }
        }
    }
}

#Preview {
    VStack(spacing: 32) {
        EmptyStateView(
            symbolName: "calendar.badge.clock",
            title: "No entries",
            message: "Start logging today.",
            actionTitle: "Add Entry",
            action: {}
        )
        EmptyStateView(
            symbolName: "shield.lefthalf.filled",
            title: "No incidents",
            message: "All clear today."
        )
    }
    .background(Color.ncBackground)
}
