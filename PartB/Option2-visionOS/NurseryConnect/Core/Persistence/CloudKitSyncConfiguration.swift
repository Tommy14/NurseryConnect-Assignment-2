//
//  CloudKitSyncConfiguration.swift
//  NurseryConnect
//
//  Feature: Core
//  Role: Keyworker
//  Created: 4 June 2026
//  Description: Shared CloudKit container identifier for iPad and visionOS targets.
//

import Foundation

/// - Description: CloudKit identifiers used by both NurseryConnect and NurseryConnect Spatial.
enum CloudKitSyncConfiguration {
    /// - Description: Must match `com.apple.developer.icloud-container-identifiers` in entitlements.
    static let containerIdentifier = "iCloud.com.assignment.NurseryConnect"
}

extension Notification.Name {
    /// - Description: Posted when CloudKit imports merge into the local persistent store (refresh UI).
    static let nurseryConnectPersistentStoreRemoteChange = Notification.Name(
        "NurseryConnectPersistentStoreRemoteChange"
    )
}
