//
//  DiaryEntryType.swift
//  NurseryConnect
//
//  Feature: Daily Diary
//  Role: Keyworker
//  Created: 28 March 2026
//  Description: Maps diary entry kinds to persisted Core Data string values.
//
// -----------------------------------------------------------------
// Date       Name        What has done
// -----------------------------------------------------------------
// 280326     Tommy1914   Created the file with persistence bridging for diary entry types.
// -----------------------------------------------------------------

import Foundation

/// - Description: Categories of daily diary observations stored as `DiaryEntry.entryType` in Core Data.
enum DiaryEntryType: String, CaseIterable, Identifiable {
    case activity
    case sleep
    case meal
    case nappy
    case wellbeing
    case milestone

    var id: String { rawValue }

    /// - Description: Value written to Core Data `entryType` attribute.
    var persistenceValue: String { rawValue }

    var title: String {
        switch self {
        case .activity: return "Activity"
        case .sleep: return "Sleep"
        case .meal: return "Meal"
        case .nappy: return "Nappy"
        case .wellbeing: return "Wellbeing"
        case .milestone: return "Milestone"
        }
    }

    /// - Description: Builds an enum case from persisted storage, defaulting to activity if unknown.
    /// - Parameters:
    ///   - raw: String from Core Data.
    /// - Returns: Matching `DiaryEntryType` or `.activity`.
    static func fromPersistence(_ raw: String) -> DiaryEntryType {
        DiaryEntryType(rawValue: raw) ?? .activity
    }
}
