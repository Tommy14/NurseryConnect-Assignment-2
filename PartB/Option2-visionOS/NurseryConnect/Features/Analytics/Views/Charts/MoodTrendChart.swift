//
//  MoodTrendChart.swift
//  NurseryConnect
//
//  Feature: Analytics
//  Role: Keyworker
//  Created: 29 May 2026
//  Description: Seven-day wellbeing mood line chart with welfare threshold rule.
//

import Charts
import CoreData
import SwiftUI

/// - Description: Line and point chart of averaged daily mood scores (1–5) for one child.
struct MoodTrendChart: View {
    let childID: UUID
    let childDisplayName: String
    var compact: Bool = false

    @FetchRequest private var wellbeingEntries: FetchedResults<DiaryEntry>

    init(childID: UUID, childDisplayName: String, compact: Bool = false) {
        self.childID = childID
        self.childDisplayName = childDisplayName
        self.compact = compact
        _wellbeingEntries = FetchRequest(
            sortDescriptors: [NSSortDescriptor(keyPath: \DiaryEntry.timestamp, ascending: true)],
            predicate: AnalyticsDataService.wellbeingLastSevenDaysPredicate(childID: childID),
            animation: .default
        )
    }

    private var points: [MoodTrendPoint] {
        AnalyticsDataService.moodTrendPoints(from: Array(wellbeingEntries))
    }

    private var chartHeight: CGFloat {
        compact ? 100 : 220
    }

    var body: some View {
        Group {
            if points.isEmpty {
                ContentUnavailableView {
                    Label("No mood data", systemImage: "heart.text.square")
                } description: {
                    if compact {
                        Text("Log wellbeing to see trends.")
                    } else {
                        Text("Wellbeing observations from the last seven days will appear here.")
                    }
                }
                .frame(height: chartHeight)
            } else {
                VStack(alignment: .leading, spacing: 8) {
                    Chart {
                        RuleMark(y: .value("Threshold", 2))
                            .foregroundStyle(Color.ncDanger.opacity(0.85))
                            .lineStyle(StrokeStyle(lineWidth: 1, dash: [4, 4]))

                        ForEach(points) { point in
                            LineMark(
                                x: .value("Day", point.day, unit: .day),
                                y: .value("Mood", point.score)
                            )
                            .interpolationMethod(.catmullRom)
                            .foregroundStyle(Color.ncPrimary)

                            PointMark(
                                x: .value("Day", point.day, unit: .day),
                                y: .value("Mood", point.score)
                            )
                            .foregroundStyle(Color.ncPrimary)
                            .symbolSize(compact ? 30 : 50)
                            .accessibilityLabel(moodAccessibilityLabel(for: point))
                        }
                    }
                    .chartYScale(domain: 1...5)
                    .chartYAxis {
                        AxisMarks(values: [1, 3, 5]) { value in
                            AxisGridLine()
                            AxisValueLabel {
                                if let intValue = value.as(Int.self) {
                                    Text(moodAxisLabel(for: intValue))
                                        .font(compact ? .caption2 : .caption)
                                }
                            }
                        }
                    }
                    .modifier(MoodChartAxisLabelsModifier(compact: compact))
                    .chartPlotStyle { plotArea in
                        plotArea.padding(.horizontal, compact ? 0 : 4)
                    }
                    .frame(height: chartHeight)

                    if !compact {
                        welfareThresholdLegend
                    }
                }
                .animation(.easeInOut, value: points)
                .transition(.opacity.combined(with: .scale(scale: 0.98)))
            }
        }
    }

    private var welfareThresholdLegend: some View {
        HStack(spacing: 8) {
            welfareThresholdLineSample
            Text("Welfare review threshold")
                .font(.caption2)
                .foregroundStyle(Color.ncDanger)
                .fixedSize(horizontal: false, vertical: true)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Welfare review threshold at mood score 2")
    }

    private var welfareThresholdLineSample: some View {
        Path { path in
            path.move(to: CGPoint(x: 0, y: 0))
            path.addLine(to: CGPoint(x: 28, y: 0))
        }
        .stroke(Color.ncDanger.opacity(0.85), style: StrokeStyle(lineWidth: 1, dash: [4, 4]))
        .frame(width: 28, height: 2)
        .accessibilityHidden(true)
    }

    private func moodAxisLabel(for value: Int) -> String {
        switch value {
        case 1: return "Upset"
        case 3: return "Okay"
        case 5: return "Happy"
        default: return "\(value)"
        }
    }

    private struct MoodChartAxisLabelsModifier: ViewModifier {
        let compact: Bool

        func body(content: Content) -> some View {
            if compact {
                content
                    .chartXAxis {
                        AxisMarks(values: .stride(by: .day)) { value in
                            AxisGridLine()
                            AxisValueLabel(format: .dateTime.weekday(.abbreviated))
                        }
                    }
            } else {
                content
                    .chartYAxisLabel("Mood", position: .leading)
                    .chartXAxis {
                        AxisMarks(values: .stride(by: .day)) { value in
                            AxisGridLine()
                            AxisValueLabel(format: .dateTime.weekday(.abbreviated))
                        }
                    }
                    .chartXAxisLabel("Day")
            }
        }
    }

    private func moodAccessibilityLabel(for point: MoodTrendPoint) -> String {
        let weekday = point.day.formatted(.dateTime.weekday(.wide))
        let scoreText = String(format: "%.1f", point.score)
        return "Mood trend for \(childDisplayName), \(weekday): \(scoreText)"
    }
}
