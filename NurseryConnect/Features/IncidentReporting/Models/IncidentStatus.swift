//
//  IncidentStatus.swift
//  NurseryConnect
//
//  Feature: Incident Reporting
//  Role: Keyworker
//  Created: 1 April 2026
//  Description: Incident workflow states and severity levels persisted as strings in Core Data.
//
// -----------------------------------------------------------------
// Date       Name        What has done
// -----------------------------------------------------------------
// 010426     Tommy1914   Created the file with status/severity bridging and display metadata.
// 100426     Tommy1914   SF Symbol names for the vertical workflow timeline.
// -----------------------------------------------------------------

import Foundation
import SwiftUI

/// - Description: Workflow state for an incident (`Incident.status` in Core Data).
enum IncidentStatus: String, CaseIterable, Identifiable {
    case draft
    case submitted
    case managerReviewed
    case parentNotified
    case acknowledged

    var id: String { rawValue }

    var persistenceValue: String { rawValue }

    /// - Description: Short label for badges and the horizontal tracker.
    var title: String {
        switch self {
        case .draft: return "Draft"
        case .submitted: return "Submitted"
        case .managerReviewed: return "Reviewed"
        case .parentNotified: return "Parent notified"
        case .acknowledged: return "Acknowledged"
        }
    }

    /// - Description: Ordered index for the step indicator (0-based).
    var stepIndex: Int {
        switch self {
        case .draft: return 0
        case .submitted: return 1
        case .managerReviewed: return 2
        case .parentNotified: return 3
        case .acknowledged: return 4
        }
    }

    /// - Description: SF Symbol for the vertical workflow timeline (filled variants read well at small sizes).
    var workflowSymbolName: String {
        switch self {
        case .draft: return "square.and.pencil.circle.fill"
        case .submitted: return "paperplane.circle.fill"
        case .managerReviewed: return "checkmark.seal.fill"
        case .parentNotified: return "bubble.left.and.bubble.right.fill"
        case .acknowledged: return "hand.thumbsup.circle.fill"
        }
    }

    /// - Description: Parses persisted status safely.
    /// - Parameters:
    ///   - raw: Stored string.
    /// - Returns: Parsed status or `.draft`.
    static func fromPersistence(_ raw: String) -> IncidentStatus {
        IncidentStatus(rawValue: raw) ?? .draft
    }
}

/// - Description: Harm and response level for an incident (`Incident.severity` in Core Data).
enum IncidentSeverity: String, CaseIterable, Identifiable {
    case minor
    case requiresFirstAid
    case safeguardingConcern
    case nearMiss
    case allergicReaction
    case medical

    var id: String { rawValue }

    var persistenceValue: String { rawValue }

    var title: String {
        switch self {
        case .minor: return "Minor"
        case .requiresFirstAid: return "Requires first aid"
        case .safeguardingConcern: return "Safeguarding concern"
        case .nearMiss: return "Near miss"
        case .allergicReaction: return "Allergic reaction"
        case .medical: return "Medical"
        }
    }

    /// - Description: Parses persisted severity safely.
    /// - Parameters:
    ///   - raw: Stored string.
    /// - Returns: Parsed severity or `.minor`.
    static func fromPersistence(_ raw: String) -> IncidentSeverity {
        IncidentSeverity(rawValue: raw) ?? .minor
    }
}
