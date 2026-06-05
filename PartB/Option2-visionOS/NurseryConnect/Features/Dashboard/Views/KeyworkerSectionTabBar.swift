//
//  KeyworkerSectionTabBar.swift
//  NurseryConnect
//
//  Feature: Dashboard
//  Role: Keyworker
//  Created: 16 April 2026
//  Description: Floating pill bar switching Children / Incidents. Frosted shell uses `Material` so labels stay sharp.
// 150426     Tommy1914   Reference-style: light glass track, inner selection capsule (lavender / amber), no drag scrub.
// 150426     Tommy1914   `onReselectTab` when the user taps an already-selected segment (pop-to-root hooks).
// 160426     Tommy1914   Dock track + rim: neutral glass only (no blue wash from glow/primary).
// 160426     Tommy1914   iOS 26+: Liquid Glass `glassEffect` on dock + selection pill (icons/labels above).
// 160426     Tommy1914   Selected segment: white icon + label on tinted pill for contrast.
// 210426     Tommy1914   Drag-scrub between tabs (touch-hold + drag) updates section selection and glass lens transition.
//

import SwiftUI

/// - Description: Bottom shell control switching between keyworker root sections; preserves accessibility IDs for UI tests.
struct KeyworkerSectionTabBar: View {
    @Binding var selectedIndex: Int
    @State private var dragPillX: CGFloat?
    /// - Description: Invoked when the user taps a segment that is already selected (e.g. Children again to pop `NavigationStack` to root).
    var onReselectTab: ((Int) -> Void)? = nil

    /// - Description: Full height of the outer pill track (stroke + material).
    private let dockBarHeight: CGFloat = 64
    /// - Description: Equal inset from the outer bar outline to the inner selection pill on every side.
    private let trackMargin: CGFloat = 8
    private let innerSegmentGutter: CGFloat = 8

    /// - Description: Single brand accent used across all tabs — consistent with app-wide tint.
    private let tabAccent = Color.ncPrimary

    private let segmentCount = 3

