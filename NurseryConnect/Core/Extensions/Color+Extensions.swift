//
//  Color+Extensions.swift
//  NurseryConnect
//
//  Feature: Core
//  Role: Keyworker
//  Created: 29 March 2026
//  Description: Bridges asset catalogue colours into SwiftUI `Color` values.
//
// -----------------------------------------------------------------
// Date       Name        What has done
// -----------------------------------------------------------------
// 290326     Tommy1914   Created the file with semantic palette accessors.
// -----------------------------------------------------------------

import SwiftUI

extension Color {
    /// - Description: Primary calm blue from assets (`BrandPrimary`).
    static let ncPrimary = Color("BrandPrimary")

    /// - Description: Secondary nurturing green from assets (`BrandSecondary`).
    static let ncSecondary = Color("BrandSecondary")

    /// - Description: Warm amber accent from assets (`AccentWarm`).
    static let ncAccentWarm = Color("AccentWarm")

    /// - Description: Incident and alert red from assets (`Danger`).
    static let ncDanger = Color("Danger")

    /// - Description: Screen background from assets (`Background`).
    static let ncBackground = Color("Background")

    /// - Description: Card surface from assets (`CardSurface`).
    static let ncCardSurface = Color("CardSurface")

    /// - Description: Diary entry accent colours (pastel-friendly).
    static let ncDiaryActivity = Color("DiaryActivity")
    static let ncDiarySleep = Color("DiarySleep")
    static let ncDiaryMeal = Color("DiaryMeal")
    static let ncDiaryNappy = Color("DiaryNappy")
    static let ncDiaryWellbeing = Color("DiaryWellbeing")
}
