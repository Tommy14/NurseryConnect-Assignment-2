//
//  StatusBadge.swift
//  NurseryConnect
//
//  Feature: Shared UI
//  Role: Keyworker
//  Created: 30 March 2026
//  Description: Compact capsule label for generic status text.
//
// -----------------------------------------------------------------
// Date       Name        What has done
// -----------------------------------------------------------------
// 300326     Tommy1914   Created the file with tinted background styling.
// -----------------------------------------------------------------

import SwiftUI

/// - Description: Small pill-shaped badge for inline status copy.
struct StatusBadge: View {
    let text: String
    let color: Color

    var body: some View {
        Text(text)
            .font(.caption.weight(.semibold))
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(color.opacity(0.18))
            .foregroundStyle(color)
            .clipShape(Capsule())
            .accessibilityLabel("Status \(text)")
    }
}

#Preview {
    StatusBadge(text: "Submitted", color: .ncPrimary)
}
