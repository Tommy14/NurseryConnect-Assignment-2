//
//  IncidentCategory.swift
//  NurseryConnect
//
//  Feature: Incident Reporting
//  Role: Keyworker
//  Created: 1 April 2026
//  Description: Incident categories shown in the keyworker reporting flow with persistence bridging.
//
// -----------------------------------------------------------------
// Date       Name        What has done
// -----------------------------------------------------------------
// 010426     Tommy1914   Created the file with category metadata and severity mapping hooks.
// 120426     Tommy1914   Removed unused SwiftUI import after build hygiene pass.
// -----------------------------------------------------------------

import Foundation

/// - Description: High-level incident classification stored as `Incident.category` in Core Data.
enum IncidentCategory: String, CaseIterable, Identifiable {
    case accidentMinor
    case accidentFirstAid
    case safeguardingConcern
    case nearMiss
    case allergicReaction
    case medicalIncident

    var id: String { rawValue }

    /// - Description: Value written to Core Data `category` attribute.
    var persistenceValue: String { rawValue }

    /// - Description: Localised title for category cards and summaries.
    var title: String {
        switch self {
        case .accidentMinor: return "Accident (Minor)"
        case .accidentFirstAid: return "Accident (First Aid)"
        case .safeguardingConcern: return "Safeguarding Concern"
        case .nearMiss: return "Near Miss"
        case .allergicReaction: return "Allergic Reaction"
        case .medicalIncident: return "Medical Incident"
        }
    }

    /// - Description: SF Symbol name for grid cards.
    var symbolName: String {
        switch self {
        case .accidentMinor: return "bandage.fill"
        case .accidentFirstAid: return "cross.case.fill"
        case .safeguardingConcern: return "hand.raised.fill"
        case .nearMiss: return "exclamationmark.triangle.fill"
        case .allergicReaction: return "allergens.fill"
        case .medicalIncident: return "heart.text.square.fill"
        }
    }

    /// - Description: Default severity when this category is selected.
    var defaultSeverity: IncidentSeverity {
        switch self {
        case .accidentMinor: return .minor
        case .accidentFirstAid: return .requiresFirstAid
        case .safeguardingConcern: return .safeguardingConcern
        case .nearMiss: return .nearMiss
        case .allergicReaction: return .allergicReaction
        case .medicalIncident: return .medical
        }
    }

    /// - Description: Whether RIDDOR should be suggested by default for this category.
    var suggestsRiddor: Bool {
        switch self {
        case .accidentFirstAid, .safeguardingConcern, .medicalIncident: return true
        default: return false
        }
    }

    /// - Description: Restores enum from persisted storage with a safe fallback.
    /// - Parameters:
    ///   - raw: String from Core Data.
    /// - Returns: Matching category or `.accidentMinor`.
    static func fromPersistence(_ raw: String) -> IncidentCategory {
        IncidentCategory(rawValue: raw) ?? .accidentMinor
    }
}
