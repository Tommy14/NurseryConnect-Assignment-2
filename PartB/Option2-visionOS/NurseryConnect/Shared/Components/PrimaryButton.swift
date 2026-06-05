//
//  PrimaryButton.swift
//  NurseryConnect
//
//  Feature: Shared UI
//  Role: Keyworker
//  Created: 30 March 2026
//  Description: Primary and secondary labelled controls with accessibility metadata.
//
// -----------------------------------------------------------------
// Date       Name        What has done
// -----------------------------------------------------------------
// 300326     Tommy1914   Created the file with prominent and outline variants.
// -----------------------------------------------------------------

import SwiftUI

/// - Description: Primary action button — uses system .borderedProminent for correct press state, a11y sizing, and pointer support.
struct PrimaryButton: View {
    let title: String
    let action: () -> Void

    var body: some View {
        Button(title, action: action)
            .buttonStyle(.borderedProminent)
            .tint(Color.ncPrimary)
            .controlSize(.large)
            .frame(maxWidth: .infinity)
            .accessibilityLabel(title)
    }
}

/// - Description: Secondary button — uses system .bordered for neutral low-emphasis actions.
struct SecondaryButton: View {
    let title: String
    let action: () -> Void

    var body: some View {
        Button(title, action: action)
            .buttonStyle(.bordered)
            .tint(Color.ncPrimary)
            .controlSize(.large)
            .frame(maxWidth: .infinity)
            .accessibilityLabel(title)
    }
}

#Preview {
    VStack(spacing: 16) {
        PrimaryButton(title: "Save entry", action: {})
        SecondaryButton(title: "Cancel", action: {})
    }
    .padding()
    .background(Color.ncBackground)
}
