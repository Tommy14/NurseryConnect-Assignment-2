//
//  KeyworkerIPadBottomDock.swift
//  NurseryConnect
//
//  Feature: Dashboard
//  Role: Keyworker
//  Created: 29 May 2026
//  Description: Centered liquid-glass bottom dock for Incidents and Messages on iPad.
//

import SwiftUI

/// - Description: Floating bottom navigation for the iPad keyworker shell (Incidents + Messages only).
struct KeyworkerIPadBottomDock: View {
    @Binding var section: KeyworkerIPadSection

    private let dockBarHeight: CGFloat = 64
    private let trackMargin: CGFloat = 6
    private let innerSegmentGutter: CGFloat = 6

    private let incidentsAccent = Color(red: 0.92, green: 0.52, blue: 0.14)
    private let messagesAccent = Color(red: 0.2, green: 0.65, blue: 0.62)

    private var selectedSlot: Int? {
        switch section {
        case .incidents: return 0
        case .messages: return 1
        case .children: return nil
        }
    }

    var body: some View {
        GeometryReader { outer in
            let compactWidth = min(236, max(0, outer.size.width - 48))
            HStack {
                Spacer(minLength: 0)
                dockChrome(width: compactWidth)
                Spacer(minLength: 0)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
        }
        .frame(height: dockBarHeight)
        .padding(.horizontal, 20)
        .padding(.bottom, 18)
    }

    private func dockChrome(width: CGFloat) -> some View {
        let outerRadius = dockBarHeight / 2
        let innerW = width - trackMargin * 2
        let segmentW = (innerW - innerSegmentGutter) / 2
        let pillHeight = dockBarHeight - trackMargin * 2
        let pillCorner = pillHeight / 2

        return ZStack {
            dockTrackFill(outerRadius: outerRadius)

            segmentTrack(
                segmentWidth: segmentW,
                pillHeight: pillHeight,
                pillCorner: pillCorner
            )

            segmentTrack(
                segmentWidth: segmentW,
                pillHeight: pillHeight,
                pillCorner: pillCorner,
                showsButtons: true
            )

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
        .clipShape(RoundedRectangle(cornerRadius: outerRadius, style: .continuous))
        .shadow(color: Color.black.opacity(0.1), radius: 14, x: 0, y: 8)
        .shadow(color: Color.black.opacity(0.04), radius: 4, x: 0, y: 2)
        .contentShape(RoundedRectangle(cornerRadius: outerRadius, style: .continuous))
    }

    @ViewBuilder
    private func segmentTrack(
        segmentWidth: CGFloat,
        pillHeight: CGFloat,
        pillCorner: CGFloat,
        showsButtons: Bool = false
    ) -> some View {
        HStack(spacing: innerSegmentGutter) {
            segmentCell(
                index: 0,
                title: "Incidents",
                systemImage: "exclamationmark.triangle.fill",
                targetSection: .incidents,
                accessibilityID: AppConstants.AccessibilityID.incidentsTab,
                segmentWidth: segmentWidth,
                pillHeight: pillHeight,
                pillCorner: pillCorner,
                showsButtons: showsButtons
            )
            segmentCell(
                index: 1,
                title: "Messages",
                systemImage: "bubble.left.and.bubble.right.fill",
                targetSection: .messages,
                accessibilityID: AppConstants.AccessibilityID.messagesTab,
                segmentWidth: segmentWidth,
                pillHeight: pillHeight,
                pillCorner: pillCorner,
                showsButtons: showsButtons,
                showsUnreadBadge: true
            )
        }
        .padding(.horizontal, trackMargin)
        .padding(.vertical, trackMargin)
        .animation(.spring(response: 0.4, dampingFraction: 0.84), value: selectedSlot)
    }

    @ViewBuilder
    private func segmentCell(
        index: Int,
        title: String,
        systemImage: String,
        targetSection: KeyworkerIPadSection,
        accessibilityID: String,
        segmentWidth: CGFloat,
        pillHeight: CGFloat,
        pillCorner: CGFloat,
        showsButtons: Bool,
        showsUnreadBadge: Bool = false
    ) -> some View {
        let isSelected = section == targetSection

        ZStack {
            if !showsButtons, selectedSlot == index {
                selectionPill(
                    width: segmentWidth,
                    height: pillHeight,
                    corner: pillCorner,
                    accent: accentColor(for: index)
                )
            }

            if showsButtons {
                Button {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.84)) {
                        section = targetSection
                    }
                } label: {
                    segmentLabel(
                        title: title,
                        systemImage: systemImage,
                        isSelected: isSelected,
                        segmentWidth: segmentWidth,
                        pillHeight: pillHeight,
                        showsUnreadBadge: showsUnreadBadge
                    )
                }
                .buttonStyle(.plain)
                .accessibilityLabel(title)
                .accessibilityAddTraits(isSelected ? [.isButton, .isSelected] : .isButton)
                .accessibilityIdentifier(accessibilityID)
            }
        }
        .frame(width: segmentWidth, height: pillHeight)
    }

    private func segmentLabel(
        title: String,
        systemImage: String,
        isSelected: Bool,
        segmentWidth: CGFloat,
        pillHeight: CGFloat,
        showsUnreadBadge: Bool
    ) -> some View {
        ZStack(alignment: .topTrailing) {
            VStack(spacing: 3) {
                Image(systemName: systemImage)
                    .font(.system(size: 19, weight: isSelected ? .semibold : .medium))
                    .symbolRenderingMode(.monochrome)
                Text(title)
                    .font(.caption2.weight(isSelected ? .semibold : .medium))
                    .lineLimit(1)
                    .minimumScaleFactor(0.85)
            }
            .multilineTextAlignment(.center)
            .foregroundStyle(segmentForeground(selected: isSelected))
            .padding(.horizontal, 4)
            .padding(.vertical, 2)
            .frame(width: segmentWidth, height: pillHeight, alignment: .center)

            if showsUnreadBadge {
                UnreadBadge()
                    .padding(.top, 1)
                    .padding(.trailing, 6)
            }
        }
        .frame(width: segmentWidth, height: pillHeight)
        .contentShape(Rectangle())
    }

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
    private func selectionPill(width: CGFloat, height: CGFloat, corner: CGFloat, accent: Color) -> some View {
        let shape = RoundedRectangle(cornerRadius: corner, style: .continuous)
        if #available(iOS 26.0, *) {
            ZStack {
                shape
                    .fill(Color.clear)
                    .glassEffect(
                        Glass.clear
                            .tint(accent.opacity(0.48))
                            .interactive(),
                        in: shape
                    )
                shape
                    .fill(
                        LinearGradient(
                            colors: [accent.opacity(0.18), accent.opacity(0.06)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .allowsHitTesting(false)
                shape
                    .strokeBorder(Color.ncAdaptiveHairlineStroke, lineWidth: 1)
                    .allowsHitTesting(false)
            }
            .frame(width: width, height: height)
            .clipShape(shape)
        } else {
            shape
                .fill(
                    LinearGradient(
                        colors: [accent.opacity(0.48), accent.opacity(0.28)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay {
                    shape
                        .strokeBorder(Color.ncAdaptiveHairlineStroke, lineWidth: 1)
                        .allowsHitTesting(false)
                }
                .frame(width: width, height: height)
                .clipShape(shape)
        }
    }

    private func segmentForeground(selected: Bool) -> AnyShapeStyle {
        if selected {
            return AnyShapeStyle(Color.white)
        }
        return AnyShapeStyle(Color.primary.opacity(0.78))
    }

    private func accentColor(for index: Int) -> Color {
        index == 0 ? incidentsAccent : messagesAccent
    }
}
