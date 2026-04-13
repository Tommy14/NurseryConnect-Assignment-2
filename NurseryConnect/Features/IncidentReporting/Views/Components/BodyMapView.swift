//
//  BodyMapView.swift
//  NurseryConnect
//
//  Feature: Incident Reporting
//  Role: Keyworker
//  Created: 7 April 2026
//  Description: Front/back body silhouette with tap-to-place injury markers.
//
// -----------------------------------------------------------------
// Date       Name        What has done
// -----------------------------------------------------------------
// 070426     Tommy1914   Created the file with Path silhouettes and normalised taps.
// 120426     Tommy1914   Keep Front/Back picker enabled when read-only; only taps/clear respect `isInteractive`.
// 120426     Tommy1914   Asset catalog body illustrations (front/back) instead of vector shapes.
// 120426     Tommy1914   Taller map area (400pt) for easier tapping and visibility.
// 120426     Tommy1914   `scaledToFill` so wide assets fill the tile (no letterboxing).
// -----------------------------------------------------------------

import SwiftUI

/// Vertical space reserved for the body illustration and markers.
private let bodyMapAreaHeight: CGFloat = 420

/// - Description: Interactive or read-only body map for marking injury locations.
struct BodyMapView: View {
    var isInteractive: Bool
    @Binding var annotations: [BodyMapAnnotation]
    @Binding var side: BodyMapSide

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Picker("Body side", selection: $side) {
                Text("Front").tag(BodyMapSide.front)
                Text("Back").tag(BodyMapSide.back)
            }
            .pickerStyle(.segmented)

            GeometryReader { geo in
                let w = geo.size.width
                let h = geo.size.height
                ZStack {
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(Color.ncPrimary.opacity(0.06))
                        .allowsHitTesting(false)

                    Image(bodyAssetName)
                        .resizable()
                        .scaledToFill()
                        .frame(width: w, height: h)
                        .clipped()
                        .accessibilityHidden(true)

                    ForEach(displayAnnotations) { marker in
                        Circle()
                            .fill(Color.ncDanger)
                            .frame(width: 14, height: 14)
                            .overlay(Circle().stroke(Color.white.opacity(0.45), lineWidth: 1))
                            .position(x: marker.normalizedX * w, y: marker.normalizedY * h)
                    }
                }
                .frame(width: w, height: h)
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(Color.ncPrimary.opacity(0.12), lineWidth: 1)
                        .allowsHitTesting(false)
                }
                .contentShape(Rectangle())
                .onTapGesture { location in
                    guard isInteractive else { return }
                    let nx = Double(location.x / max(w, 1))
                    let ny = Double(location.y / max(h, 1))
                    annotations.append(BodyMapAnnotation(side: side, normalizedX: nx, normalizedY: ny))
                    NCHaptics.impactLight()
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: bodyMapAreaHeight)

            if isInteractive {
                Button("Clear all markers") {
                    annotations.removeAll()
                }
                .buttonStyle(.borderless)
            }
        }
    }

    private var bodyAssetName: String {
        side == .front ? "BodyMapFront" : "BodyMapBack"
    }

    private var displayAnnotations: [BodyMapAnnotation] {
        annotations.filter { $0.side == side }
    }
}

#Preview {
    struct PreviewHolder: View {
        @State private var annotations: [BodyMapAnnotation] = []
        @State private var side: BodyMapSide = .front
        var body: some View {
            BodyMapView(isInteractive: true, annotations: $annotations, side: $side)
                .padding()
        }
    }
    return PreviewHolder()
}
