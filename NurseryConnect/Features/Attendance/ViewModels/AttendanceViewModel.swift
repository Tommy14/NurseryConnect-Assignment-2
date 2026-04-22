//
//  AttendanceViewModel.swift
//  NurseryConnect
//
//  Feature: Attendance
//  Role: Keyworker
//  Created: 16 April 2026
//  Description: Loads today’s attendance row and performs check-in / check-out saves.
//

import Combine
import CoreData
import Foundation

/// - Description: High-level state for the daily attendance card.
enum AttendancePhase: Equatable {
    case expected
    /// - Description: Recorded as not attending today (sick/holiday, etc.); clears timestamps when set.
    case absent
    case onPremises
    case departed
}

/// - Description: Manages one child’s attendance for the current calendar day.
@MainActor
final class AttendanceViewModel: ObservableObject {
    @Published private(set) var phase: AttendancePhase = .expected
    @Published private(set) var checkInAt: Date?
    @Published private(set) var checkOutAt: Date?
    @Published private(set) var droppedOffBy: String = ""
    @Published private(set) var collectedBy: String?
    @Published private(set) var authorisedCollectorLines: [String] = []
    @Published var errorMessage: String?

    private let childID: UUID
    private let context: NSManagedObjectContext

    init(childID: UUID, context: NSManagedObjectContext) {
        self.childID = childID
        self.context = context
    }

    /// - Description: Reloads child metadata and today’s `AttendanceRecord` if present.
    func load() async {
        errorMessage = nil
        do {
            try performLoad()
        } catch {
            errorMessage = "Could not load attendance."
        }
    }

    /// - Description: Records arrival; creates today’s row if needed (overwrites prior check-in on the same day).
    func checkIn(at time: Date, droppedOffBy name: String) async {
        errorMessage = nil
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.isEmpty == false else {
            errorMessage = "Enter who dropped the child off."
            return
        }
        do {
            guard let child = try fetchChild() else {
                errorMessage = "Child not found."
                return
            }
            let dayStart = Date().startOfDay
            let record = try fetchOrCreateRecord(child: child, dayStart: dayStart)
            record.markedAbsent = false
            record.checkInAt = time
            record.droppedOffBy = trimmed
            try context.save()
            apply(from: record)
        } catch {
            context.rollback()
            errorMessage = "Unable to save check-in."
        }
    }

    /// - Description: Records departure with the collector name selected or entered by staff.
    func checkOut(at time: Date, collectedBy name: String) async {
        errorMessage = nil
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.isEmpty == false else {
            errorMessage = "Enter who collected the child."
            return
        }
        do {
            guard let child = try fetchChild() else {
                errorMessage = "Child not found."
                return
            }
            let dayStart = Date().startOfDay
            guard let record = try fetchRecord(child: child, dayStart: dayStart),
                  record.checkInAt != nil
            else {
                errorMessage = "Check the child in before check-out."
                return
            }
            guard record.checkOutAt == nil else {
                errorMessage = "This child is already checked out today."
                return
            }
            record.checkOutAt = time
            record.collectedBy = trimmed
            try context.save()
            apply(from: record)
        } catch {
            context.rollback()
            errorMessage = "Unable to save check-out."
        }
    }

    /// - Description: Creates or updates today’s row: marks the child absent and clears arrival/departure fields.
    func markAbsentToday() async {
        errorMessage = nil
        do {
            guard let child = try fetchChild() else {
                errorMessage = "Child not found."
                return
            }
            let dayStart = Date().startOfDay
            let record = try fetchOrCreateRecord(child: child, dayStart: dayStart)
            record.markedAbsent = true
            record.checkInAt = nil
            record.checkOutAt = nil
            record.droppedOffBy = ""
            record.collectedBy = nil
            try context.save()
            apply(from: record)
        } catch {
            context.rollback()
            errorMessage = "Unable to save absence."
        }
    }

    /// - Description: Clears the absent flag so staff can check the child in; does not create a row if none exists.
    func clearMarkedAbsent() async {
        errorMessage = nil
        do {
            guard let child = try fetchChild() else {
                errorMessage = "Child not found."
                return
            }
            let dayStart = Date().startOfDay
            guard let record = try fetchRecord(child: child, dayStart: dayStart) else { return }
            guard record.markedAbsent else { return }
            record.markedAbsent = false
            try context.save()
            apply(from: record)
        } catch {
            context.rollback()
            errorMessage = "Unable to update attendance."
        }
    }

