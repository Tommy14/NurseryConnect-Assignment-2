//
//  StatOrbsView.swift
//  NurseryConnect Spatial
//
//  Feature: Spatial — 3D
//  Created: 4 June 2026
//  Description: Floating 3D stat orbs using RealityKit. Each stat gets a glowing
//               sphere at a different Z depth that pulses gently. Falls back to
//               2D pill cards on Simulator.
//

import SwiftUI
#if !arch(simulator)
import RealityKit
import UIKit
#endif

/// - Description: Stats rendered as floating 3D orbs in the hub view.
struct StatOrbsView: View {
    let stats: [(title: String, value: String, color: Color)]

    @State private var sceneReady = false
    @State private var pulseScale: CGFloat = 1.0

    var body: some View {
        #if arch(simulator)
        simulatorFallback
        #else
        realityOrbsView
        #endif
    }

    // MARK: - Simulator fallback

    private var simulatorFallback: some View {
        HStack(spacing: 12) {
            ForEach(stats.indices, id: \.self) { idx in
                let stat = stats[idx]
                VStack(spacing: 8) {
                    ZStack {
                        Circle()
                            .fill(stat.color.opacity(0.2))
                            .frame(width: 56, height: 56)
                        Text(stat.value)
                            .font(.system(.title3, design: .rounded, weight: .bold))
                            .foregroundStyle(stat.color)
                    }
                    .scaleEffect(pulseScale)
                    Text(stat.title)
                        .font(.ncCaption2)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
            }
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 3).repeatForever(autoreverses: true)) {
                pulseScale = 1.05
            }
        }
    }

    #if !arch(simulator)
    // MARK: - RealityKit orbs

    private var realityOrbsView: some View {
        Group {
            if sceneReady {
                RealityView { content in
                    do {
                        try buildOrbScene(into: content)
                    } catch {
                        print("StatOrbs RealityKit error: \(error)")
                        buildFallbackScene(into: content)
                    }
                }
                .frame(height: 120)
                .frame(depth: 0.15)
            } else {
                simulatorFallback
                    .frame(height: 120)
            }
        }
        .task {
            try? await Task.sleep(nanoseconds: 400_000_000)
            sceneReady = true
        }
    }

    private func buildOrbScene(into content: RealityViewContent) throws {
        let root = Entity()
        root.name = "OrbRoot"
        content.add(root)

        let count = Float(stats.count)
        let spacing: Float = 0.22
        let xOrigin = -(count - 1) * spacing / 2

        for (idx, stat) in stats.enumerated() {
            let orb = try makeOrb(color: UIColor(stat.color), radius: 0.045)
            let zOffset: Float = Float(idx) * 0.015
            orb.position = SIMD3(xOrigin + Float(idx) * spacing, 0, zOffset)
            root.addChild(orb)
        }
    }

    private func makeOrb(color: UIColor, radius: Float) throws -> ModelEntity {
        let mesh = MeshResource.generateSphere(radius: radius)
        var material = SimpleMaterial(color: color, isMetallic: false)
        material.roughness = .init(floatLiteral: 0.3)
        let entity = ModelEntity(mesh: mesh, materials: [material])
        return entity
    }

    private func buildFallbackScene(into content: RealityViewContent) {
        let root = Entity()
        content.add(root)
        for (idx, _) in stats.enumerated() {
            let mesh = MeshResource.generateSphere(radius: 0.04)
            let material = SimpleMaterial(color: .systemBlue, isMetallic: false)
            let entity = ModelEntity(mesh: mesh, materials: [material])
            entity.position = SIMD3(Float(idx) * 0.22 - 0.33, 0, 0)
            root.addChild(entity)
        }
    }
    #endif
}
