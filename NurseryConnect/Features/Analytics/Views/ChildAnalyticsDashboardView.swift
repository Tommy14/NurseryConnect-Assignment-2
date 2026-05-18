//
//  ChildAnalyticsDashboardView.swift
//  NurseryConnect
//
//  Feature: Analytics
//  Role: Keyworker
//  Created: 29 May 2026
//  Description: Scrollable analytics dashboard for the Charts segment (single-column layout).
//

import CoreData
import SwiftUI

/// - Description: Full-width analytics dashboard when the Charts segment is selected.
struct ChildAnalyticsDashboardView: View {
    let childID: UUID
    let childDisplayName: String
    let managedObjectContext: NSManagedObjectContext

    @State private var isAuthorized = false

    var body: some View {
        Group {
            if isAuthorized {
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 20) {
                        ChartSectionCard(
                            title: "Mood trend — \(childDisplayName)",
                            caption: "Daily average wellbeing mood over the last seven days. The red line marks the welfare review threshold (EYFS): if the average drops below 2, schedule a welfare check."
                        ) {
                            MoodTrendChart(childID: childID, childDisplayName: childDisplayName)
                        }

                        ChartSectionCard(
                            title: "This Week's Activity — \(childDisplayName)",
                            caption: "Count of diary observations by type for the current week. Tap a bar to highlight matching entries in the journal column."
                        ) {
                            WeeklyActivityDistributionChart(
                                childID: childID,
                                childDisplayName: childDisplayName
                            )
                        }

                        ChartSectionCard(
                            title: "Monthly attendance — \(childDisplayName)",
                            caption: "Each bar is one day this month: green when \(childDisplayName) was present, amber when marked absent, grey when no attendance record exists yet."
                        ) {
                            ChildMonthlyAttendanceChart(
                                childID: childID,
                                childDisplayName: childDisplayName
                            )
                        }
                    }
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .scrollContentBackground(.hidden)
                .ncStudioScreenBackdropUnlessChildWorkspace()
            } else {
                ContentUnavailableView {
                    Label("Not available", systemImage: "lock.fill")
                } description: {
                    Text("Analytics are only available for children assigned to you.")
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .ncStudioScreenBackdropUnlessChildWorkspace()
            }
        }
        .task(id: childID) {
            isAuthorized = (try? KeyworkerGDPRScope.childBelongsToKeyworker(childID: childID, in: managedObjectContext)) ?? false
        }
    }
}
