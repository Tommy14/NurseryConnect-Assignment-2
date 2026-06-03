//
//  SpatialExperienceKind.swift
//  NurseryConnect Spatial
//
//  Feature: Spatial
//  Created: 2 June 2026
//  Description: Identifies each spatial workspace opened from the hub.
//

import Foundation

/// - Description: Spatial workspaces available from the nursery home screen.
enum SpatialExperienceKind: String, CaseIterable, Identifiable {
    case keyworkerDashboard
    case settingManagerOverview

    var id: String { rawValue }

    var title: String {
        switch self {
        case .keyworkerDashboard: return "Keyworker dashboard"
        case .settingManagerOverview: return "Setting Manager overview"
        }
    }

    var subtitle: String {
        switch self {
        case .keyworkerDashboard:
            return "Messages, your cohort, and mood insights for children on site."
        case .settingManagerOverview:
            return "Attendance, incidents, and parent engagement across the setting."
        }
    }

    var systemImage: String {
        switch self {
        case .keyworkerDashboard: return "person.2.badge.gearshape.fill"
        case .settingManagerOverview: return "building.2.fill"
        }
    }

    var actionLabel: String {
        switch self {
        case .keyworkerDashboard: return "Open keyworker workspace"
        case .settingManagerOverview: return "Open manager overview"
        }
    }
}