    var body: some View {
        GeometryReader { outer in
            let compactWidth = min(288, max(0, outer.size.width - 40))
            HStack {
                Spacer(minLength: 0)
                dockChrome(width: compactWidth)
                Spacer(minLength: 0)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
        }
        .frame(height: dockBarHeight)
        .padding(.horizontal, 16)
        .padding(.bottom, 16)
    }

    private func dockChrome(width: CGFloat) -> some View {
        let outerRadius = dockBarHeight / 2
        let innerW = width - trackMargin * 2
        let gutterTotal = innerSegmentGutter * CGFloat(segmentCount - 1)
        let segmentW = (innerW - gutterTotal) / CGFloat(segmentCount)
        let segmentStride = segmentW + innerSegmentGutter
        let pillHeight = dockBarHeight - trackMargin * 2
        let pillWidth = segmentW
        let pillCorner = pillHeight / 2
        let restingPillX = trackMargin + CGFloat(selectedIndex) * segmentStride
        let minPillX = trackMargin
        let maxPillX = trackMargin + CGFloat(segmentCount - 1) * segmentStride
        let displayedPillX = clampedPillX(dragPillX ?? restingPillX, minX: minPillX, maxX: maxPillX)
        let visualIndex = indexForPillX(displayedPillX, firstSlotX: trackMargin, segmentStride: segmentStride)

        return ZStack(alignment: .topLeading) {
            dockTrackFill(outerRadius: outerRadius)

            selectionPill(
                width: pillWidth,
                height: pillHeight,
                corner: pillCorner,
                visualIndex: visualIndex
            )
            .offset(x: displayedPillX, y: trackMargin)
            .animation(dragPillX == nil ? .spring(response: 0.4, dampingFraction: 0.84) : .linear(duration: 0.06), value: displayedPillX)

            HStack {
                Spacer(minLength: 0)
                HStack(spacing: innerSegmentGutter) {
                    segmentButton(
                        title: "Children",
                        systemImage: "figure.child",
                        index: 0,
                        accessibilityID: AppConstants.AccessibilityID.myChildrenTab,
                        segmentWidth: segmentW,
                        height: dockBarHeight,
                        visualIndex: visualIndex
                    )
                    segmentButton(
                        title: "Incidents",
                        systemImage: "exclamationmark.triangle.fill",
                        index: 1,
                        accessibilityID: AppConstants.AccessibilityID.incidentsTab,
                        segmentWidth: segmentW,
                        height: dockBarHeight,
                        visualIndex: visualIndex
                    )
                    messagesSegmentButton(
                        segmentWidth: segmentW,
                        height: dockBarHeight,
                        visualIndex: visualIndex
                    )
                }
                .frame(width: innerW)
                Spacer(minLength: 0)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            RoundedRectangle(cornerRadius: outerRadius, style: .continuous)
                .strokeBorder(
                    LinearGradient(
                        colors: [
                            Color.ncGlassHighlight(lightOpacity: 0.55),
                            Color.ncGlassHighlight(lightOpacity: 0.12),
                            Color.ncGlassHighlight(lightOpacity: 0.08)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
                .allowsHitTesting(false)
        }
        .frame(width: width, height: dockBarHeight)
        .shadow(color: Color.black.opacity(0.1), radius: 14, x: 0, y: 8)
        .shadow(color: Color.black.opacity(0.04), radius: 4, x: 0, y: 2)
        .contentShape(RoundedRectangle(cornerRadius: outerRadius, style: .continuous))
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { value in
                    let targetPillX = clampedPillX(
                        value.location.x - (pillWidth / 2),
                        minX: minPillX,
                        maxX: maxPillX
                    )
                    dragPillX = targetPillX

                    let targetIndex = indexForPillX(targetPillX, firstSlotX: trackMargin, segmentStride: segmentStride)
                    if targetIndex != selectedIndex {
                        selectedIndex = targetIndex
                    }
                }
                .onEnded { value in
                    let finalPillX = clampedPillX(
                        value.location.x - (pillWidth / 2),
                        minX: minPillX,
                        maxX: maxPillX
                    )
                    let finalIndex = indexForPillX(finalPillX, firstSlotX: trackMargin, segmentStride: segmentStride)
                    withAnimation(.spring(response: 0.38, dampingFraction: 0.84)) {
                        selectedIndex = finalIndex
                        dragPillX = nil
                    }
                }
        )
    }

    /// - Description: Outer dock — Liquid Glass on iOS 26+; `Material` + tint wash on older OS (labels sit above this layer).
    @ViewBuilder
    private func dockTrackFill(outerRadius: CGFloat) -> some View {
        let shape = RoundedRectangle(cornerRadius: outerRadius, style: .continuous)
        if #available(iOS 26.0, *) {
            ZStack {
                shape
                    .fill(Color.clear)
                    .glassEffect(
                        Glass.clear
                            .tint(Color.ncGlowBlue.opacity(0.2))
                            .interactive(),
                        in: shape
                    )
                shape
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.ncGlassHighlight(lightOpacity: 0.38),
                                Color.ncGlowViolet.opacity(0.06)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }
        } else {
            shape
                .fill(.ultraThinMaterial)
                .overlay {
                    shape
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color.ncGlassHighlight(lightOpacity: 0.42),
                                    Color.ncGlassHighlight(lightOpacity: 0.10)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                }
        }
    }

    @ViewBuilder
    private func selectionPill(width: CGFloat, height: CGFloat, corner: CGFloat, visualIndex: Int) -> some View {
        let shape = RoundedRectangle(cornerRadius: corner, style: .continuous)
        let accent = accentColor(for: visualIndex)
        if #available(iOS 26.0, *) {
            ZStack {
                shape
                    .fill(Color.clear)
                    .frame(width: width, height: height)
                    .glassEffect(
                        Glass.clear
                            .tint(accent.opacity(0.48))
                            .interactive(),
                        in: shape
                    )
                shape
                    .fill(
                        LinearGradient(
                            colors: [
                                accent.opacity(0.18),
                                accent.opacity(0.06)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .allowsHitTesting(false)
                shape
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.ncGlassHighlight(lightOpacity: 0.28),
                                Color.ncGlassHighlight(lightOpacity: 0.04)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .allowsHitTesting(false)
                shape
                    .strokeBorder(Color.ncAdaptiveHairlineStroke, lineWidth: 1.35)
                    .allowsHitTesting(false)
            }
            .frame(width: width, height: height)
        } else {
            shape
                .fill(
                    LinearGradient(
                        colors: [
                            accent.opacity(0.48),
                            accent.opacity(0.28)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay {
                    shape
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color.ncGlassHighlight(lightOpacity: 0.22),
                                    Color.ncGlassHighlight(lightOpacity: 0.05)
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .allowsHitTesting(false)
                }
                .overlay {
                    shape
                        .strokeBorder(Color.ncAdaptiveHairlineStroke, lineWidth: 1.35)
                        .allowsHitTesting(false)
                }
                .frame(width: width, height: height)
        }
    }

    private func segmentButton(
        title: String,
        systemImage: String,
        index: Int,
        accessibilityID: String,
        segmentWidth: CGFloat,
        height: CGFloat,
        visualIndex: Int
    ) -> some View {
        let selected = visualIndex == index
        return Button {
            if selectedIndex == index {
                onReselectTab?(index)
            } else {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.84)) {
                    selectedIndex = index
                }
            }
        } label: {
            VStack(spacing: 4) {
                Image(systemName: systemImage)
                    .font(.system(size: 20, weight: selected ? .semibold : .medium))
                    .symbolRenderingMode(.monochrome)
                Text(title)
                    .font(.caption2.weight(selected ? .semibold : .medium))
            }
            .multilineTextAlignment(.center)
            .frame(width: segmentWidth, height: height, alignment: .center)
            .foregroundStyle(segmentForeground(selected: selected))
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(title)
        .accessibilityAddTraits(selected ? [.isSelected] : [])
        .accessibilityIdentifier(accessibilityID)
    }

    private func segmentForeground(selected: Bool) -> AnyShapeStyle {
        if selected {
            return AnyShapeStyle(Color.white)
        }
        return AnyShapeStyle(Color.primary.opacity(0.78))
    }

    private func messagesSegmentButton(segmentWidth: CGFloat, height: CGFloat, visualIndex: Int) -> some View {
        let selected = visualIndex == 2
        return Button {
            if selectedIndex == 2 {
                onReselectTab?(2)
            } else {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.84)) {
                    selectedIndex = 2
                }
            }
        } label: {
            ZStack(alignment: .topTrailing) {
                VStack(spacing: 4) {
                    Image(systemName: "bubble.left.and.bubble.right.fill")
                        .font(.system(size: 20, weight: selected ? .semibold : .medium))
                    Text("Messages")
                        .font(.caption2.weight(selected ? .semibold : .medium))
                }
                .multilineTextAlignment(.center)
                .frame(width: segmentWidth, height: height, alignment: .center)
                .foregroundStyle(segmentForeground(selected: selected))

                UnreadBadge()
                    .offset(x: 4, y: 2)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Messages")
        .accessibilityAddTraits(selected ? [.isSelected] : [])
        .accessibilityIdentifier(AppConstants.AccessibilityID.messagesTab)
    }

    private func accentColor(for index: Int) -> Color { tabAccent }

    /// - Description: Maps pill offset to nearest section index.
    private func indexForPillX(_ pillX: CGFloat, firstSlotX: CGFloat, segmentStride: CGFloat) -> Int {
        let relative = pillX - firstSlotX + (segmentStride / 2)
        let raw = Int(relative / segmentStride)
        return min(max(raw, 0), segmentCount - 1)
    }

    /// - Description: Keeps the moving lens inside the segment track.
    private func clampedPillX(_ x: CGFloat, minX: CGFloat, maxX: CGFloat) -> CGFloat {
        min(max(x, minX), maxX)
    }
}

#Preview {
    struct PreviewHost: View {
        @State private var tab = 0
        var body: some View {
            ZStack {
                Color.ncBackground.ignoresSafeArea()
                VStack {
                    Spacer()
                    KeyworkerSectionTabBar(selectedIndex: $tab)
                }
            }
        }
    }
    return PreviewHost()
}
