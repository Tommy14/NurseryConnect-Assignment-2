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
        HStack(spacing: 6) {
            Image(systemName: icon)
                .foregroundStyle(Color.ncDanger)
            Text(severity.title)
                .font(.footnote.weight(.semibold))
        }
        .accessibilityElement(children: .combine)
    }
}

#Preview {
    IncidentSeverityIndicator(severity: .requiresFirstAid)
}
