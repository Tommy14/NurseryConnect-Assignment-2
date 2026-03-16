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

/// - Description: Primary filled button with rounded corners and brand colour.
struct PrimaryProminentButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .foregroundStyle(Color.white)
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .frame(minHeight: AppConstants.minimumTouchTarget)
            .background(Color.ncPrimary.opacity(configuration.isPressed ? 0.85 : 1.0))
            .clipShape(RoundedRectangle(cornerRadius: AppConstants.buttonCornerRadius, style: .continuous))
    }
}

/// - Description: Secondary outline button for neutral actions.
struct SecondaryOutlineButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .foregroundStyle(Color.ncPrimary)
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .frame(minHeight: AppConstants.minimumTouchTarget)
            .background(
                RoundedRectangle(cornerRadius: AppConstants.buttonCornerRadius, style: .continuous)
                    .stroke(Color.ncPrimary.opacity(configuration.isPressed ? 0.6 : 1.0), lineWidth: 1.5)
            )
    }
}
