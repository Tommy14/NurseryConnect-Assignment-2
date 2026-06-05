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
// 160426     Tommy1914   Background/card/glow from assets; dynamic glass + hairline helpers for dark mode.
// -----------------------------------------------------------------

import SwiftUI
import UIKit

extension Color {
    /// - Description: Primary calm blue from assets (`BrandPrimary`).
    static let ncPrimary = Color("BrandPrimary")

    /// - Description: Secondary nurturing green from assets (`BrandSecondary`).
    static let ncSecondary = Color("BrandSecondary")

    /// - Description: Warm amber accent from assets (`AccentWarm`).
    static let ncAccentWarm = Color("AccentWarm")

    /// - Description: Incident and alert red from assets (`Danger`).
    static let ncDanger = Color("Danger")

    /// - Description: Screen base (`Background` asset; light + dark appearances).
    static let ncBackground = Color("Background")

    /// - Description: Elevated card base (`CardSurface` asset; light + dark appearances).
    static let ncCardSurface = Color("CardSurface")

    /// - Description: Atmospheric gradient accents (`GlowBlue` / `GlowViolet` assets).
    static let ncGlowBlue = Color("GlowBlue")
    static let ncGlowViolet = Color("GlowViolet")

    /// - Description: Specular rim for glass-style strokes — full strength in light mode, subdued in dark mode.
    static func ncGlassHighlight(lightOpacity: CGFloat) -> Color {
        Color(UIColor { traits in
            let dark = traits.userInterfaceStyle == .dark
            let alpha: CGFloat
            if dark {
                alpha = min(0.30, max(0.04, lightOpacity * 0.36))
            } else {
                alpha = lightOpacity
            }
            return UIColor.white.withAlphaComponent(alpha)
        })
    }

    /// - Description: Hairline on filled pills/capsules: dark outline in light UI, light outline in dark UI.
    static var ncAdaptiveHairlineStroke: Color {
        Color(UIColor { traits in
            traits.userInterfaceStyle == .dark
                ? UIColor.white.withAlphaComponent(0.20)
                : UIColor.black.withAlphaComponent(0.30)
        })
    }

    /// - Description: Diary entry accent colours (pastel-friendly).
    static let ncDiaryActivity = Color("DiaryActivity")
    static let ncDiarySleep = Color("DiarySleep")
    static let ncDiaryMeal = Color("DiaryMeal")
    static let ncDiaryNappy = Color("DiaryNappy")
    static let ncDiaryWellbeing = Color("DiaryWellbeing")
}
