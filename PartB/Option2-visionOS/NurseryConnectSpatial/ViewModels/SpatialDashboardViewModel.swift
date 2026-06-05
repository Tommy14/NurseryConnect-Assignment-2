//
//  SpatialDashboardViewModel.swift
//  NurseryConnect Spatial
//
//  Feature: Spatial
//  Role: Keyworker
//  Created: 2 June 2026
//  Description: Loads assigned children with today’s attendance, diary, mood, and incident flags.
//

import Combine
import CoreData
import Foundation

/// - Description: Spatial dashboard data for assigned children (read-only, no attendance mutations).
@MainActor
final class SpatialDashboardViewModel: ObservableObject {
    @Published private(set) var childSummaries: [SpatialChildSummary] = []

    private let context: NSManagedObjectContext

    init(context: NSManagedObjectContext) {
        self.context = context
    }

    func refresh() async {
        context.processPendingChanges()
        do {
            let children = try KeyworkerGDPRScope.assignedChildren(in: context)
            var rows: [SpatialChildSummary] = []
            for child in children {
                guard let id = child.id else { continue }
                let entries = try todaysDiaryEntries(for: child)
                let dot = completeness(from: entries)
                let attendance = try todaysAttendanceRecord(for: child)
                let markedAbsent = attendance?.markedAbsent == true
                let bucket = KeyworkerAttendanceBucket.resolve(
                    checkOutAt: attendance?.checkOutAt,
                    checkInAt: attendance?.checkInAt,
                    markedAbsent: markedAbsent
                )
                let mood = Self.latestWellbeingMood(from: entries)
                let hasOpen = try childHasNonAcknowledgedIncident(child)
                let preferred = child.preferredName?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
                rows.append(
                    SpatialChildSummary(
                        id: id,
                        firstName: child.firstName ?? "",
                        lastName: child.lastName ?? "",
                        preferredName: preferred.isEmpty ? (child.firstName ?? "") : preferred,
                        roomName: child.roomName ?? "",
                        allergies: child.allergies ?? "",
                        photoConsent: child.photoConsent,
                        dot: dot,
                        attendanceBucket: bucket,
                        latestMoodRating: mood,
                        hasOpenIncident: hasOpen
                    )
                )
            }
            childSummaries = rows.sorted { $0.firstName < $1.firstName }
        } catch {
            childSummaries = []
        }
    }

    private func todaysDiaryEntries(for child: Child) throws -> [DiaryEntry] {
        let start = Date().startOfDay
        let end = Date().endOfDay
        let request: NSFetchRequest<DiaryEntry> = DiaryEntry.fetchRequest()
        request.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [
            NSPredicate(format: "child == %@", child),
            NSPredicate(format: "timestamp >= %@ AND timestamp < %@", start as NSDate, end as NSDate)
        ])
        return try context.fetch(request)
    }

    private func completeness(from entries: [DiaryEntry]) -> SpatialDiaryCompleteness {
        guard !entries.isEmpty else { return .none }
        let types = Set(entries.compactMap { DiaryEntryType.fromPersistence($0.entryType ?? "") })
        let hasWellbeing = types.contains(.wellbeing)
        let hasCareLog = types.contains(.meal) || types.contains(.nappy) || types.contains(.activity)
        if hasWellbeing && hasCareLog { return .complete }
        return .partial
    }

    private func todaysAttendanceRecord(for child: Child) throws -> AttendanceRecord? {
        let dayStart = Date().startOfDay
        let request: NSFetchRequest<AttendanceRecord> = AttendanceRecord.fetchRequest()
        request.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [
            NSPredicate(format: "child == %@", child),
            NSPredicate(format: "dayStart == %@", dayStart as NSDate)
        ])
        request.fetchLimit = 1
        return try context.fetch(request).first
    }

    private func childHasNonAcknowledgedIncident(_ child: Child) throws -> Bool {
        let request: NSFetchRequest<Incident> = Incident.fetchRequest()
        request.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [
            NSPredicate(format: "child == %@", child),
            NSPredicate(format: "status != %@", IncidentStatus.acknowledged.persistenceValue)
        ])
        request.fetchLimit = 1
        return try context.count(for: request) > 0
    }

    private static func latestWellbeingMood(from entries: [DiaryEntry]) -> Int16? {
        let wellbeing = entries.filter {
            DiaryEntryType.fromPersistence($0.entryType ?? "") == .wellbeing && $0.moodRating > 0
        }
        guard let latest = wellbeing.max(by: { ($0.timestamp ?? .distantPast) < ($1.timestamp ?? .distantPast) }) else {
            return nil
        }
        return latest.moodRating
    }
}
