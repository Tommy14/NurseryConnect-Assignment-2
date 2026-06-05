//
//  ChildJournalSegment.swift
//  NurseryConnect
//
//  Feature: Daily Diary
//  Role: Keyworker
//  Created: 29 May 2026
//  Description: Segmented journal column content in the iPad split view.
//

import Foundation

/// - Description: Segmented journal column content in the iPad split view.
enum ChildJournalSegment: String, CaseIterable, Identifiable {
    case journal
    case milestones
    case charts

    var id: String { rawValue }

    var title: String {
        switch self {
        case .journal: return "Journal"
        case .milestones: return "Milestones"
        case .charts: return "Charts"
        }
    }

    /// - Description: Segment after this one when swiping left, if any.
    var next: ChildJournalSegment? {
        let all = Self.allCases
        guard let index = all.firstIndex(of: self), index < all.count - 1 else { return nil }
        return all[index + 1]
    }

    /// - Description: Segment before this one when swiping right, if any.
    var previous: ChildJournalSegment? {
        let all = Self.allCases
        guard let index = all.firstIndex(of: self), index > 0 else { return nil }
        return all[index - 1]
    }
}
