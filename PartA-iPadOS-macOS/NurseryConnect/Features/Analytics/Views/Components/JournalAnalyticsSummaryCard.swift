//
//  JournalAnalyticsSummaryCard.swift
//  NurseryConnect
//
//  Feature: Analytics
//  Role: Keyworker
//  Created: 29 May 2026
//  Description: Compact mood and weekly activity charts for the journal summary area.
//

import SwiftUI

/// - Description: Horizontal summary of mood trend and weekly activity for the journal tab.
struct JournalAnalyticsSummaryCard: View {
    let childID: UUID
    let childDisplayName: String

    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(\.keyworkerChildWorkspace) private var keyworkerChildWorkspace
    @EnvironmentObject private var coordinator: KeyworkerIPadCoordinator

    private var usesVerticalChartLayout: Bool {
        horizontalSizeClass == .compact || keyworkerChildWorkspace
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: "chart.xyaxis.line")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Color.ncPrimary)
                Text("Analytics snapshot")
                    .font(.caption.weight(.bold))
                    .tracking(0.6)
                    .foregroundStyle(.secondary)
                Spacer(minLength: 0)
                if coordinator.journalContentSegment != .charts {
                    Button("Open charts") {
                        coordinator.journalContentSegment = .charts
                    }
                    .font(.caption.weight(.semibold))
                }
            }

            if usesVerticalChartLayout {
                VStack(spacing: 16) {
                    chartSections
                }
            } else {
                HStack(alignment: .top, spacing: 16) {
                    chartSections
                }
            }
        }
        .padding(14)
        .ncStudioElevatedSurface(cornerRadius: 14)
    }

    @ViewBuilder
    private var chartSections: some View {
        summarySection(title: "Mood (7 days)") {
            MoodTrendChart(childID: childID, childDisplayName: childDisplayName, compact: true)
        }
        summarySection(title: "This week") {
            WeeklyActivityDistributionChart(
                childID: childID,
                childDisplayName: childDisplayName,
                compact: true
            )
        }
    }

    private func summarySection<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundStyle(Color(.secondaryLabel))
            content()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
