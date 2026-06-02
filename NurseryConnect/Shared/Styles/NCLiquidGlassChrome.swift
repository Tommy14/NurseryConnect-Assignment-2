//
//  NCLiquidGlassChrome.swift
//  NurseryConnect
//
//  Feature: Shared UI
//  Role: Keyworker
//  Created: 16 April 2026
//  Description: Background-only liquid glass plates (iOS 26+). Never wrap text/icons — only empty `RoundedRectangle`s use `glassEffect`.
//

import SwiftUI

/// - Description: Reusable frosted **background** shapes for cards and panels. Content must sit in a separate layer above these views.
enum NCLiquidGlassChrome {
    /// - Description: Standard list/dashboard card fill: glass on iOS 26+, `ncCardSurface` below.
    @ViewBuilder
    static func cardBackground(cornerRadius: CGFloat) -> some View {
        #if os(iOS)
        if #available(iOS 26.0, *) {
            LiquidGlassCardPlate(cornerRadius: cornerRadius)
        } else {
            OpaqueCardPlate(cornerRadius: cornerRadius)
        }
        #else
        OpaqueCardPlate(cornerRadius: cornerRadius)
        #endif
    }

    /// - Description: Incident row: frosted base on iOS 26 with a soft tint wash; single gradient on older OS.
    @ViewBuilder
    static func incidentRowBackground(accent: Color, cornerRadius: CGFloat) -> some View {
        #if os(iOS)
        if #available(iOS 26.0, *) {
            ZStack {
                LiquidGlassCardPlate(cornerRadius: cornerRadius)
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.ncCardSurface.opacity(0.58),
                                accent.opacity(0.1)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }
        } else {
            incidentRowOpaqueBackground(accent: accent, cornerRadius: cornerRadius)
        }
        #else
        incidentRowOpaqueBackground(accent: accent, cornerRadius: cornerRadius)
        #endif
    }

    @ViewBuilder
    private static func incidentRowOpaqueBackground(accent: Color, cornerRadius: CGFloat) -> some View {
        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
            .fill(
                LinearGradient(
                    colors: [Color.ncCardSurface, accent.opacity(0.08)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
    }
}

// MARK: - Private plates

private struct OpaqueCardPlate: View {
    let cornerRadius: CGFloat

    var body: some View {
        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
            .fill(Color.ncCardSurface)
    }
}

#if os(iOS)
@available(iOS 26.0, *)
struct LiquidGlassCardPlate: View {
    let cornerRadius: CGFloat

    var body: some View {
        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
            .fill(Color.clear)
            .glassEffect(
                Glass.clear
                    .tint(Color.ncGlassHighlight(lightOpacity: 0.1))
                    .interactive(),
                in: RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
            )
    }
}
#endif
