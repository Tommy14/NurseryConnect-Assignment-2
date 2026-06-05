//
//  MoodChartWindowID.swift
//  NurseryConnect Spatial
//
//  Feature: Spatial
//  Role: Keyworker
//  Created: 1 June 2026
//  Description: Window value type for opening the volumetric mood chart scene.
//

import Foundation

/// - Description: Identifies which child's mood chart to show in the volumetric window.
struct MoodChartWindowID: Codable, Hashable, Sendable {
    let childID: UUID
}