    /// - Description: Submits a safeguarding incident so leadership is notified that someone not on the authorised collectors list attempted collection at check-out. Does not check the child out.
    /// - Parameters:
    ///   - additionalNotes: Optional extra detail from staff (names given, what was said, etc.).
    /// - Returns: `true` when the incident was saved and queued for sync.
    @discardableResult
    func reportUnauthorisedCollectionAttempt(additionalNotes: String = "") async -> Bool {
        errorMessage = nil
        let category = IncidentCategory.safeguardingConcern
        let trimmedNotes = additionalNotes.trimmingCharacters(in: .whitespacesAndNewlines)
        do {
            guard let child = try fetchChild() else {
                errorMessage = "Child not found."
                return false
            }
            let dayStart = Date().startOfDay
            guard let record = try fetchRecord(child: child, dayStart: dayStart),
                  record.checkInAt != nil,
                  record.checkOutAt == nil
            else {
                errorMessage = "The child must be checked in and not yet checked out to report this."
                return false
            }

            let fn = child.firstName?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            let ln = child.lastName?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            let displayName = [fn, ln].filter { !$0.isEmpty }.joined(separator: " ")
            let nameForCopy = displayName.isEmpty ? "the child" : displayName

            guard let incident = NSEntityDescription.insertNewObject(
                forEntityName: "Incident",
                into: context
            ) as? Incident else {
                errorMessage = "Unable to create safeguarding report."
                return false
            }
            incident.id = UUID()
            incident.timestamp = Date()
            incident.category = category.persistenceValue
            incident.severity = category.defaultSeverity.persistenceValue
            incident.location = "Collection / pick-up"
            var description = "A person not listed as an authorised collector attempted to collect \(nameForCopy) at check-out."
            if trimmedNotes.isEmpty == false {
                description += " Staff notes: \(trimmedNotes)"
            }
            incident.incidentDescription = description
            incident.immediateActionTaken = """
            Child remained on the premises. Collection was not completed until identity could be verified with parents/carers per policy; room leadership was informed.
            """
            incident.witnesses = ""
            incident.bodyMapAnnotations = BodyMapCodec.encode([])
            incident.riddorRequired = false
            incident.isParentNotified = false
            incident.managerCountersigned = false
            incident.child = child
            incident.status = IncidentStatus.submitted.persistenceValue

            try context.save()
            await SyncQueueService.shared.enqueueIncident(incident)
            return true
        } catch {
            context.rollback()
            errorMessage = "Unable to send safeguarding report."
            return false
        }
    }

    // MARK: - Private

    private func performLoad() throws {
        guard let child = try fetchChild() else {
            errorMessage = "Child not found."
            return
        }
        authorisedCollectorLines = AuthorisedCollectorsParsing.lines(from: child.authorisedCollectors)
        let dayStart = Date().startOfDay
        if let record = try fetchRecord(child: child, dayStart: dayStart) {
            apply(from: record)
        } else {
            phase = .expected
            checkInAt = nil
            checkOutAt = nil
            droppedOffBy = ""
            collectedBy = nil
        }
    }

    private func apply(from record: AttendanceRecord) {
        checkInAt = record.checkInAt
        checkOutAt = record.checkOutAt
        droppedOffBy = record.droppedOffBy ?? ""
        collectedBy = record.collectedBy
        if record.checkOutAt != nil {
            phase = .departed
        } else if record.markedAbsent {
            phase = .absent
        } else if record.checkInAt != nil {
            phase = .onPremises
        } else {
            phase = .expected
        }
    }

    private func fetchChild() throws -> Child? {
        let request = NSFetchRequest<Child>(entityName: "Child")
        request.predicate = NSPredicate(format: "id == %@", childID as CVarArg)
        request.fetchLimit = 1
        return try context.fetch(request).first
    }

    private func fetchRecord(child: Child, dayStart: Date) throws -> AttendanceRecord? {
        let request = NSFetchRequest<AttendanceRecord>(entityName: "AttendanceRecord")
        request.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [
            NSPredicate(format: "child == %@", child),
            NSPredicate(format: "dayStart == %@", dayStart as NSDate)
        ])
        request.fetchLimit = 1
        return try context.fetch(request).first
    }

    private func fetchOrCreateRecord(child: Child, dayStart: Date) throws -> AttendanceRecord {
        if let existing = try fetchRecord(child: child, dayStart: dayStart) {
            return existing
        }
        guard let record = NSEntityDescription.insertNewObject(
            forEntityName: "AttendanceRecord",
            into: context
        ) as? AttendanceRecord else {
            throw NSError(
                domain: "AttendanceViewModel",
                code: 1,
                userInfo: [NSLocalizedDescriptionKey: "Could not create attendance record entity."]
            )
        }
        record.id = UUID()
        record.dayStart = dayStart
        record.child = child
        record.droppedOffBy = ""
        record.markedAbsent = false
        return record
    }
}
