//
//  LoadingOverlay.swift
//  NurseryConnect
//
//  Feature: Shared UI
//  Role: Keyworker
//  Created: 30 March 2026
//  Description: Full-screen translucent overlay with a progress indicator.
//
// -----------------------------------------------------------------
// Date       Name        What has done
// -----------------------------------------------------------------
// 300326     Tommy1914   Created the file with progress view and label.
// -----------------------------------------------------------------

import SwiftUI

/// - Description: Blocks interaction while asynchronous work completes.
struct LoadingOverlay: View {
    let message: String

    var body: some View {
        ZStack {
            Color.black.opacity(0.15)
                .ignoresSafeArea()
            VStack(spacing: 12) {
                ProgressView()
                    .progressViewStyle(.circular)
                Text(message)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .padding(20)
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
        .accessibilityLabel("Loading")
        .accessibilityHint(message)
    }
}

#Preview {
    LoadingOverlay(message: "Saving…")
}
