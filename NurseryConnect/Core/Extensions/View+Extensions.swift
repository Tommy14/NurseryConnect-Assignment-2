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
            .background(Color.ncCardSurface)
            .clipShape(RoundedRectangle(cornerRadius: radius, style: .continuous))
            .shadow(color: Color.black.opacity(0.06), radius: 8, x: 0, y: 4)
    }

    /// - Description: Ensures a minimum 44pt hit target for accessibility.
    /// - Returns: View with `frame(minWidth:minHeight:)` using `AppConstants.minimumTouchTarget`.
    func ncMinimumTouchTarget() -> some View {
        frame(minWidth: AppConstants.minimumTouchTarget, minHeight: AppConstants.minimumTouchTarget)
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
