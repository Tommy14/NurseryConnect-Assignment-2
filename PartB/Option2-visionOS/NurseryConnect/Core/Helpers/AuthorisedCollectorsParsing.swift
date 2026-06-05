//
//  AuthorisedCollectorsParsing.swift
//  NurseryConnect
//
//  Feature: Core
//  Role: Keyworker
//  Created: 16 April 2026
//  Description: Parses multiline `Child.authorisedCollectors` for pickers and validation.
//

import Foundation

/// - Description: Pure helpers for the authorised collectors text field (one person per line).
enum AuthorisedCollectorsParsing {
    /// - Description: Non-empty trimmed lines from the stored string.
    /// - Parameters:
    ///   - raw: Value from `Child.authorisedCollectors`.
    static func lines(from raw: String?) -> [String] {
        guard let raw, raw.isEmpty == false else { return [] }
        return raw
            .components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
    }

    /// - Description: True when `selection` exactly matches one authorised line (audit-safe).
    static func isAuthorisedCollector(_ selection: String, allowedLines: [String]) -> Bool {
        let trimmed = selection.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.isEmpty == false else { return false }
        return allowedLines.contains(trimmed)
    }
}
