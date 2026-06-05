//
//  ButtonStyles.swift
//  NurseryConnect
//
//  Feature: Shared UI
//  Role: Keyworker
//  Created: 29 March 2026
//  Description: Reusable button styles for primary and secondary actions.
//
// -----------------------------------------------------------------
// Date       Name        What has done
// -----------------------------------------------------------------
// 290326     Tommy1914   Created the file with filled and outline button styles.
// -----------------------------------------------------------------

import SwiftUI

/// - Description: Retained for source compatibility — PrimaryButton now delegates directly to .borderedProminent.
struct PrimaryProminentButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .opacity(configuration.isPressed ? 0.85 : 1.0)
    }
}

/// - Description: Retained for source compatibility — SecondaryButton now delegates directly to .bordered.
struct SecondaryOutlineButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .opacity(configuration.isPressed ? 0.7 : 1.0)
    }
}
