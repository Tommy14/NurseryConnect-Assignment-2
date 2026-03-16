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

/// - Description: Primary action button used for save/submit flows.
struct PrimaryButton: View {
    let title: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .frame(maxWidth: .infinity)
        }
        .buttonStyle(PrimaryProminentButtonStyle())
        .accessibilityLabel(title)
        .accessibilityHint("Performs the primary action for this screen.")
    }
}

/// - Description: Secondary outline button for cancel or low-emphasis actions.
struct SecondaryButton: View {
    let title: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .frame(maxWidth: .infinity)
        }
        .buttonStyle(SecondaryOutlineButtonStyle())
        .accessibilityLabel(title)
        .accessibilityHint("Performs a secondary action.")
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
