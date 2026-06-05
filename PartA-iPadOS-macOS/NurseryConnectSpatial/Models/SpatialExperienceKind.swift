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
    case attendance
    case transport
    case mealPlan
    case messaging

    var id: String { rawValue }

    var title: String {
        switch self {
        case .keyworkerDashboard:   return "Keyworker dashboard"
        case .settingManagerOverview: return "Setting Manager"
        case .attendance:           return "Attendance"
        case .transport:            return "Transport tracker"
        case .mealPlan:             return "Meal plan"
        case .messaging:            return "Messages"
        }
    }

    var subtitle: String {
        switch self {
        case .keyworkerDashboard:
            return "Messages, your cohort, and mood insights for children on site."
        case .settingManagerOverview:
            return "Attendance, incidents, and parent engagement across the setting."
        case .attendance:
            return "Check children in and out. Monitor today's on-site ratios."
        case .transport:
            return "Live school-run tracker with manifest and ETA."
        case .mealPlan:
            return "Weekly menu with allergen flags and nutritional compliance."
        case .messaging:
            return "Encrypted parent and staff messaging. EYFS-compliant retention."
        }
    }

    var systemImage: String {
        switch self {
        case .keyworkerDashboard:   return "person.2.badge.gearshape.fill"
        case .settingManagerOverview: return "building.2.fill"
        case .attendance:           return "checkmark.seal.fill"
        case .transport:            return "bus.fill"
        case .mealPlan:             return "fork.knife"
        case .messaging:            return "bubble.left.and.bubble.right.fill"
        }
    }

    var actionLabel: String {
        switch self {
        case .keyworkerDashboard:   return "Open keyworker workspace"
        case .settingManagerOverview: return "Open manager overview"
        case .attendance:           return "Open attendance tracker"
        case .transport:            return "Open transport tracker"
        case .mealPlan:             return "Open meal plan"
        case .messaging:            return "Open messages"
        }
    }

    var windowID: String {
        switch self {
        case .keyworkerDashboard:   return SpatialWindowID.keyworkerDashboard
        case .settingManagerOverview: return SpatialWindowID.settingManager
        case .attendance:           return SpatialWindowID.attendance
        case .transport:            return SpatialWindowID.transport
        case .mealPlan:             return SpatialWindowID.mealPlan
        case .messaging:            return SpatialWindowID.messaging
        }
    }
}
