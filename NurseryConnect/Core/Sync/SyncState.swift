//
//  SyncState.swift
//  NurseryConnect
//
//  Feature: Core
//  Role: Keyworker
//  Created: 13 April 2026
//  Description: Shared sync status mapping for local-first queue processing.
//

import Foundation

enum SyncState: String, CaseIterable {
    case synced
    case pending
    case failed

    static func fromPersistence(_ rawValue: String?) -> SyncState {
        guard let rawValue, let state = SyncState(rawValue: rawValue) else {
            return .synced
        }
        return state
    }
}
