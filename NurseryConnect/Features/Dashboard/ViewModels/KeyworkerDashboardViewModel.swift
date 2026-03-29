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
// -----------------------------------------------------------------

import Combine
import CoreData
import Foundation

/// - Description: Traffic-light style indicator for whether today’s key diary domains are logged.
enum DiaryCompletenessDot: String, CaseIterable {
    case complete
    case partial
    case none
}

/// - Description: Lightweight row model for dashboard cards (avoids binding views directly to managed objects).
struct KeyworkerChildSummary: Identifiable, Hashable {
    let id: UUID
    let firstName: String
    let lastName: String
    let roomName: String
    let allergies: String
    let dateOfBirth: Date
    let dot: DiaryCompletenessDot
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

    // MARK: - Lifecycle

    /// - Description: Creates a view model bound to the supplied managed object context.
    /// - Parameters:
    ///   - context: Main-queue Core Data context.
    init(context: NSManagedObjectContext) {
        self.context = context
    }

    // MARK: - Public Methods

    /// - Description: Reloads children assigned to the demo keyworker and refreshes completeness dots.
    func refresh() async {
        isLoading = true
        defer { isLoading = false }
        DataSeeder.seedIfNeeded(context: context)
        do {
            let children = try fetchAssignedChildren()
            var rows: [KeyworkerChildSummary] = []
            for child in children {
                guard let id = child.id else { continue }
                let dot = try completeness(for: child)
                let summary = KeyworkerChildSummary(
                    id: id,
                    firstName: child.firstName ?? "",
                    lastName: child.lastName ?? "",
                    roomName: child.roomName ?? "",
                    allergies: child.allergies ?? "",
                    dateOfBirth: child.dateOfBirth ?? Date(),
                    dot: dot
                )
                rows.append(summary)
            }
            childSummaries = rows.sorted { $0.firstName < $1.firstName }
        } catch {
            errorMessage = "Could not load children. Please try again."
        }
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

    /// - Description: Computes diary completeness from today’s entries for the given child.
    /// - Parameters:
    ///   - child: Core Data child record.
    /// - Returns: Completeness dot state for UI colouring.
    private func completeness(for child: Child) throws -> DiaryCompletenessDot {
        let start = Date().startOfDay
        let end = Date().endOfDay
        let request: NSFetchRequest<DiaryEntry> = DiaryEntry.fetchRequest()
        request.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [
            NSPredicate(format: "child == %@", child),
            NSPredicate(format: "timestamp >= %@ AND timestamp < %@", start as NSDate, end as NSDate)
        ])
        let entries = try context.fetch(request)
        let types = Set(entries.map { DiaryEntryType.fromPersistence($0.entryType ?? "") })
        let required = Set(AppConstants.requiredDiaryTypesForCompleteDay.compactMap { DiaryEntryType(rawValue: $0) })
        let present = Set(required.filter { types.contains($0) })
        if present.isEmpty {
            return .none
        }
        if present == required {
            return .complete
        }
        return .partial
    }
}
