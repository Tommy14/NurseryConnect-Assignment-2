//
//  MessageActivityChart.swift
//  NurseryConnect
//
//  Feature: Analytics
//  Role: Keyworker
//  Created: 29 May 2026
//  Description: Seven-day inbound parent message sparkline for engagement monitoring.
//

import Charts
import CoreData
import SwiftUI

/// - Description: Compact bar sparkline of parent messages received per day (last seven days).
struct MessageActivityChart: View {
    @Environment(\.managedObjectContext) private var context
    @State private var dayCounts: [MessageDayCount] = []

    var body: some View {
        Group {
            if dayCounts.allSatisfy({ $0.count == 0 }) {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(Color(.tertiarySystemFill))
                    .frame(height: 60)
                    .overlay {
                        Text("No parent messages this week")
                            .font(.caption2)
                            .foregroundStyle(Color(.secondaryLabel))
                    }
            } else {
                Chart(dayCounts) { item in
                    BarMark(
                        x: .value("Day", item.day, unit: .day),
                        y: .value("Messages", item.count)
                    )
                    .foregroundStyle(Color.ncSecondary)
                }
                .chartXAxis(.hidden)
                .chartYAxis(.hidden)
                .frame(height: 60)
                .animation(.easeInOut, value: dayCounts)
                .transition(.opacity)
            }
        }
        .task {
            await loadMessageCounts()
        }
        .onReceive(NotificationCenter.default.publisher(for: .NSManagedObjectContextObjectsDidChange, object: context)) { _ in
            Task { await loadMessageCounts() }
        }
    }

    @MainActor
    private func loadMessageCounts() async {
        context.processPendingChanges()
        do {
            let childIDs = try MessagingGDPRScope.assignedChildIDs(in: context)
            let threadIDs = try MessagingGDPRScope.assignedThreadIDs(childIDs: childIDs, in: context)
            guard !threadIDs.isEmpty else {
                dayCounts = Date.lastSevenCalendarDays().map { MessageDayCount(day: $0, count: 0) }
                return
            }

            let sevenDaysAgo = Calendar.current.date(byAdding: .day, value: -6, to: Date().startOfDay) ?? Date().startOfDay
            let request: NSFetchRequest<Message> = Message.fetchRequest()
            request.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [
                NSPredicate(format: "threadID IN %@", threadIDs),
                NSPredicate(format: "senderRole != %@", MessageSenderRole.keyworker.persistenceValue),
                NSPredicate(format: "sentAt >= %@", sevenDaysAgo as NSDate)
            ])
            let messages = try context.fetch(request)
            dayCounts = AnalyticsDataService.messageDayCounts(from: messages)
        } catch {
            dayCounts = Date.lastSevenCalendarDays().map { MessageDayCount(day: $0, count: 0) }
        }
    }
}
