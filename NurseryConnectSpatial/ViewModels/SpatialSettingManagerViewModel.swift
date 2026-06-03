//
//  SpatialSettingManagerViewModel.swift
//  NurseryConnect Spatial
//
//  Feature: Spatial
//  Role: Setting Manager
//  Created: 2 June 2026
//  Description: Nursery-wide aggregates for the spatial Setting Manager dashboard.
//

import Combine
import CoreData
import Foundation

/// - Description: One keyworker row in the manager overview.
struct SpatialKeyworkerCohortRow: Identifiable, Hashable {
    let id: String
    let keyworkerName: String
    let assignedCount: Int
    let onSiteCount: Int
}

/// - Description: Dietary alert for catering coordination.
struct SpatialDietaryAlert: Identifiable, Hashable {
    let id: UUID
    let childName: String
    let detail: String
}

/// - Description: Loads setting-wide metrics across all children and keyworkers.
@MainActor
final class SpatialSettingManagerViewModel: ObservableObject {
    @Published private(set) var totalChildren = 0
    @Published private(set) var onSiteCount = 0
    @Published private(set) var awaitingCount = 0
    @Published private(set) var openIncidentCount = 0
    @Published private(set) var unreadMessageCount = 0
    @Published private(set) var keyworkerRows: [SpatialKeyworkerCohortRow] = []
    @Published private(set) var dietaryAlerts: [SpatialDietaryAlert] = []

    private let context: NSManagedObjectContext

    init(context: NSManagedObjectContext) {
        self.context = context
    }

    func refresh() async {
        context.processPendingChanges()
        do {
            let children = try fetchAllChildren()
            totalChildren = children.count
            var onSite = 0
            var awaiting = 0
            var incidents = 0
            var dietary: [SpatialDietaryAlert] = []

            for child in children {
                let attendance = try todaysAttendance(for: child)
                let bucket = KeyworkerAttendanceBucket.resolve(
                    checkOutAt: attendance?.checkOutAt,
                    checkInAt: attendance?.checkInAt,
                    markedAbsent: attendance?.markedAbsent == true
                )
                switch bucket {
                case .onSite: onSite += 1
                case .awaiting: awaiting += 1
                default: break
                }
                if try hasOpenIncident(child) { incidents += 1 }

                let diet = (child.dietaryRequirements ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
                let allergy = (child.allergies ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
                if !diet.isEmpty || !allergy.isEmpty {
                    let detail = [allergy, diet].filter { !$0.isEmpty }.joined(separator: " · ")
                    dietary.append(
                        SpatialDietaryAlert(
                            id: child.id ?? UUID(),
                            childName: child.fullDisplayName,
                            detail: detail
                        )
                    )
                }
            }

            onSiteCount = onSite
            awaitingCount = awaiting
            openIncidentCount = try countOpenIncidents()
            unreadMessageCount = try fetchUnreadCount()
            keyworkerRows = buildKeyworkerRows(from: children)
            dietaryAlerts = dietary.sorted { $0.childName < $1.childName }
        } catch {
            totalChildren = 0
            onSiteCount = 0
            awaitingCount = 0
            openIncidentCount = 0
            unreadMessageCount = 0
            keyworkerRows = []
            dietaryAlerts = []
        }
    }

    private func fetchAllChildren() throws -> [Child] {
        let request: NSFetchRequest<Child> = Child.fetchRequest()
        request.sortDescriptors = [
            NSSortDescriptor(keyPath: \Child.keyworkerName, ascending: true),
            NSSortDescriptor(keyPath: \Child.firstName, ascending: true)
        ]
        return try context.fetch(request)
    }

    private func todaysAttendance(for child: Child) throws -> AttendanceRecord? {
        let dayStart = Date().startOfDay
        let request: NSFetchRequest<AttendanceRecord> = AttendanceRecord.fetchRequest()
        request.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [
            NSPredicate(format: "child == %@", child),
            NSPredicate(format: "dayStart == %@", dayStart as NSDate)
        ])
        request.fetchLimit = 1
        return try context.fetch(request).first
    }

    private func hasOpenIncident(_ child: Child) throws -> Bool {
        let request: NSFetchRequest<Incident> = Incident.fetchRequest()
        request.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [
            NSPredicate(format: "child == %@", child),
            NSPredicate(format: "status != %@", IncidentStatus.acknowledged.persistenceValue)
        ])
        request.fetchLimit = 1
        return try context.count(for: request) > 0
    }

    private func countOpenIncidents() throws -> Int {
        let request: NSFetchRequest<Incident> = Incident.fetchRequest()
        request.predicate = NSPredicate(format: "status != %@", IncidentStatus.acknowledged.persistenceValue)
        return try context.count(for: request)
    }

    private func fetchUnreadCount() throws -> Int {
        let request: NSFetchRequest<Message> = Message.fetchRequest()
        request.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [
            NSPredicate(format: "isRead == NO"),
            NSPredicate(format: "senderRole != %@", MessageSenderRole.keyworker.persistenceValue)
        ])
        return try context.count(for: request)
    }

    private func buildKeyworkerRows(from children: [Child]) -> [SpatialKeyworkerCohortRow] {
        let grouped = Dictionary(grouping: children) { $0.keyworkerName ?? "Unassigned" }
        return grouped.map { name, cohort in
            var onSite = 0
            for child in cohort {
                guard let attendance = try? todaysAttendance(for: child) else { continue }
                if KeyworkerAttendanceBucket.resolve(
                    checkOutAt: attendance.checkOutAt,
                    checkInAt: attendance.checkInAt,
                    markedAbsent: attendance.markedAbsent
                ) == .onSite {
                    onSite += 1
                }
            }
            return SpatialKeyworkerCohortRow(
                id: name,
                keyworkerName: name,
                assignedCount: cohort.count,
                onSiteCount: onSite
            )
        }
        .sorted { $0.keyworkerName < $1.keyworkerName }
    }
}
