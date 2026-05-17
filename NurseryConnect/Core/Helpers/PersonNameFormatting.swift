//
//  PersonNameFormatting.swift
//  NurseryConnect
//
//  Feature: Core
//  Role: Keyworker
//  Created: 29 May 2026
//  Description: Consistent legal/full name formatting for child and practitioner UI.
//

import CoreData
import Foundation

/// - Description: Builds display names from first and last name parts.
enum PersonNameFormatting {
    /// - Description: First and last name joined for lists, headers, and messaging.
    static func fullName(first: String?, last: String?) -> String {
        let firstTrimmed = first?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let lastTrimmed = last?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let combined = [firstTrimmed, lastTrimmed].filter { !$0.isEmpty }.joined(separator: " ")
        return combined.isEmpty ? "Child" : combined
    }

    /// - Description: First character of the first name, or "?" when empty.
    static func givenNameInitial(first: String?) -> String {
        let trimmed = first?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        guard let character = trimmed.first else { return "?" }
        return String(character).uppercased()
    }
}

extension KeyworkerChildSummary {
    /// - Description: Legal/full name for roster, journal chrome, and analytics labels.
    var fullName: String {
        PersonNameFormatting.fullName(first: firstName, last: lastName)
    }
}

extension Child {
    /// - Description: Legal/full name for incidents, messaging, and profile headers.
    var fullDisplayName: String {
        PersonNameFormatting.fullName(first: firstName, last: lastName)
    }
}
