//
//  SyncQueueService.swift
//  NurseryConnect
//
//  Feature: Core
//  Role: Keyworker
//  Created: 10 April 2026
//  Description: Local-first queue that retries diary and incident submissions.
//

import Combine
import CoreData
import Foundation

@MainActor
protocol SyncTransport {
    func uploadDiaryEntry(_ entry: DiaryEntry) async throws
    func uploadIncident(_ incident: Incident) async throws
}

struct NoopSyncTransport: SyncTransport {
    func uploadDiaryEntry(_ entry: DiaryEntry) async throws {}
    func uploadIncident(_ incident: Incident) async throws {}
}

@MainActor
final class SyncQueueService: ObservableObject {
    static var shared: SyncQueueService {
        Shared.instance
    }

    private enum Shared {
        static let instance = SyncQueueService(
            context: PersistenceController.shared.container.viewContext,
            networkMonitor: NetworkMonitor.shared
        )
    }

    @Published private(set) var isProcessing = false
    private let context: NSManagedObjectContext
    private let transport: SyncTransport
    private let networkMonitor: NetworkMonitor

    init(
        context: NSManagedObjectContext,
        transport: SyncTransport? = nil,
        networkMonitor: NetworkMonitor? = nil
    ) {
        self.context = context
        self.transport = transport ?? NoopSyncTransport()
        self.networkMonitor = networkMonitor ?? .shared
    }

    func enqueueDiary(_ entry: DiaryEntry) async {
        markPending(entry: entry)
        persistContext()
        await processQueueIfPossible()
    }

    func enqueueIncident(_ incident: Incident) async {
        markPending(incident: incident)
        persistContext()
        await processQueueIfPossible()
    }

    func retryDiary(_ entry: DiaryEntry) async {
        markPending(entry: entry)
        persistContext()
        await processQueueIfPossible(force: true)
    }

    func retryIncident(_ incident: Incident) async {
        markPending(incident: incident)
        persistContext()
        await processQueueIfPossible(force: true)
    }

    func processQueueIfPossible(force: Bool = false) async {
        guard force || networkMonitor.isOnline else { return }
        guard !isProcessing else { return }
        isProcessing = true
        defer { isProcessing = false }

        let now = Date()

        do {
            for entry in try fetchPendingDiaryEntries() where shouldAttemptSync(
                state: SyncState.fromPersistence(entry.syncState),
                attempts: Int(entry.syncAttemptCount),
                enqueuedAt: entry.syncEnqueuedAt,
                now: now
            ) {
                do {
                    try await transport.uploadDiaryEntry(entry)
                    markSynced(entry: entry)
                } catch {
                    markFailed(attempts: Int(entry.syncAttemptCount)) { nextCount, retryAnchor in
                        entry.syncAttemptCount = Int32(nextCount)
                        entry.lastSyncError = error.localizedDescription
                        entry.syncEnqueuedAt = retryAnchor
                        entry.syncState = SyncState.failed.rawValue
                    }
                }
            }

            for incident in try fetchPendingIncidents() where shouldAttemptSync(
                state: SyncState.fromPersistence(incident.syncState),
                attempts: Int(incident.syncAttemptCount),
                enqueuedAt: incident.syncEnqueuedAt,
                now: now
            ) {
                do {
                    try await transport.uploadIncident(incident)
                    markSynced(incident: incident)
                } catch {
                    markFailed(attempts: Int(incident.syncAttemptCount)) { nextCount, retryAnchor in
                        incident.syncAttemptCount = Int32(nextCount)
                        incident.lastSyncError = error.localizedDescription
                        incident.syncEnqueuedAt = retryAnchor
                        incident.syncState = SyncState.failed.rawValue
                    }
                }
            }
            persistContext()
        } catch {
            // Keep queue resilient; failures remain visible via record-level sync fields.
        }
    }

    private func fetchPendingDiaryEntries() throws -> [DiaryEntry] {
        let request: NSFetchRequest<DiaryEntry> = DiaryEntry.fetchRequest()
        request.predicate = NSPredicate(format: "syncState != %@", SyncState.synced.rawValue)
        request.sortDescriptors = [NSSortDescriptor(key: "syncEnqueuedAt", ascending: true)]
        return try context.fetch(request)
    }

    private func fetchPendingIncidents() throws -> [Incident] {
        let request: NSFetchRequest<Incident> = Incident.fetchRequest()
        request.predicate = NSPredicate(format: "syncState != %@", SyncState.synced.rawValue)
        request.sortDescriptors = [NSSortDescriptor(key: "syncEnqueuedAt", ascending: true)]
        return try context.fetch(request)
    }

    private func shouldAttemptSync(state: SyncState, attempts: Int, enqueuedAt: Date?, now: Date) -> Bool {
        guard state != .synced else { return false }
        if state == .pending { return true }
        let anchor = enqueuedAt ?? .distantPast
        let delay = backoffDelay(forAttemptCount: attempts)
        return now.timeIntervalSince(anchor) >= delay
    }

    private func backoffDelay(forAttemptCount attempts: Int) -> TimeInterval {
        let cappedAttempt = max(0, min(attempts, 6))
        return min(pow(2.0, Double(cappedAttempt)) * 10.0, 300.0)
    }

    private func markPending(entry: DiaryEntry) {
        entry.syncState = SyncState.pending.rawValue
        entry.syncEnqueuedAt = Date()
        entry.lastSyncError = nil
    }

    private func markPending(incident: Incident) {
        incident.syncState = SyncState.pending.rawValue
        incident.syncEnqueuedAt = Date()
        incident.lastSyncError = nil
    }

    private func markSynced(entry: DiaryEntry) {
        entry.syncState = SyncState.synced.rawValue
        entry.syncAttemptCount = 0
        entry.lastSyncError = nil
        entry.syncEnqueuedAt = Date()
    }

    private func markSynced(incident: Incident) {
        incident.syncState = SyncState.synced.rawValue
        incident.syncAttemptCount = 0
        incident.lastSyncError = nil
        incident.syncEnqueuedAt = Date()
    }

    private func markFailed(attempts: Int, apply: (_ nextCount: Int, _ retryAnchor: Date) -> Void) {
        let nextCount = min(attempts + 1, 20)
        apply(nextCount, Date())
    }

    private func persistContext() {
        guard context.hasChanges else { return }
        try? context.save()
    }
}
