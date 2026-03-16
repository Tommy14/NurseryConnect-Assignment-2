//
//  EmptyStateView.swift
//  NurseryConnect
//
//  Feature: Shared UI
//  Role: Keyworker
//  Created: 30 March 2026
//  Description: Empty-state layout with SF Symbol artwork and supportive copy.
//
// -----------------------------------------------------------------
// Date       Name        What has done
// -----------------------------------------------------------------
// 300326     Tommy1914   Created the file with icon, title, and message stack.
// -----------------------------------------------------------------

import SwiftUI

/// - Description: Presents a friendly empty state when no records exist for a filter.
struct EmptyStateView: View {
    let symbolName: String
    let title: String
    let message: String

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: symbolName)
                .font(.system(size: 48))
                .foregroundStyle(Color.ncPrimary)
                .accessibilityHidden(true)
            Text(title)
                .font(AppTheme.headlineRounded())
                .multilineTextAlignment(.center)
            Text(message)
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(24)
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .combine)
    }
}

#Preview {
    EmptyStateView(symbolName: "calendar.badge.clock", title: "No entries", message: "Start logging today.")
        .background(Color.ncBackground)
}
