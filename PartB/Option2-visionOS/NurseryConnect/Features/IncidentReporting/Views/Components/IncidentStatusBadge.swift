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

    private var text: String {
        switch status {
        case .submitted: return "Awaiting review"
        case .managerReviewed: return "Awaiting review"
        default: return status.title
        }
    }

    private var color: Color {
        switch status {
        case .draft: return .gray
        case .submitted, .managerReviewed: return Color(red: 0.68, green: 0.36, blue: 0.35)
        case .parentNotified: return Color.ncAccentWarm
        case .acknowledged: return Color(red: 0.41, green: 0.62, blue: 0.38)
        }
    }

    var body: some View {
        StatusBadge(text: text, color: color)
    }
}

#Preview {
    IncidentStatusBadge(status: .submitted)
}
