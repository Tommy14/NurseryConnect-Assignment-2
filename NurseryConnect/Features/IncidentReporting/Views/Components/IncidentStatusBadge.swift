//
//  IncidentStatusBadge.swift
//  NurseryConnect
//
//  Feature: Incident Reporting
//  Role: Keyworker
//  Created: 6 April 2026
//  Description: Colour-coded capsule for incident workflow states.
//
// -----------------------------------------------------------------
// Date       Name        What has done
// -----------------------------------------------------------------
// 060426     Tommy1914   Created the file with palette mapping for each status.
// -----------------------------------------------------------------

import SwiftUI

/// - Description: Renders a human-readable incident status with semantic colours.
struct IncidentStatusBadge: View {
    let status: IncidentStatus

    private var color: Color {
        switch status {
        case .draft: return .gray
        case .submitted: return .blue
        case .managerReviewed: return .purple
        case .parentNotified: return Color.ncAccentWarm
        case .acknowledged: return Color.ncSecondary
        }
    }

    var body: some View {
        StatusBadge(text: status.title, color: color)
    }
}

#Preview {
    IncidentStatusBadge(status: .submitted)
}
