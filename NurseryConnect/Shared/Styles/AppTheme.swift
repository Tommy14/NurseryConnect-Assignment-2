//
//  AppTheme.swift
//  NurseryConnect
//
//  Feature: Shared UI
//  Role: Keyworker
//  Created: 29 March 2026
//  Description: Typography and colour helpers that keep the nursery UI cohesive.
//
// -----------------------------------------------------------------
// Date       Name        What has done
// -----------------------------------------------------------------
// 290326     Tommy1914   Created the file with rounded headings and semantic colours.
// -----------------------------------------------------------------

import SwiftUI

/// - Description: Central place for fonts and semantic colours used across SwiftUI screens.
enum AppTheme {
    /// - Description: Friendly rounded style for major headings (SF Pro Rounded via design).
    static func headlineRounded() -> Font {
        .system(.title2, design: .rounded).weight(.semibold)
    }

    /// - Description: Large greeting style for the dashboard banner.
    static func greetingRounded() -> Font {
        .system(.title, design: .rounded).weight(.bold)
    }

    /// - Description: Secondary rounded title for section headers.
    static func titleRounded() -> Font {
        .system(.title3, design: .rounded).weight(.semibold)
    }

    /// - Description: Body text uses default SF Pro via semantic text styles.
    static func bodyPrimary() -> Font {
        .body
    }

    /// - Description: Maps diary entry types to pastel-friendly colours for nodes and cards.
    /// - Parameters:
    ///   - type: Diary entry classification.
    /// - Returns: SwiftUI colour from the asset catalogue.
    static func diaryColor(for type: DiaryEntryType) -> Color {
        switch type {
        case .activity: return .ncDiaryActivity
        case .sleep: return .ncDiarySleep
        case .meal: return .ncDiaryMeal
        case .nappy: return .ncDiaryNappy
        case .wellbeing, .milestone: return .ncDiaryWellbeing
        }
    }

    /// - Description: Readable foreground on top of pastel diary backgrounds.
    /// - Parameters:
    ///   - type: Diary entry classification.
    /// - Returns: Contrasting text colour.
    static func diaryForeground(for type: DiaryEntryType) -> Color {
        Color.primary.opacity(0.9)
    }
}
