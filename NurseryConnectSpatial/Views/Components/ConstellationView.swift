//
//  ConstellationView.swift
//  NurseryConnect Spatial
//
//  Feature: Spatial — 3D
//  Created: 4 June 2026
//  Description: Child wellbeing constellation using RealityKit. Each assigned child
//               is a glowing sphere in a gentle arc. Colour maps to mood.
//               Falls back to a 2D arc on Simulator.
//

import SwiftUI
#if !arch(simulator)
import RealityKit
import UIKit
#endif

struct ConstellationEntry: Identifiable {
    let id: UUID
    let name: String
    let moodRating: Int
    let hasIncident: Bool

    var moodColor: Color {
        switch moodRating {
        case 4...5: return Color.ncSecondary
        case 3:     return Color.ncAccentWarm
        default:    return Color.ncDanger
        }
    }
}

/// - Description: Spatial arc of glowing spheres, one per child, tappable to open diary.
struct ConstellationView: View {
    let children: [ConstellationEntry]
    var onChildTapped: (ConstellationEntry) -> Void = { _ in }

    @State private var sceneReady = false
    @State private var selectedID: UUID?
    @State private var pulsePhase: CGFloat = 0

    var body: some View {
        #if arch(simulator)
        simulatorFallback
        #else
        realityConstellation
        #endif
    }

    // MARK: - Simulator fallback

    private var simulatorFallback: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 14) {
                ForEach(children) { child in
                    Button {
                        selectedID = child.id
                        onChildTapped(child)
                    } label: {
                        VStack(spacing: 6) {
                            ZStack {
                                Circle()
                                    .fill(child.moodColor.opacity(0.25))
                                    .frame(width: 40, height: 40)
                                Circle()
                                    .fill(child.moodColor)
                                    .frame(width: 22, height: 22)
                                    .scaleEffect(child.hasIncident ? 1.0 + 0.15 * sin(pulsePhase) : 1.0)
                            }
                            Text(child.name.prefix(6))
                                .font(.ncCaption2)
                                .foregroundStyle(.secondary)
                        }
                        .opacity(selectedID == nil || selectedID == child.id ? 1 : 0.5)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 8)
        }
        .onAppear {
            withAnimation(.linear(duration: 1.5).repeatForever(autoreverses: false)) {
                pulsePhase = .pi * 2
            }
        }
    }

    #if !arch(simulator)
    // MARK: - RealityKit constellation

    private var realityConstellation: some View {
        Group {
            if sceneReady {
                RealityView { content in
                    do {
                        try buildConstellation(into: content)
                    } catch {
                        print("Constellation RealityKit error: \(error)")
                    }
                }
                .frame(height: 100)
                .frame(depth: 0.12)
            } else {
                simulatorFallback.frame(height: 100)
            }
        }
        .task {
            try? await Task.sleep(nanoseconds: 350_000_000)
            sceneReady = true
        }
    }

    private func buildConstellation(into content: RealityViewContent) throws {
        let root = Entity()
        root.name = "ConstellationRoot"
        content.add(root)

        let count = children.count
        let arcAngleTotal: Float = 0.8 * Float.pi
        let arcRadius: Float = 0.28

        for (idx, child) in children.enumerated() {
            let angle = -arcAngleTotal / 2 + arcAngleTotal * Float(idx) / max(Float(count - 1), 1)
            let x = arcRadius * sin(angle)
            let y = arcRadius * (cos(angle) - 1) * 0.3
            let z = Float(idx) * 0.01

            let radius: Float = child.hasIncident ? 0.030 : 0.022
            let mesh = MeshResource.generateSphere(radius: radius)
            let uiColor = UIColor(child.moodColor)
            let material = SimpleMaterial(color: uiColor.withAlphaComponent(0.9), isMetallic: false)
            let sphere = ModelEntity(mesh: mesh, materials: [material])
            sphere.position = SIMD3(x, y, z)
            sphere.name = child.id.uuidString
            root.addChild(sphere)
        }
    }
    #endif
}
