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

    /// - Description: Futuristic screen base used app-wide.
    static let ncBackground = Color(red: 0.93, green: 0.95, blue: 0.99)

    /// - Description: Elevated card base used app-wide.
    static let ncCardSurface = Color(red: 0.97, green: 0.98, blue: 1.0)

    /// - Description: Futuristic accent helper tones for subtle atmospheric gradients.
    static let ncGlowBlue = Color(red: 0.24, green: 0.73, blue: 0.96)
    static let ncGlowViolet = Color(red: 0.52, green: 0.56, blue: 0.98)

    /// - Description: Diary entry accent colours (pastel-friendly).
    static let ncDiaryActivity = Color("DiaryActivity")
    static let ncDiarySleep = Color("DiarySleep")
    static let ncDiaryMeal = Color("DiaryMeal")
    static let ncDiaryNappy = Color("DiaryNappy")
    static let ncDiaryWellbeing = Color("DiaryWellbeing")
}
