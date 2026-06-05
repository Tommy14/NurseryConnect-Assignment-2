//
//  WeeklyActivityDistributionChart.swift
//  NurseryConnect
//
//  Feature: Analytics
//  Role: Keyworker
//  Created: 29 May 2026
//  Description: Bar chart of diary entry counts by type for the current week.
//

import Charts
import CoreData
import SwiftUI

/// - Description: Weekly diary entry distribution with optional bar tap to filter the journal.
struct WeeklyActivityDistributionChart: View {
    let childID: UUID
    let childDisplayName: String
    var compact: Bool = false
    var onBarTapped: ((DiaryEntryType) -> Void)?

    @EnvironmentObject private var coordinator: KeyworkerIPadCoordinator
    @FetchRequest private var weekEntries: FetchedResults<DiaryEntry>

    init(
        childID: UUID,
        childDisplayName: String,
        compact: Bool = false,
        onBarTapped: ((DiaryEntryType) -> Void)? = nil
    ) {
        self.childID = childID
        self.childDisplayName = childDisplayName
        self.compact = compact
        self.onBarTapped = onBarTapped
        _weekEntries = FetchRequest(
            sortDescriptors: [NSSortDescriptor(keyPath: \DiaryEntry.timestamp, ascending: true)],
            predicate: AnalyticsDataService.diaryCurrentWeekPredicate(childID: childID),
            animation: .default
        )
    }

    private var counts: [WeeklyActivityCount] {
        AnalyticsDataService.weeklyActivityCounts(from: Array(weekEntries))
    }

    private var chartHeight: CGFloat {
        compact ? 100 : 220
    }

    var body: some View {
        Group {
            if counts.allSatisfy({ $0.count == 0 }) {
                ContentUnavailableView {
                    Label("No activity", systemImage: "chart.bar")
                } description: {
                    Text("Diary entries this week will appear here.")
                }
                .frame(height: chartHeight)
            } else {
                Chart(counts) { item in
                    BarMark(
                        x: .value("Type", item.type.title),
                        y: .value("Count", item.count)
                    )
                    .foregroundStyle(by: .value("Type", item.type.title))
                    .annotation(position: .top) {
                        if item.count > 0 {
                            Text("\(item.count)")
                                .font(.caption2.weight(.semibold))
                                .foregroundStyle(Color(.label))
                        }
                    }
                }
                .chartForegroundStyleScale { typeName in
                    if let type = DiaryEntryType.allCases.first(where: { $0.title == typeName }) {
                        return AppTheme.diaryColor(for: type)
                    }
                    return Color.ncPrimary
                }
                .chartYAxis {
                    AxisMarks(position: .leading) { value in
                        AxisGridLine()
                        AxisValueLabel {
                            if let intValue = value.as(Int.self) {
                                Text("\(intValue)")
                            }
                        }
                    }
                }
                .chartXAxis {
                    AxisMarks { value in
                        AxisValueLabel {
                            if let label = value.as(String.self) {
                                Text(compact ? String(label.prefix(3)) : label)
                                    .font(.caption2)
                            }
                        }
                    }
                }
                .chartOverlay { proxy in
                    GeometryReader { geometry in
                        Rectangle()
                            .fill(Color.clear)
                            .contentShape(Rectangle())
                            .onTapGesture { location in
                                guard let plotFrame = proxy.plotFrame else { return }
                                let origin = geometry[plotFrame].origin
                                let xPosition = location.x - origin.x
                                guard let typeName: String = proxy.value(atX: xPosition),
                                      let type = DiaryEntryType.allCases.first(where: { $0.title == typeName }) else {
                                    return
                                }
                                handleBarTap(type)
                            }
                    }
                }
                .frame(height: chartHeight)
                .animation(.easeInOut, value: counts)
                .transition(.opacity.combined(with: .scale(scale: 0.98)))
            }
        }
    }

    private func handleBarTap(_ type: DiaryEntryType) {
        coordinator.journalEntryTypeFilter = type
        if coordinator.journalContentSegment == .charts {
            coordinator.journalContentSegment = .journal
        }
        onBarTapped?(type)
    }
}
