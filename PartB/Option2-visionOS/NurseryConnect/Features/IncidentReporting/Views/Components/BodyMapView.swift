//
//  BodyMapView.swift
//  NurseryConnect
//
//  Feature: Incident Reporting
//  Role: Keyworker
//  Created: 7 April 2026
//  Description: Front/back body silhouette with tap-to-place injury markers.
//

import SwiftUI
import UIKit

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
                let fittedSize = fittedBodySize(in: geo.size, assetName: bodyAssetName)

                ZStack {
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(Color.ncPrimary.opacity(0.06))
                        .allowsHitTesting(false)

                    bodyIllustration(size: fittedSize)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
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

    private func bodyIllustration(size: CGSize) -> some View {
        Image(bodyAssetName)
            .resizable()
            .scaledToFit()
            .frame(width: size.width, height: size.height)
            .overlay {
                ForEach(displayAnnotations) { marker in
                    Circle()
                        .fill(Color.ncDanger)
                        .frame(width: 14, height: 14)
                        .overlay(Circle().stroke(Color.ncGlassHighlight(lightOpacity: 0.45), lineWidth: 1))
                        .position(
                            x: marker.normalizedX * size.width,
                            y: marker.normalizedY * size.height
                        )
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(Color.ncPrimary.opacity(0.12), lineWidth: 1)
                    .allowsHitTesting(false)
            }
            .contentShape(Rectangle())
            .onTapGesture { location in
                guard isInteractive else { return }
                guard size.width > 0, size.height > 0 else { return }
                let nx = Double(location.x / size.width)
                let ny = Double(location.y / size.height)
                guard (0 ... 1).contains(nx), (0 ... 1).contains(ny) else { return }
                annotations.append(BodyMapAnnotation(side: side, normalizedX: nx, normalizedY: ny))
                NCHaptics.impactLight()
            }
            .accessibilityHidden(true)
    }

    private func fittedBodySize(in container: CGSize, assetName: String) -> CGSize {
        guard container.width > 0, container.height > 0 else { return .zero }
        guard
            let image = UIImage(named: assetName),
            image.size.width > 0,
            image.size.height > 0
        else {
            let side = min(container.width, container.height * 0.92)
            return CGSize(width: side * 0.55, height: side)
        }

        let imageAspect = image.size.width / image.size.height
        let containerAspect = container.width / container.height

        if imageAspect >= containerAspect {
            let width = container.width
            return CGSize(width: width, height: width / imageAspect)
        }

        let height = container.height
        return CGSize(width: height * imageAspect, height: height)
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
