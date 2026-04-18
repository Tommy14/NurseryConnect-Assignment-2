//
//  KeyworkerDashboardViewModel.swift
//  NurseryConnect
//
//  Feature: Dashboard
//  Role: Keyworker
//  Created: 2 April 2026
//  Description: Loads assigned children and computes today’s diary completeness indicators.
//
// -----------------------------------------------------------------
// Date       Name        What has done
// -----------------------------------------------------------------
// 020426     Tommy1914   Created the file with fetches and completeness scoring.
// 100426     Tommy1914   Seed-before-fetch and loading state to avoid empty dashboard race.
// 100426     Tommy1914   Refresh summaries when `DiaryEntry` saves (no restart required).
// 100426     Tommy1914   Marked save-notification helper `nonisolated` to avoid main-actor sync warning pauses.
// 140426     Tommy1914   Green dot when every planned session has a log (`DayTimelineMerger`).
// 140426     Tommy1914   Removed gender from child summaries and persistence.
// -----------------------------------------------------------------

import Combine
import CoreData
import Foundation

/// - Description: Traffic-light style indicator: green when every planned session has at least one log today.
enum DiaryCompletenessDot: String, CaseIterable {
    case complete
    case partial
    case none
}

/// - Description: Sleep interval from today’s diary rows (for “Sleeping” on dashboard tiles).
struct ChildSleepInterval: Hashable {
    let start: Date
    let end: Date
}

/// - Description: Lightweight row model for dashboard cards (avoids binding views directly to managed objects).
struct KeyworkerChildSummary: Identifiable, Hashable {
    let id: UUID
    let firstName: String
    let lastName: String
    let roomName: String
    let keyworkerName: String
    let allergies: String
    let photoConsent: Bool
    let dateOfBirth: Date
    let dot: DiaryCompletenessDot
    /// - Description: Today’s logged sleep spans for resolving “Sleeping” vs schedule.
    let sleepIntervals: [ChildSleepInterval]
    let checkInAt: Date?
    let checkOutAt: Date?
    /// - Description: When false, activity text ignores attendance (schedule only). True when today has an `AttendanceRecord` row.
    let usesAttendanceForActivityLine: Bool
    /// - Description: Derived attendance bucket for dashboard sections and the child card capsule.
    let attendanceBucket: KeyworkerAttendanceBucket
    /// - Description: Most recent wellbeing mood (1–5) logged today, if any.
    let latestMoodRating: Int16?
    /// - Description: True when any incident for this child is not yet acknowledged.
    let hasOpenIncident: Bool
}

extension KeyworkerChildSummary {
    /// - Description: SwiftUI row identity for the dashboard list. `id` alone is not enough: `ForEach` can reuse row views when only attendance changes, leaving capsules stale after check-in.
    var dashboardRowIdentity: String {
        let inT = checkInAt?.timeIntervalSinceReferenceDate ?? -1
        let outT = checkOutAt?.timeIntervalSinceReferenceDate ?? -1
        return "\(id.uuidString)|\(attendanceBucket.rawValue)|\(inT)|\(outT)|\(usesAttendanceForActivityLine)"
    }
}

/// - Description: Coordinates dashboard data for the keyworker home screen.
@MainActor
final class KeyworkerDashboardViewModel: ObservableObject {
    // MARK: - Published State

    @Published private(set) var childSummaries: [KeyworkerChildSummary] = []
    @Published private(set) var isLoading = true
    @Published var errorMessage: String?

    // MARK: - Properties

    private let context: NSManagedObjectContext
    private var saveObserver: NSObjectProtocol?

    // MARK: - Lifecycle

    /// - Description: Creates a view model bound to the supplied managed object context.
    /// - Parameters:
    ///   - context: Main-queue Core Data context.
    init(context: NSManagedObjectContext) {
        self.context = context
        saveObserver = NotificationCenter.default.addObserver(
            forName: .NSManagedObjectContextDidSave,
            object: context,
            queue: .main
        ) { [weak self] notification in
            guard let self else { return }
            guard Self.notificationInvolvesDashboardRelevantStores(notification) else { return }
            Task { await self.reloadChildSummariesFromStore(showLoading: false) }
        }
    }

    deinit {
        if let saveObserver {
            NotificationCenter.default.removeObserver(saveObserver)
        }
    }

    // MARK: - Public Methods

    /// - Description: Reloads children assigned to the demo keyworker and refreshes completeness dots.
    func refresh() async {
        await reloadChildSummariesFromStore(showLoading: true)
    }

