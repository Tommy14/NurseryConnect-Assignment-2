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
// -----------------------------------------------------------------

import SwiftUI

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
            .disabled(!isInteractive)

            GeometryReader { geo in
                ZStack {
                    BodySilhouetteShape(side: side)
                        .stroke(Color.primary.opacity(0.35), lineWidth: 2)
                        .background(
                            BodySilhouetteShape(side: side)
                                .fill(Color.ncPrimary.opacity(0.06))
                        )

                    ForEach(displayAnnotations, id: \.self) { marker in
                        Circle()
                            .fill(Color.ncDanger)
                            .frame(width: 12, height: 12)
                            .position(x: marker.normalizedX * geo.size.width,
                                      y: marker.normalizedY * geo.size.height)
                    }
                }
                .contentShape(Rectangle())
                .onTapGesture { location in
                    guard isInteractive else { return }
                    let nx = Double(location.x / max(geo.size.width, 1))
                    let ny = Double(location.y / max(geo.size.height, 1))
                    annotations.append(BodyMapAnnotation(side: side, normalizedX: nx, normalizedY: ny))
                    NCHaptics.impactLight()
                }
            }
            .frame(height: 320)

            if isInteractive {
                Button("Clear all markers") {
                    annotations.removeAll { $0.side == side }
                }
                .buttonStyle(.borderless)
            }
        }
    }

    private var displayAnnotations: [BodyMapAnnotation] {
        annotations.filter { $0.side == side }
    }
}

/// - Description: Simple child silhouette used for annotation scaling (not anatomically exact).
private struct BodySilhouetteShape: Shape {
    let side: BodyMapSide

    func path(in rect: CGRect) -> Path {
        var path = Path()
        let w = rect.width
        let h = rect.height
        let head = CGRect(x: w * 0.38, y: h * 0.05, width: w * 0.24, height: h * 0.14)
        path.addEllipse(in: head)

        let torso = CGRect(x: w * 0.30, y: h * 0.20, width: w * 0.40, height: h * 0.38)
        path.addRoundedRect(in: torso, cornerSize: CGSize(width: 18, height: 18))

        let armLeft = CGRect(x: w * 0.12, y: h * 0.22, width: w * 0.18, height: h * 0.10)
        let armRight = CGRect(x: w * 0.70, y: h * 0.22, width: w * 0.18, height: h * 0.10)
        path.addRoundedRect(in: armLeft, cornerSize: CGSize(width: 10, height: 10))
        path.addRoundedRect(in: armRight, cornerSize: CGSize(width: 10, height: 10))

        let legLeft = CGRect(x: w * 0.34, y: h * 0.56, width: w * 0.12, height: h * 0.32)
        let legRight = CGRect(x: w * 0.54, y: h * 0.56, width: w * 0.12, height: h * 0.32)
        path.addRoundedRect(in: legLeft, cornerSize: CGSize(width: 10, height: 10))
        path.addRoundedRect(in: legRight, cornerSize: CGSize(width: 10, height: 10))

        if side == .back {
            path.move(to: CGPoint(x: w * 0.42, y: h * 0.12))
            path.addLine(to: CGPoint(x: w * 0.58, y: h * 0.12))
        }

        return path
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
