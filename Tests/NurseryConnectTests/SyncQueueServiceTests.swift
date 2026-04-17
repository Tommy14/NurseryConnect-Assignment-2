//
//  SyncQueueServiceTests.swift
//  NurseryConnectTests
//
//  Feature: Core
//  Role: Keyworker
//  Created: 13 April 2026
//  Description: Unit tests for local sync queue state transitions and retry behavior.
//

import CoreData
import XCTest
@testable import NurseryConnect

@MainActor
final class SyncQueueServiceTests: XCTestCase {
    func testEnqueueDiaryWhenOfflineStaysPending() async {
        let stack = PersistenceController(inMemory: true)
        let monitor = NetworkMonitor(initialIsOnline: false, enablePathMonitor: false)
        let queue = SyncQueueService(
            context: stack.container.viewContext,
            transport: PassingTransport(),
            networkMonitor: monitor
        )
        let child = makeChild(in: stack.container.viewContext)
        let entry = makeDiaryEntry(child: child, in: stack.container.viewContext)

        await queue.enqueueDiary(entry)

        XCTAssertEqual(entry.syncState, SyncState.pending.rawValue)
        XCTAssertEqual(entry.syncAttemptCount, 0)
    }

    func testEnqueueIncidentSyncsWhenOnline() async {
        let stack = PersistenceController(inMemory: true)
        let monitor = NetworkMonitor(initialIsOnline: true, enablePathMonitor: false)
        let queue = SyncQueueService(
            context: stack.container.viewContext,
            transport: PassingTransport(),
            networkMonitor: monitor
        )
        let child = makeChild(in: stack.container.viewContext)
        let incident = makeIncident(child: child, in: stack.container.viewContext)

        await queue.enqueueIncident(incident)

        XCTAssertEqual(incident.syncState, SyncState.synced.rawValue)
        XCTAssertEqual(incident.syncAttemptCount, 0)
        XCTAssertNil(incident.lastSyncError)
    }

    func testFailedSyncMarksRecordFailedAndIncrementsAttempts() async {
        let stack = PersistenceController(inMemory: true)
        let monitor = NetworkMonitor(initialIsOnline: true, enablePathMonitor: false)
        let queue = SyncQueueService(
            context: stack.container.viewContext,
            transport: FailingTransport(),
            networkMonitor: monitor
        )
        let child = makeChild(in: stack.container.viewContext)
        let incident = makeIncident(child: child, in: stack.container.viewContext)

        await queue.enqueueIncident(incident)

        XCTAssertEqual(incident.syncState, SyncState.failed.rawValue)
        XCTAssertEqual(incident.syncAttemptCount, 1)
        XCTAssertNotNil(incident.lastSyncError)
    }

    private func makeChild(in context: NSManagedObjectContext) -> Child {
        let child = Child(context: context)
        child.id = UUID()
        child.firstName = "Test"
        child.lastName = "Child"
        child.keyworkerName = AppConstants.keyworkerDisplayName
        child.roomName = "Sunshine"
        child.dateOfBirth = Date().addingTimeInterval(-100_000)
        return child
    }

    private func makeDiaryEntry(child: Child, in context: NSManagedObjectContext) -> DiaryEntry {
        let entry = DiaryEntry(context: context)
        entry.id = UUID()
        entry.entryType = DiaryEntryType.activity.persistenceValue
        entry.notes = "Observed activity"
        entry.timestamp = Date()
        entry.child = child
        entry.syncState = SyncState.synced.rawValue
        return entry
    }

    private func makeIncident(child: Child, in context: NSManagedObjectContext) -> Incident {
        let incident = Incident(context: context)
        incident.id = UUID()
        incident.category = IncidentCategory.accidentMinor.persistenceValue
        incident.severity = IncidentSeverity.minor.persistenceValue
        incident.status = IncidentStatus.submitted.persistenceValue
        incident.timestamp = Date()
        incident.incidentDescription = "Minor bump."
        incident.immediateActionTaken = "Applied cold compress."
        incident.child = child
        incident.syncState = SyncState.synced.rawValue
        return incident
    }
}

private struct PassingTransport: SyncTransport {
    func uploadDiaryEntry(_ entry: DiaryEntry) async throws {}
    func uploadIncident(_ incident: Incident) async throws {}
}

private struct FailingTransport: SyncTransport {
    func uploadDiaryEntry(_ entry: DiaryEntry) async throws {
        throw NSError(domain: "SyncTests", code: 1)
    }

    func uploadIncident(_ incident: Incident) async throws {
        throw NSError(domain: "SyncTests", code: 2)
    }
}