    /// - Description: Recomputes dashboard rows; use `showLoading: false` after saves so the list does not flash a spinner.
    func reloadChildSummariesFromStore(showLoading: Bool) async {
        if showLoading { isLoading = true }
        defer { if showLoading { isLoading = false } }
        context.processPendingChanges()
        DataSeeder.seedIfNeeded(context: context)
        do {
            let children = try fetchAssignedChildren()
            var rows: [KeyworkerChildSummary] = []
            for child in children {
                guard let id = child.id else { continue }
                let entries = try todaysDiaryEntries(for: child)
                let dot = completenessDot(from: entries)
                let sleepIntervals = DayTimelineMerger.sleepIntervals(from: entries).map {
                    ChildSleepInterval(start: $0.start, end: $0.end)
                }
                let attendance = try todaysAttendanceRecord(for: child)
                let hasOpen = try childHasNonAcknowledgedIncident(child)
                let mood = Self.latestWellbeingMood(from: entries)
                let markedAbsent = attendance?.markedAbsent == true
                let bucket = KeyworkerAttendanceBucket.resolve(
                    checkOutAt: attendance?.checkOutAt,
                    checkInAt: attendance?.checkInAt,
                    markedAbsent: markedAbsent
                )
                let summary = KeyworkerChildSummary(
                    id: id,
                    firstName: child.firstName ?? "",
                    lastName: child.lastName ?? "",
                    roomName: child.roomName ?? "",
                    keyworkerName: child.keyworkerName ?? "",
                    allergies: child.allergies ?? "",
                    photoConsent: child.photoConsent,
                    dateOfBirth: child.dateOfBirth ?? Date(),
                    dot: dot,
                    sleepIntervals: sleepIntervals,
                    checkInAt: attendance?.checkInAt,
                    checkOutAt: attendance?.checkOutAt,
                    usesAttendanceForActivityLine: attendance != nil,
                    attendanceBucket: bucket,
                    latestMoodRating: mood,
                    hasOpenIncident: hasOpen
                )
                rows.append(summary)
            }
            childSummaries = rows.sorted { $0.firstName < $1.firstName }
        } catch {
            errorMessage = "Could not load children. Please try again."
        }
    }

    /// - Description: True when a save touches diary, attendance, or incidents (dashboard list must stay fresh).
    nonisolated private static func notificationInvolvesDashboardRelevantStores(_ notification: Notification) -> Bool {
        let keys = [NSInsertedObjectsKey, NSUpdatedObjectsKey, NSDeletedObjectsKey]
        for key in keys {
            if let set = notification.userInfo?[key] as? Set<NSManagedObject> {
                if set.contains(where: { $0 is DiaryEntry || $0 is AttendanceRecord || $0 is Incident }) { return true }
            } else if let set = notification.userInfo?[key] as? NSSet {
                for case let obj as NSManagedObject in set {
                    if obj is DiaryEntry || obj is AttendanceRecord || obj is Incident { return true }
                }
            }
        }
        return false
    }

    /// - Description: Latest mood from today’s wellbeing rows by timestamp.
    private static func latestWellbeingMood(from entries: [DiaryEntry]) -> Int16? {
        let wellbeing = entries.filter {
            DiaryEntryType.fromPersistence($0.entryType ?? "") == .wellbeing && $0.moodRating > 0
        }
        guard let latest = wellbeing.max(by: { ($0.timestamp ?? .distantPast) < ($1.timestamp ?? .distantPast) }) else {
            return nil
        }
        return latest.moodRating
    }

    // MARK: - Private Methods

    /// - Description: Returns children linked to the current keyworker display name.
    /// - Returns: Array of `Child` entities.
    private func fetchAssignedChildren() throws -> [Child] {
        let request: NSFetchRequest<Child> = Child.fetchRequest()
        // GDPR: Scope results to the practitioner’s assigned cohort for this demo keyworker account.
        request.predicate = NSPredicate(format: "keyworkerName == %@", AppConstants.keyworkerDisplayName)
        request.sortDescriptors = [NSSortDescriptor(keyPath: \Child.firstName, ascending: true)]
        return try context.fetch(request)
    }

    /// - Description: Fetches today’s diary rows for completeness and sleep spans.
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

    /// - Description: Green dot only when each nursery schedule segment for today has at least one non-sleep diary row.
    private func completenessDot(from entries: [DiaryEntry]) -> DiaryCompletenessDot {
        if entries.isEmpty {
            return .none
        }
        let dayAnchor = Date().startOfDay
        if DayTimelineMerger.allPlannedSessionsHaveAtLeastOneLog(entries: entries, referenceDay: dayAnchor) {
            return .complete
        }
        return .partial
    }

    /// - Description: Today’s attendance row for the child, if present.
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

    /// - Description: True if any incident exists that is not yet acknowledged.
    private func childHasNonAcknowledgedIncident(_ child: Child) throws -> Bool {
        let request: NSFetchRequest<Incident> = Incident.fetchRequest()
        request.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [
            NSPredicate(format: "child == %@", child),
            NSPredicate(format: "status != %@", IncidentStatus.acknowledged.persistenceValue)
        ])
        request.fetchLimit = 1
        return try context.count(for: request) > 0
    }

}
