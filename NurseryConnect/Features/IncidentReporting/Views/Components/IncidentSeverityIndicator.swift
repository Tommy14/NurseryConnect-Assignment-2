//
//  IncidentSeverityIndicator.swift
//  NurseryConnect
//
//  Feature: Incident Reporting
//  Role: Keyworker
//  Created: 6 April 2026
//  Description: Compact severity label with iconography for triage at a glance.
//
// -----------------------------------------------------------------
// Date       Name        What has done
// -----------------------------------------------------------------
// 060426     Tommy1914   Created the file with icon and title layout.
// 100426     Tommy1914   Studio capsule presentation.
// -----------------------------------------------------------------

import SwiftUI

/// - Description: Shows severity with a warning-style icon for higher risk levels.
struct IncidentSeverityIndicator: View {
    let severity: IncidentSeverity

    private var icon: String {
        switch severity {
        case .minor: return "exclamationmark.circle"
        case .requiresFirstAid: return "cross.case"
        case .safeguardingConcern: return "hand.raised.fill"
        case .nearMiss: return "exclamationmark.triangle.fill"
        case .allergicReaction: return "allergens"
        case .medical: return "heart.text.square"
        }
    }

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(
                    LinearGradient(
                        colors: [Color.ncDanger, Color.orange.opacity(0.85)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
            Text(severity.title)
                .font(.subheadline.weight(.semibold))
            Spacer(minLength: 0)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.ncCardSurface)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 4)
        .overlay {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(Color.ncDanger.opacity(0.2), lineWidth: 1)
                .allowsHitTesting(false)
        }
        .accessibilityElement(children: .combine)
    }
}

#Preview {
    IncidentSeverityIndicator(severity: .requiresFirstAid)
}
