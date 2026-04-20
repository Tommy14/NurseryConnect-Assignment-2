//
//  DailyDiarySummaryCard.swift
//  NurseryConnect
//
//  Feature: Daily Diary
//  Role: Keyworker
//  Created: 22 April 2026
//  Description: Shows a compact aggregate summary of today's diary records.
//

import SwiftUI

struct DailyDiarySummaryCard: View {
    let summary: DailyDiarySummary
    @Binding var isExpanded: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 8) {
                Image(systemName: "chart.bar.doc.horizontal")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Color.ncPrimary)
                Text("Today's summary")
                    .font(.caption.weight(.bold))
                    .tracking(0.6)
                    .foregroundStyle(.secondary)
                Spacer(minLength: 0)
                Image(systemName: isExpanded ? "chevron.up.circle.fill" : "chevron.down.circle.fill")
                    .font(.body)
                    .foregroundStyle(.tertiary)
            }

            if isExpanded {
                fitnessSummaryTile
            } else {
                compactSummaryLine
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .ncStudioElevatedSurface(cornerRadius: 14)
        .contentShape(Rectangle())
        .onTapGesture {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.85)) {
                isExpanded.toggle()
            }
        }
        .accessibilityAddTraits(.isButton)
        .accessibilityLabel(isExpanded ? "Collapse today’s summary" : "Expand today’s summary")
    }

    private var moodValueText: String {
        guard let average = summary.averageMoodRating else { return "No mood logged" }
        return String(format: "%.1f/5", average)
    }

    private var moodDetailText: String? {
        guard let latest = summary.latestMoodRating else { return nil }
        return "Latest \(latest)/5"
    }

    private var activePercentageText: String {
        guard let percentage = summary.activePercentage else { return "—" }
        return "\(Int(percentage.rounded()))%"
    }

    private var compactSummaryLine: some View {
        HStack(spacing: 12) {
            compactMetric(title: "Sleep", value: formattedDuration(summary.totalSleepMinutes))
            compactMetric(title: "Fluid", value: "\(summary.totalFluidIntakeMl) ml")
            compactMetric(title: "Active", value: activePercentageText)
            Spacer(minLength: 0)
        }
    }

    private func compactMetric(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(.caption2.weight(.semibold))
                .foregroundStyle(.secondary)
            Text(value)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.primary)
        }
    }

    private var fitnessSummaryTile: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 16) {
                ringCluster
                VStack(alignment: .leading, spacing: 10) {
                    ringLegendRow(
                        color: activeStartColor,
                        title: "Active",
                        value: activePercentageText,
                        detail: summary.activePercentage == nil ? "No duration logs yet" : nil
                    )
                    ringLegendRow(
                        color: sleepStartColor,
                        title: "Sleep",
                        value: formattedDuration(summary.totalSleepMinutes),
                        detail: "\(sleepShareText) of logged duration"
                    )
                    ringLegendRow(
                        color: fluidStartColor,
                        title: "Fluid",
                        value: "\(summary.totalFluidIntakeMl) ml",
                        detail: "Goal \(Int(hydrationRingProgress * 100))%"
                    )
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }

            Divider()

            HStack(spacing: 18) {
                bottomMetric(systemImage: "figure.and.child.holdinghands", title: "Nappy", value: "\(summary.nappyChangesCount)")
                bottomMetric(systemImage: "heart.fill", title: "Mood", value: moodValueText)
                if let detail = moodDetailText {
                    Text(detail)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .frame(maxWidth: .infinity, alignment: .center)
        }
    }

    private var activeRingProgress: Double {
        guard let percentage = summary.activePercentage else { return 0 }
        return min(max(percentage / 100, 0), 1)
    }

    private var sleepRingProgress: Double {
        let total = summary.activeMinutes + summary.restMinutes
        guard total > 0 else { return 0 }
        return min(max(Double(summary.restMinutes) / Double(total), 0), 1)
    }

    private var hydrationRingProgress: Double {
        let hydrationGoalMl = 1000.0
        guard hydrationGoalMl > 0 else { return 0 }
        return min(max(Double(summary.totalFluidIntakeMl) / hydrationGoalMl, 0), 1)
    }

    private var ringCluster: some View {
        ZStack {
            Circle()
                .stroke(Color.primary.opacity(0.08), lineWidth: 12)
                .frame(width: 140, height: 140)
            Circle()
                .trim(from: 0, to: activeRingProgress)
                .stroke(
                    AngularGradient(
                        gradient: Gradient(colors: [activeStartColor, activeEndColor]),
                        center: .center
                    ),
                    style: StrokeStyle(lineWidth: 12, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .frame(width: 140, height: 140)
                .animation(.easeInOut(duration: 0.35), value: activeRingProgress)

            Circle()
                .stroke(Color.primary.opacity(0.08), lineWidth: 10)
                .frame(width: 106, height: 106)
            Circle()
                .trim(from: 0, to: sleepRingProgress)
                .stroke(
                    AngularGradient(
                        gradient: Gradient(colors: [sleepStartColor, sleepEndColor]),
                        center: .center
                    ),
                    style: StrokeStyle(lineWidth: 10, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .frame(width: 106, height: 106)
                .animation(.easeInOut(duration: 0.35), value: sleepRingProgress)

            Circle()
                .stroke(Color.primary.opacity(0.08), lineWidth: 8)
                .frame(width: 76, height: 76)
            Circle()
                .trim(from: 0, to: hydrationRingProgress)
                .stroke(
                    AngularGradient(
                        gradient: Gradient(colors: [fluidStartColor, fluidEndColor]),
                        center: .center
                    ),
                    style: StrokeStyle(lineWidth: 8, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .frame(width: 76, height: 76)
                .animation(.easeInOut(duration: 0.35), value: hydrationRingProgress)

            VStack(spacing: 2) {
                Text(activePercentageText)
                    .font(.title2.weight(.bold))
                    .foregroundStyle(activeStartColor)
                Text("Active")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var sleepShareText: String {
        let total = summary.activeMinutes + summary.restMinutes
        guard total > 0 else { return "0%" }
        let share = Int((Double(summary.restMinutes) / Double(total) * 100).rounded())
        return "\(share)%"
    }

    private func ringLegendRow(color: Color, title: String, value: String, detail: String?) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack(spacing: 6) {
                Circle()
                    .fill(color)
                    .frame(width: 7, height: 7)
                Text(title)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
            }
            Text(value)
                .font(.headline.weight(.semibold))
                .foregroundStyle(.primary)
                .lineLimit(2)
                .minimumScaleFactor(0.85)
            if let detail {
                Text(detail)
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
                    .lineLimit(1)
            }
        }
    }

    private func bottomMetric(systemImage: String, title: String, value: String) -> some View {
        HStack(spacing: 6) {
            Image(systemName: systemImage)
                .font(.caption.weight(.semibold))
                .foregroundStyle(Color.ncPrimary.opacity(0.95))
            VStack(alignment: .leading, spacing: 1) {
                Text(title)
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(.secondary)
                Text(value)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.primary)
                    .lineLimit(1)
            }
        }
    }

    private var activeStartColor: Color { Color(red: 1.0, green: 0.26, blue: 0.52) }   // vivid pink
    private var activeEndColor: Color { Color(red: 1.0, green: 0.57, blue: 0.26) }     // warm orange
    private var sleepStartColor: Color { Color(red: 0.46, green: 0.36, blue: 1.0) }    // electric violet
    private var sleepEndColor: Color { Color(red: 0.17, green: 0.74, blue: 1.0) }      // cyan-blue
    private var fluidStartColor: Color { Color(red: 0.06, green: 0.79, blue: 0.74) }   // turquoise
    private var fluidEndColor: Color { Color(red: 0.13, green: 0.97, blue: 0.42) }     // neon green

    private func formattedDuration(_ minutes: Int) -> String {
        guard minutes > 0 else { return "0m" }
        let hours = minutes / 60
        let remainingMinutes = minutes % 60
        if hours == 0 {
            return "\(remainingMinutes)m"
        }
        if remainingMinutes == 0 {
            return "\(hours)h"
        }
        return "\(hours)h \(remainingMinutes)m"
    }

}

#Preview {
    DailyDiarySummaryCard(
        summary: DailyDiarySummary(
            totalSleepMinutes: 95,
            totalFluidIntakeMl: 450,
            nappyChangesCount: 2,
            averageMoodRating: 4.0,
            latestMoodRating: 5,
            activeMinutes: 120,
            restMinutes: 95,
            activePercentage: 55.8
        ),
        isExpanded: .constant(true)
    )
    .padding()
}
