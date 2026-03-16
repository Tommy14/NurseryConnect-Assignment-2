//
//  DailyDiaryViewModel.swift
//  NurseryConnect
//
//  Feature: Daily Diary
//  Role: Keyworker
//  Created: 3 April 2026
//  Description: Fetches today’s diary rows, validates new entries, and persists updates.
//
// -----------------------------------------------------------------
// Date       Name        What has done
// -----------------------------------------------------------------
// 030426     Tommy1914   Created the file with fetch, save, delete, and validation helpers.
// -----------------------------------------------------------------

import CoreData
import Foundation

/// - Description: Presentation fields for validating a new diary entry before save.
struct DiaryDraftValidation {
    var isValid: Bool
    var missingFields: [String]
}

/// - Description: Manages diary CRUD for a single child on the current calendar day.
@MainActor
final class DailyDiaryViewModel: ObservableObject {
    // MARK: - Published State

    @Published private(set) var entries: [DiaryEntry] = []
    @Published var errorMessage: String?

    // MARK: - Properties

    private let childID: UUID
    private let context: NSManagedObjectContext

    // MARK: - Lifecycle

    /// - Description: Binds the view model to a child identifier and Core Data context.
    /// - Parameters:
    ///   - childID: Stable UUID for the child record.
    ///   - context: Managed object context (main queue).
    init(childID: UUID, context: NSManagedObjectContext) {
        self.childID = childID
        self.context = context
    }

    // MARK: - Public Methods

    /// - Description: Reloads today’s diary entries for the bound child, sorted by time ascending.
    func loadEntries() async {
        do {
            entries = try fetchTodayEntries()
        } catch {
            errorMessage = "Could not load diary entries."
        }
    }

    /// - Description: Persists a new diary entry for the current child.
    /// - Parameters:
    ///   - entry: Populated managed object (already inserted into the context).
    func saveNewEntry(_ entry: DiaryEntry) async {
        do {
            guard context.hasChanges else { return }
            try context.save()
            await loadEntries()
        } catch {
            context.delete(entry)
            errorMessage = "Unable to save this diary entry."
        }
    }

    /// - Description: Updates submission state for room-leader handover.
    /// - Parameters:
    ///   - entry: Target diary row.
    ///   - submitted: New submission flag.
    func updateSubmission(_ entry: DiaryEntry, submitted: Bool) async {
        entry.isSubmittedToManager = submitted
        await persist(entry: entry)
    }

    /// - Description: Deletes a diary entry after confirmation in the UI.
    /// - Parameters:
    ///   - entry: Row to remove.
    func delete(entry: DiaryEntry) async {
        context.delete(entry)
        await persistDelete()
    }

    /// - Description: Validates type-specific mandatory fields for the add form.
    /// - Parameters:
    ///   - type: Selected diary type.
    ///   - notes: Free-text notes (may be required depending on type).
    ///   - activityType: Activity label when relevant.
    ///   - eyfsArea: Learning area when relevant.
    ///   - mealDescription: Meal description when relevant.
    ///   - milestoneDescription: Milestone text when relevant.
    /// - Returns: Validation summary for inline error display.
    func validate(
        type: DiaryEntryType,
        notes: String,
        activityType: String,
        eyfsArea: String,
        mealDescription: String,
        milestoneDescription: String
    ) -> DiaryDraftValidation {
        var missing: [String] = []
        switch type {
        case .activity:
            if activityType.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty { missing.append("Activity type") }
            if eyfsArea.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty { missing.append("EYFS area") }
        case .meal:
            if mealDescription.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty { missing.append("Food description") }
        case .milestone:
            if milestoneDescription.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty { missing.append("Milestone description") }
        case .wellbeing:
            break
        default:
            break
        }
        if notes.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            // Notes are required for every type in this MVP to support practitioner accountability.
            missing.append("Notes")
        }
        return DiaryDraftValidation(isValid: missing.isEmpty, missingFields: missing)
    }

    // MARK: - Private Methods

    /// - Description: Locates the `Child` entity backing this view model.
    /// - Returns: Matching child or `nil` if missing.
    private func fetchChild() throws -> Child? {
        let request: NSFetchRequest<Child> = Child.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", childID as CVarArg)
        request.fetchLimit = 1
        return try context.fetch(request).first
    }

    /// - Description: Retrieves today’s diary rows for the child.
    /// - Returns: Sorted `DiaryEntry` results.
    private func fetchTodayEntries() throws -> [DiaryEntry] {
        guard let child = try fetchChild() else { return [] }
        let start = Date().startOfDay
        let end = Date().endOfDay
        let request: NSFetchRequest<DiaryEntry> = DiaryEntry.fetchRequest()
        request.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [
            NSPredicate(format: "child == %@", child),
            NSPredicate(format: "timestamp >= %@ AND timestamp < %@", start as NSDate, end as NSDate)
        ])
        request.sortDescriptors = [NSSortDescriptor(keyPath: \DiaryEntry.timestamp, ascending: true)]
        return try context.fetch(request)
    }

    /// - Description: Saves the context after a mutation, surfacing failures.
    /// - Parameters:
    ///   - entry: Optional entry for rollback on failure.
    private func persist(entry: DiaryEntry? = nil) async {
        do {
            try context.save()
            await loadEntries()
        } catch {
            if let entry {
                context.refresh(entry, mergeChanges: false)
            }
            errorMessage = "Could not update this entry."
        }
    }

    /// - Description: Persists after a deletion operation.
    private func persistDelete() async {
        do {
            try context.save()
            await loadEntries()
        } catch {
            errorMessage = "Could not delete this entry."
        }
    }
}
