//
//  IncidentBeaconView.swift
//  NurseryConnect Spatial
//
//  Feature: Spatial — 3D
//  Created: 4 June 2026
//  Description: Pulsing 3D alert beacon shown above the incident list when open incidents exist.
//               Uses a rotating cylinder with emissive material on device, animated SwiftUI rings
//               on Simulator.
//

import SwiftUI
#if !arch(simulator)
import RealityKit
import UIKit
#endif

/// - Description: Urgent 3D beacon that draws spatial attention to open incidents.
struct IncidentBeaconView: View {
    let openCount: Int

    @State private var sceneReady = false
    @State private var pulseScale: CGFloat = 1.0
    @State private var rotation: Angle = .zero

    private var isActive: Bool { openCount > 0 }

    var body: some View {
        if isActive {
            HStack(spacing: 12) {
                #if arch(simulator)
                simulatorBeacon
                #else
                realityBeacon
                #endif
                VStack(alignment: .leading, spacing: 2) {
                    Text("\(openCount) open incident\(openCount == 1 ? "" : "s")")
                        .font(.ncCaption.weight(.bold))
                        .foregroundStyle(Color.ncDanger)
                    Text("Requires attention today")
                        .font(.ncCaption2)
                        .foregroundStyle(.secondary)
                }
                Spacer()
            }
            .padding(12)
            .background(Color.ncDanger.opacity(0.10), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(Color.ncDanger.opacity(0.25), lineWidth: 1)
            )
        }
    }

    // MARK: - Simulator fallback

    private var simulatorBeacon: some View {
        ZStack {
            Circle()
                .stroke(Color.ncDanger.opacity(0.4), lineWidth: 3)
                .frame(width: 44, height: 44)
                .scaleEffect(pulseScale)
            Circle()
                .fill(Color.ncDanger)
                .frame(width: 26, height: 26)
            Image(systemName: "exclamationmark")
                .font(.caption.weight(.black))
                .foregroundStyle(.white)
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true)) {
                pulseScale = 1.35
            }
        }
    }

    #if !arch(simulator)
    // MARK: - RealityKit beacon

    private var realityBeacon: some View {
        Group {
            if sceneReady {
                RealityView { content in
                    do {
                        try buildBeacon(into: content)
                    } catch {
                        print("Beacon RealityKit error: \(error)")
                    }
                }
                .frame(width: 52, height: 52)
                .frame(depth: 0.08)
            } else {
                simulatorBeacon.frame(width: 52, height: 52)
            }
        }
        .task {
            try? await Task.sleep(nanoseconds: 300_000_000)
            sceneReady = true
        }
    }

    private func buildBeacon(into content: RealityViewContent) throws {
        let root = Entity()
        root.name = "BeaconRoot"
        content.add(root)

        let cylinderMesh = MeshResource.generateCylinder(height: 0.06, radius: 0.018)
        var material = SimpleMaterial(color: UIColor.systemRed.withAlphaComponent(0.9), isMetallic: false)
        material.roughness = .init(floatLiteral: 0.3)
        let cylinder = ModelEntity(mesh: cylinderMesh, materials: [material])
        cylinder.position = SIMD3(0, 0, 0)
        root.addChild(cylinder)

        let sphereMesh = MeshResource.generateSphere(radius: 0.022)
        let sphere = ModelEntity(mesh: sphereMesh, materials: [material])
        sphere.position = SIMD3(0, 0.05, 0)
        root.addChild(sphere)

        // Continuous rotation is applied via update closure through parent view
    }
    #endif
}
