//
//  View+Extensions.swift
//  NurseryConnect
//
//  Feature: Core
//  Role: Keyworker
//  Created: 29 March 2026
//  Description: Reusable SwiftUI modifiers for cards, haptics, and accessibility sizing.
//
// -----------------------------------------------------------------
// Date       Name        What has done
// -----------------------------------------------------------------
// 290326     Tommy1914   Created the file with card chrome and haptic helpers.
// 100426     Tommy1914   `ncStudioElevatedSurface` for glassy gradient-bordered panels (decorative overlays non-interactive).
// 140426     Tommy1914   `ncDiaryTimelineCard` — toned down to light tint + single shadow (diary list).
// 140426     Tommy1914   Card/timeline modifiers use `NCLiquidGlassChrome` on iOS 26 (background plates only).
// 160426     Tommy1914   Card rim gradients use `ncGlassHighlight` for dark mode.
// 160426     Tommy1914   Bolder 2pt gradient rims on `ncCardStyle`, `ncStudioElevatedSurface`, tinted/diary tiles.
// -----------------------------------------------------------------

import SwiftUI
import UIKit

extension View {
    /// - Description: Applies standard card styling for list and dashboard tiles.
    /// - Parameters:
    ///   - radius: Corner radius in points.
    /// - Returns: A view with background, shadow, and rounded corners.
    func ncCardStyle(radius: CGFloat = AppConstants.cardCornerRadius) -> some View {
        self
            .background {
                NCLiquidGlassChrome.cardBackground(cornerRadius: radius)
            }
            .clipShape(RoundedRectangle(cornerRadius: radius, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: radius, style: .continuous)
                    .stroke(
                        LinearGradient(
                            colors: [
                                Color.ncGlassHighlight(lightOpacity: 0.95),
                                Color.ncGlowBlue.opacity(0.48),
                                Color.ncGlowViolet.opacity(0.4)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 2
                    )
                    .allowsHitTesting(false)
            }
            .shadow(color: Color.black.opacity(0.08), radius: 12, x: 0, y: 6)
            .shadow(color: Color.ncGlowBlue.opacity(0.2), radius: 22, x: 0, y: 12)
    }

    /// - Description: Ensures a minimum 44pt hit target for accessibility.
    /// - Returns: View with `frame(minWidth:minHeight:)` using `AppConstants.minimumTouchTarget`.
    func ncMinimumTouchTarget() -> some View {
        frame(minWidth: AppConstants.minimumTouchTarget, minHeight: AppConstants.minimumTouchTarget)
    }

    /// - Description: Frosted, elevated panel with gradient wash and border — use after padding on content. Decorative layers do not absorb touches.
    func ncStudioElevatedSurface(cornerRadius: CGFloat = 18) -> some View {
        background {
            NCLiquidGlassChrome.cardBackground(cornerRadius: cornerRadius)
                .shadow(color: Color.black.opacity(0.09), radius: 14, x: 0, y: 8)
        }
        .overlay {
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [Color.ncGlowBlue.opacity(0.14), Color.ncGlowViolet.opacity(0.12), Color.clear],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .allowsHitTesting(false)
        }
        .overlay {
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .stroke(
                    LinearGradient(
                        colors: [
                            Color.ncGlassHighlight(lightOpacity: 0.95),
                            Color.ncGlowBlue.opacity(0.52),
                            Color.ncGlowViolet.opacity(0.42)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 2
                )
                .allowsHitTesting(false)
        }
    }

    /// - Description: Pastel-tinted card with gradient rim (diary log tiles, chips).
    func ncStudioTintedCard(tint: Color, cornerRadius: CGFloat = 14) -> some View {
        background {
            ZStack {
                NCLiquidGlassChrome.cardBackground(cornerRadius: cornerRadius)
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(tint.opacity(0.2))
            }
            .shadow(color: tint.opacity(0.18), radius: 10, x: 0, y: 5)
        }
        .overlay {
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .stroke(
                    LinearGradient(
                        colors: [
                            Color.ncGlassHighlight(lightOpacity: 0.9),
                            tint.opacity(0.72),
                            Color.ncGlowBlue.opacity(0.38)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 2
                )
                .allowsHitTesting(false)
        }
    }

    /// - Description: Diary timeline tile: soft type tint, **type-coloured outline** (readable on light bg), light shadow.
    func ncDiaryTimelineCard(tint: Color, cornerRadius: CGFloat = 14) -> some View {
        background {
            ZStack {
                NCLiquidGlassChrome.cardBackground(cornerRadius: cornerRadius)
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(tint.opacity(0.11))
            }
        }
        .overlay {
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .strokeBorder(
                    LinearGradient(
                        colors: [
                            tint.opacity(0.55),
                            tint.opacity(0.32),
                            Color.primary.opacity(0.14)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 2
                )
                .allowsHitTesting(false)
        }
        .shadow(color: Color.black.opacity(0.06), radius: 8, x: 0, y: 3)
    }

    /// - Description: Soft screen backdrop: solid background plus a short top gradient (pair with `scrollContentBackground(.hidden)` on lists when needed).
    func ncStudioScreenBackdrop() -> some View {
        background {
            ZStack(alignment: .top) {
                Color.ncBackground
                LinearGradient(
                    colors: [Color.ncGlowBlue.opacity(0.22), Color.ncGlowViolet.opacity(0.18), Color.clear],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(height: 320)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                .allowsHitTesting(false)
            }
            .ignoresSafeArea()
        }
    }
}

// MARK: - Keyworker shell layout

private struct UsesFloatingTabBarShellKey: EnvironmentKey {
    static let defaultValue = false
}

extension EnvironmentValues {
    /// - Description: True when the view is under `KeyworkerDashboardView` with the custom floating tab bar (`safeAreaInset`).
    var usesFloatingTabBarShell: Bool {
        get { self[UsesFloatingTabBarShellKey.self] }
        set { self[UsesFloatingTabBarShellKey.self] = newValue }
    }
}

/// - Description: Lightweight haptic feedback helpers used on primary actions.
enum NCHaptics {
    /// - Description: Light impact for standard button taps.
    static func impactLight() {
        #if targetEnvironment(simulator)
        return
        #else
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.prepare()
        generator.impactOccurred()
        #endif
    }

    /// - Description: Success notification feedback for completed workflows.
    static func success() {
        #if targetEnvironment(simulator)
        return
        #else
        let generator = UINotificationFeedbackGenerator()
        generator.prepare()
        generator.notificationOccurred(.success)
        #endif
    }
}
