//
//  MoodChartVolumeView.swift
//  NurseryConnect Spatial
//
//  Feature: Spatial
//  Role: Keyworker
//  Created: 30 May 2026
//  Description: Volumetric RealityKit mood trend chart for a selected child.
//

import CoreData
import SwiftUI
#if !arch(simulator)
import RealityKit
import UIKit
#endif

/// - Description: One day's mood score and label for the 3D bar chart.
private struct SevenDayMoodBarModel: Identifiable {
    let id: Int
    let label: String
    let score: Float
}

/// - Description: SwiftUI bar strip with perspective — visible in Simulator and as a 3D-style preview.
private struct MoodChartBarStripView: View {
    let bars: [SevenDayMoodBarModel]
    let rotationDegrees: Double

    private let maxBarHeight: CGFloat = 100
    private let maxScore: Float = 5
    private let welfareThreshold: Float = 2

    var body: some View {
        GeometryReader { geometry in
            let thresholdY = barTopOffset(in: geometry.size.height, score: welfareThreshold)

            ZStack(alignment: .bottomLeading) {
                Rectangle()
                    .fill(Color.red.opacity(0.9))
                    .frame(height: 2)
                    .padding(.horizontal, 14)
                    .offset(y: -thresholdY)

                HStack(alignment: .bottom, spacing: 14) {
                    ForEach(bars) { bar in
                        barColumn(bar)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
                .padding(.horizontal, 14)
                .padding(.bottom, 22)
            }
        }
        .frame(height: 150)
        .rotation3DEffect(.degrees(rotationDegrees * 0.2), axis: (x: 0, y: 1, z: 0))
        .rotation3DEffect(.degrees(20), axis: (x: 1, y: 0, z: 0))
    }

    private func barColumn(_ bar: SevenDayMoodBarModel) -> some View {
        VStack(spacing: 6) {
            RoundedRectangle(cornerRadius: 6, style: .continuous)
                .fill(barGradient(for: bar))
                .frame(width: 24, height: barHeight(for: bar.score))
                .overlay {
                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                        .stroke(Color.white.opacity(0.25), lineWidth: 0.5)
                }
            Text(bar.label)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }

    private func barHeight(for score: Float) -> CGFloat {
        let normalized = score > 0 ? CGFloat(score / maxScore) : 0.14
        return max(10, normalized * maxBarHeight)
    }

    private func barTopOffset(in totalHeight: CGFloat, score: Float) -> CGFloat {
        22 + barHeight(for: score)
    }

    private func barGradient(for bar: SevenDayMoodBarModel) -> LinearGradient {
        let base = barColor(for: bar.score)
        return LinearGradient(
            colors: [base.opacity(0.95), base.opacity(0.55)],
            startPoint: .top,
            endPoint: .bottom
        )
    }

    private func barColor(for score: Float) -> Color {
        guard score > 0 else { return Color.secondary.opacity(0.35) }
        switch score {
        case 4...5: return Color.green
        case 3..<4: return Color.orange
        default: return Color.red
        }
    }
}

/// - Description: Floating volumetric wellbeing mood chart for one child.
struct MoodChartVolumeView: View {
    let childID: UUID

    @Environment(\.managedObjectContext) private var context
    @Environment(\.dismissWindow) private var dismissWindow

    @State private var childDisplayName = "Child"
    @State private var moodBars: [SevenDayMoodBarModel] = []
    @State private var averageMood: Double?
    @State private var rotationAngle: Double = 0
    @State private var sceneIsReady: Bool = false

    private var hasMoodData: Bool {
        moodBars.contains { $0.score > 0 }
    }

    private var showsWelfareReview: Bool {
        guard let averageMood else { return false }
        return averageMood < 2.5
    }

    private var moodBarsSignature: String {
        moodBars.map { "\($0.id):\($0.score)" }.joined(separator: "|")
    }

    var body: some View {
        VStack(spacing: 0) {
            overlayPanel
            chartContent
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .task {
            loadChartData()
        }
    }

    @ViewBuilder
    private var chartContent: some View {
        if hasMoodData {
            VStack(spacing: 12) {
                moodBarsStage
                MoodTrendChart(childID: childID, childDisplayName: childDisplayName, compact: true)
                    .frame(height: 100)
                    .padding(.horizontal, 4)
            }
            .padding(.horizontal, 12)
            .padding(.top, 8)
            .padding(.bottom, 12)
        } else {
            ContentUnavailableView {
                Label("No mood data", systemImage: "heart.text.square")
            } description: {
                Text("Wellbeing observations from the last seven days will appear here.")
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }

    @ViewBuilder
    private var moodBarsStage: some View {
        #if arch(simulator)
        MoodChartBarStripView(bars: moodBars, rotationDegrees: rotationAngle)
            .frame(height: 150)
            .frame(maxWidth: .infinity)
            .padding(.horizontal, 8)
            .padding(.vertical, 6)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
            .gesture(dragRotationGesture)
        #else
        realityBarsStage
        #endif
    }

    #if !arch(simulator)
    private var realityBarsStage: some View {
        Group {
            if sceneIsReady {
                RealityView { content in
                    guard content.entities.isEmpty else { return }
                    do {
                        try populateScene(into: content)
                    } catch {
                        print("RealityKit scene error: \(error)")
                    }
                } update: { content in
                    applyRotation(to: content)
                }
                .id(moodBarsSignature)
                .frame(height: 188)
                .frame(maxWidth: .infinity)
                .frame(depth: 0.10)
                .overlay(alignment: .bottom) { dayLabelsRow }
                .gesture(dragRotationGesture)
            } else {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(.ultraThinMaterial)
                    .frame(height: 188)
                    .overlay { ProgressView() }
                    .overlay(alignment: .bottom) { dayLabelsRow }
            }
        }
        .task {
            try? await Task.sleep(nanoseconds: 300_000_000)
            sceneIsReady = true
        }
    }

    private var dayLabelsRow: some View {
        HStack(spacing: 0) {
            ForEach(moodBars) { bar in
                Text(bar.label)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity)
            }
        }
        .padding(.horizontal, 6)
        .padding(.bottom, 6)
    }
    #endif

    private var dragRotationGesture: some Gesture {
        DragGesture()
            .onChanged { value in
                rotationAngle = value.translation.width * 0.5
            }
    }

    private var overlayPanel: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Mood Trend — \(childDisplayName)")
                        .font(.headline)
                    Text("Last 7 days · Welfare threshold at mood 2")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Button(action: closeChart) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title2)
                        .symbolRenderingMode(.hierarchical)
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Close mood chart")
            }

            if showsWelfareReview {
                Label("Consider welfare review", systemImage: "exclamationmark.triangle.fill")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.red)
                    .padding(8)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .modifier(MoodChartOverlayChrome())
    }

    private func closeChart() {
        dismissWindow(id: "mood-chart", value: MoodChartWindowID(childID: childID))
    }

    #if !arch(simulator)
    private static let chartRootName = "MoodChartRoot"

    private func applyRotation(to content: RealityViewContent) {
        guard let root = content.entities.first(where: { $0.name == Self.chartRootName }) else { return }
        root.orientation = simd_quatf(angle: Float(rotationAngle) * .pi / 180, axis: SIMD3(0, 1, 0))
    }

    private func populateScene(into content: RealityViewContent) throws {
        guard !moodBars.isEmpty else { return }

        let root = Entity()
        root.name = Self.chartRootName
        root.position = SIMD3(0, 0.01, 0)
        content.add(root)

        let barWidth: Float = 0.028
        let barDepth: Float = 0.028
        let maxBarHeight: Float = 0.11
        let floorY: Float = -0.04
        let spacing: Float = 0.072
        let count = Float(moodBars.count)
        let xOrigin = -(count - 1) * spacing / 2
        let chartSpan = max(0.38, (count - 1) * spacing + barWidth)

        for bar in moodBars {
            let hasScore = bar.score > 0
            let normalized = hasScore ? (bar.score / 5.0) : 0.18
            let height = max(0.02, normalized * maxBarHeight)
            let barMesh = MeshResource.generateBox(size: [barWidth, height, barDepth])
            let material = SimpleMaterial(
                color: hasScore ? moodColor(score: bar.score) : UIColor.systemGray3,
                isMetallic: false
            )
            let barEntity = ModelEntity(mesh: barMesh, materials: [material])

            let xPos = xOrigin + Float(bar.id) * spacing
            barEntity.position = SIMD3(xPos, floorY + height / 2, 0)
            root.addChild(barEntity)
        }

        let thresholdHeight = floorY + (2.0 / 5.0) * maxBarHeight
        let lineMesh = MeshResource.generateBox(size: [chartSpan, 0.0025, 0.0025])
        let lineMaterial = SimpleMaterial(color: .red, isMetallic: false)
        let lineEntity = ModelEntity(mesh: lineMesh, materials: [lineMaterial])
        lineEntity.position = SIMD3(0, thresholdHeight, 0.015)
        root.addChild(lineEntity)

        applyRotation(to: content)
    }

    private func moodColor(score: Float) -> UIColor {
        switch score {
        case 4...5: return .systemGreen
        case 3..<4: return .systemOrange
        default: return .systemRed
        }
    }
    #endif

    private func loadChartData() {
        let childRequest: NSFetchRequest<Child> = Child.fetchRequest()
        childRequest.fetchLimit = 1
        childRequest.predicate = NSPredicate(format: "id == %@", childID as CVarArg)
        if let child = try? context.fetch(childRequest).first {
            childDisplayName = child.fullDisplayName
        }

        let entryRequest: NSFetchRequest<DiaryEntry> = DiaryEntry.fetchRequest()
        entryRequest.sortDescriptors = [NSSortDescriptor(keyPath: \DiaryEntry.timestamp, ascending: true)]
        entryRequest.predicate = AnalyticsDataService.wellbeingLastSevenDaysPredicate(childID: childID)

        guard let entries = try? context.fetch(entryRequest) else {
            moodBars = []
            averageMood = nil
            return
        }

        let points = AnalyticsDataService.moodTrendPoints(from: entries)
        averageMood = AnalyticsDataService.averageMoodScore(from: points)

        let scoreByDay = Dictionary(uniqueKeysWithValues: points.map { ($0.day.startOfDay, Float($0.score)) })
        let days = Date.lastSevenCalendarDays()

        moodBars = days.enumerated().map { index, day in
            SevenDayMoodBarModel(
                id: index,
                label: day.formatted(.dateTime.weekday(.abbreviated)),
                score: scoreByDay[day.startOfDay] ?? 0
            )
        }
    }
}

/// - Description: Simulator uses standard material; device uses spatial glass chrome.
private struct MoodChartOverlayChrome: ViewModifier {
    func body(content: Content) -> some View {
        #if arch(simulator)
        content
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        #else
        content
            .glassBackgroundEffect()
        #endif
    }
}
