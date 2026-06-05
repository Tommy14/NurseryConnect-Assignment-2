//
//  NCSpatialWindowChrome.swift
//  NurseryConnect
//
//  Feature: Shared UI
//  Created: 4 June 2026
//  Description: iOS-style continuous corner glass for visionOS plain windows.
//

import SwiftUI

#if os(visionOS)
extension View {
    /// - Description: Clips window content and applies system glass with iOS-like continuous corners (use with `.windowStyle(.plain)`).
    func ncSpatialWindowChrome(
        cornerRadius: CGFloat = AppConstants.spatialWindowCornerRadius
    ) -> some View {
        let shape = RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
        return frame(maxWidth: .infinity, maxHeight: .infinity)
            .clipShape(shape)
            .glassBackgroundEffect(in: shape)
    }
}
#endif
