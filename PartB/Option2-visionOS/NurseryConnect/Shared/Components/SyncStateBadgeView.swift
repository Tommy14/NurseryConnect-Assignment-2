//
//  SyncStateBadgeView.swift
//  NurseryConnect
//
//  Feature: Shared
//  Role: Keyworker
//  Created: 10 April 2026
//  Description: Compact icon that communicates local sync state for queued records.
//

import SwiftUI

struct SyncStateBadgeView: View {
    let state: SyncState

    var body: some View {
        Image(systemName: symbol)
            .font(.subheadline.weight(.semibold))
            .symbolRenderingMode(.hierarchical)
            .foregroundStyle(foregroundColor)
            .padding(6)
            .background(Circle().fill(backgroundColor))
            .overlay(Circle().stroke(foregroundColor.opacity(0.28), lineWidth: 1))
            .accessibilityLabel("Sync state \(labelTitle)")
    }

    private var labelTitle: String {
        switch state {
        case .synced: return "Synced"
        case .pending: return "Pending sync"
        case .failed: return "Sync failed"
        }
    }

    private var symbol: String {
        switch state {
        case .synced: return "checkmark.icloud.fill"
        case .pending: return "icloud.and.arrow.up"
        case .failed: return "exclamationmark.icloud.fill"
        }
    }

    private var foregroundColor: Color {
        switch state {
        case .synced: return .green
        case .pending: return Color.ncPrimary
        case .failed: return Color.ncDanger
        }
    }

    private var backgroundColor: Color {
        switch state {
        case .synced: return Color.green.opacity(0.14)
        case .pending: return Color.ncPrimary.opacity(0.14)
        case .failed: return Color.ncDanger.opacity(0.12)
        }
    }
}
