//
//  SpatialChildSummary.swift
//  NurseryConnect Spatial
//
//  Feature: Spatial
//  Role: Keyworker
//  Created: 2 June 2026
//  Description: Lightweight child row model for the visionOS dashboard.
//

import Foundation

/// - Description: Diary completeness indicator for spatial child cards.
enum SpatialDiaryCompleteness: String, Hashable {
    case complete
    case partial
    case none
}

/// - Description: Dashboard row for one assigned child on the spatial workspace.
struct SpatialChildSummary: Identifiable, Hashable {
    let id: UUID
    let firstName: String
    let lastName: String
    let preferredName: String
    let roomName: String
    let allergies: String
    let photoConsent: Bool
    let dot: SpatialDiaryCompleteness
    let attendanceBucket: KeyworkerAttendanceBucket
    let latestMoodRating: Int16?
    let hasOpenIncident: Bool
}
