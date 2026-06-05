//
//  NurseryTheme.swift
//  NurseryConnect Spatial
//
//  Feature: Spatial
//  Created: 4 June 2026
//  Description: Shared visionOS colour and typography theme for NurseryConnect spatial views.
//

import SwiftUI

/// - Description: Centralised colour and typography tokens for the spatial UI.
enum NurseryTheme {
    static let primary      = Color(red: 0.20, green: 0.60, blue: 0.95)
    static let accent       = Color(red: 0.35, green: 0.85, blue: 0.65)
    static let warning      = Color(red: 1.00, green: 0.62, blue: 0.00)
    static let danger       = Color(red: 0.95, green: 0.30, blue: 0.30)
    static let surface      = Color.white.opacity(0.12)
    static let surfaceHover = Color.white.opacity(0.18)
    static let textPrimary  = Color.white
    static let textSecondary = Color.white.opacity(0.65)
}

// MARK: - EYFS area colours
extension NurseryTheme {
    enum EYFS {
        static let physical    = Color(red: 0.20, green: 0.55, blue: 0.95)
        static let communication = Color(red: 0.55, green: 0.25, blue: 0.90)
        static let psed        = Color(red: 0.95, green: 0.35, blue: 0.65)
        static let literacy    = Color(red: 0.95, green: 0.50, blue: 0.10)
        static let maths       = Color(red: 0.10, green: 0.70, blue: 0.75)
        static let world       = Color(red: 0.20, green: 0.70, blue: 0.40)
        static let expressive  = Color(red: 0.95, green: 0.40, blue: 0.35)

        static func color(for area: String) -> Color {
            switch area.lowercased() {
            case let s where s.contains("physical"):      return physical
            case let s where s.contains("communication"): return communication
            case let s where s.contains("psed"), let s where s.contains("personal"): return psed
            case let s where s.contains("literacy"):      return literacy
            case let s where s.contains("math"):          return maths
            case let s where s.contains("world"):         return world
            case let s where s.contains("express"):       return expressive
            default:                                       return primary
            }
        }
    }
}

// MARK: - Font helpers
extension Font {
    static let ncLargeTitle  = Font.system(.largeTitle,  design: .rounded, weight: .bold)
    static let ncTitle2      = Font.system(.title2,      design: .rounded, weight: .semibold)
    static let ncTitle3      = Font.system(.title3,      design: .rounded, weight: .semibold)
    static let ncHeadline    = Font.system(.headline,    design: .rounded, weight: .semibold)
    static let ncBody        = Font.system(.body,        design: .rounded)
    static let ncCaption     = Font.system(.caption,     design: .rounded)
    static let ncCaption2    = Font.system(.caption2,    design: .rounded)
}

// MARK: - Card modifier helper
struct GlassCard: ViewModifier {
    var cornerRadius: CGFloat = 20

    func body(content: Content) -> some View {
        content
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(Color.white.opacity(0.15), lineWidth: 1)
            )
    }
}

extension View {
    func glassCard(cornerRadius: CGFloat = 20) -> some View {
        modifier(GlassCard(cornerRadius: cornerRadius))
    }
}
