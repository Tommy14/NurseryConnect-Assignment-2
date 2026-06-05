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
// 300526     Tommy1914   Headings use SF Pro (default system design) instead of SF Pro Rounded.
// 140426     Tommy1914   `ncRootScrollEdgeEffectForTopNavigation` for iOS 26 root lists.
// 210426     Tommy1914   Stronger top scroll-edge style so nav-bar drag shows the same magnified glass response as the tab dock.
// -----------------------------------------------------------------

import SwiftUI

/// - Description: Central place for fonts and semantic colours used across SwiftUI screens.
enum AppTheme {
    /// - Description: Major headings — uses semantic Dynamic Type style so text scales with user preferences.
    static func headlineRounded() -> Font { .title2.weight(.semibold) }

    /// - Description: Large greeting style for the dashboard banner.
    static func greetingRounded() -> Font { .title.weight(.bold) }

    /// - Description: Secondary title for section headers.
    static func titleRounded() -> Font { .title3.weight(.semibold) }

    /// - Description: Body text.
    static func bodyPrimary() -> Font { .body }

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

extension View {
    /// - Description: Uppercase section overline (e.g. “TODAY”, “INBOX SCOPE”) used on dashboard and incidents.
    func ncSectionOverlineStyle() -> some View {
        font(.caption2.weight(.heavy))
            .tracking(1.1)
            .textCase(.uppercase)
            .foregroundStyle(.secondary)
    }

    /// - Description: Enables the top scroll-edge/nav-bar drag response on root scroll views where this modifier is applied.
    @ViewBuilder
    func ncRootScrollEdgeEffectForTopNavigation() -> some View {
        #if os(iOS)
        if #available(iOS 26.0, *) {
            self.scrollEdgeEffectStyle(.hard, for: .top)
        } else {
            self
        }
        #else
        self
        #endif
    }
}
