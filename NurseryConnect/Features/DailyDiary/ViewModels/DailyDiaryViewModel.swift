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

import Combine
import CoreData
import Foundation

/// - Description: Presentation fields for validating a new diary entry before save.
struct DiaryDraftValidation {
    var isValid: Bool
    var missingFields: [String]
}

/// - Description: Aggregated daily metrics derived from a child's diary entries.
struct DailyDiarySummary {
    var totalSleepMinutes: Int
    var totalFluidIntakeMl: Int
    var nappyChangesCount: Int
    var averageMoodRating: Double?
    var latestMoodRating: Int?
    var activeMinutes: Int
    var restMinutes: Int
    var activePercentage: Double?
}

/// - Description: Manages diary CRUD for a single child on the current calendar day.
@MainActor
final class DailyDiaryViewModel: ObservableObject {
    // MARK: - Published State

    @Published private(set) var entries: [DiaryEntry] = []
    @Published var errorMessage: String?

    /// - Description: Shared nursery schedule merged with today’s rows (sleep masks activity placeholders).
    var mergedTimelineRows: [MergedDiaryTimelineRow] {
        DayTimelineMerger.mergedRows(entries: entries, referenceDay: Date())
    }

    /// - Description: Consolidated overview of today's diary records for top-of-screen summary UI.
    var dailySummary: DailyDiarySummary {
        var sleepMinutes = 0
        var fluidIntakeMl = 0
        var nappyCount = 0
        var moodRatings: [Int] = []
        var latestMood: (rating: Int, timestamp: Date)?
        var activityMinutes = 0
        var mealMinutes = 0

        for entry in entries {
            let type = DiaryEntryType.fromPersistence(entry.entryType ?? "")
            switch type {
            case .sleep:
                sleepMinutes += max(Int(entry.duration), 0)
            case .meal:
                fluidIntakeMl += max(Int(entry.fluidIntake), 0)
                mealMinutes += max(Int(entry.duration), 0)
            case .nappy:
                nappyCount += 1
            case .wellbeing:
                let rating = Int(entry.moodRating)
                if rating > 0 {
                    moodRatings.append(rating)
                    let timestamp = entry.timestamp ?? .distantPast
                    if let currentLatest = latestMood {
                        if timestamp > currentLatest.timestamp {
                            latestMood = (rating: rating, timestamp: timestamp)
                        }
                    } else {
                        latestMood = (rating: rating, timestamp: timestamp)
                    }
                }
            case .activity:
                activityMinutes += max(Int(entry.duration), 0)
            case .milestone:
                continue
            }
        }

        let activeMinutes = activityMinutes + mealMinutes
        let restMinutes = sleepMinutes
        let denominator = activeMinutes + restMinutes
        let activePercentage: Double? = denominator > 0
            ? (Double(activeMinutes) / Double(denominator)) * 100
            : nil
        let averageMood = moodRatings.isEmpty ? nil : Double(moodRatings.reduce(0, +)) / Double(moodRatings.count)

        return DailyDiarySummary(
            totalSleepMinutes: sleepMinutes,
            totalFluidIntakeMl: fluidIntakeMl,
            nappyChangesCount: nappyCount,
            averageMoodRating: averageMood,
            latestMoodRating: latestMood?.rating,
            activeMinutes: activeMinutes,
            restMinutes: restMinutes,
            activePercentage: activePercentage
        )
    }

    // MARK: - Properties

    private let childID: UUID
    private let context: NSManagedObjectContext
    private let syncQueue: SyncQueueService

    // MARK: - Lifecycle

    /// - Description: Binds the view model to a child identifier and Core Data context.
    /// - Parameters:
    ///   - childID: Stable UUID for the child record.
    ///   - context: Managed object context (main queue).
    init(
        childID: UUID,
        context: NSManagedObjectContext,
        syncQueue: SyncQueueService? = nil
    ) {
        self.childID = childID
        self.context = context
        self.syncQueue = syncQueue ?? .shared
    }

    // MARK: - Public Methods

    /// - Description: Reloads today’s diary entries for the bound child, sorted by time ascending.
    func loadEntries() async {
        do {
            entries = try fetchTodayEntries()
            errorMessage = nil
        } catch {
            errorMessage = "Could not load diary entries."
        }
    }

    /// - Description: Persists a new diary entry for the current child.
    /// - Parameters:
    ///   - entry: Populated managed object (already inserted into the context).
    func saveNewEntry(_ entry: DiaryEntry) async {
        errorMessage = nil
        do {
            guard context.hasChanges else { return }
            try context.save()
            await syncQueue.enqueueDiary(entry)
            errorMessage = nil
            await loadEntries()
        } catch {
            context.delete(entry)
            errorMessage = "Unable to save this diary entry."
        }
    }

    /// - Description: Creates and saves a new diary entry using the view-model context.
    /// - Parameters:
    ///   - draft: Canonical values collected from the add-entry form.
    /// - Returns: `true` when the entry is saved successfully.
    @discardableResult
    func createEntry(from draft: DiaryEntryDraftValues) async -> Bool {
        errorMessage = nil
        do {
            guard let child = try fetchChild() else {
                errorMessage = "Missing child record."
                return false
            }
            guard let entry = NSEntityDescription.insertNewObject(
                forEntityName: "DiaryEntry",
                into: context
            ) as? DiaryEntry else {
                errorMessage = "Unable to create this diary entry."
                return false
            }
            entry.id = UUID()
            entry.submittedAt = Date()
            entry.child = child
            entry.isSubmittedToManager = false
            entry.applyDraft(draft)
            await saveNewEntry(entry)
            return errorMessage == nil
        } catch {
            errorMessage = "Unable to save this diary entry."
            return false
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

    /// - Description: Applies an auditable correction while preserving original values.
    /// - Parameters:
    ///   - entry: Existing diary row to update.
    ///   - draft: Replacement values that become the current timeline display.
    ///   - reason: Mandatory reason captured in correction history.
    /// - Returns: `true` when a correction was applied and persisted.
    @discardableResult
    func correctEntry(_ entry: DiaryEntry, with draft: DiaryEntryDraftValues, reason: String) async -> Bool {
        errorMessage = nil
        let trimmedReason = reason.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedReason.isEmpty else {
            errorMessage = "A correction reason is required."
            return false
        }

        let changes = entry.correctionChanges(comparedTo: draft)
        guard !changes.isEmpty else {
            errorMessage = "No changes detected to save."
            return false
        }

        entry.storeOriginalSnapshotIfNeeded()
        let correctedAt = Date()
        for change in changes {
            guard let correction = NSEntityDescription.insertNewObject(
                forEntityName: "DiaryEntryCorrection",
                into: context
            ) as? DiaryEntryCorrection else {
                errorMessage = "Could not update this entry."
                return false
            }
            correction.id = UUID()
            correction.correctedAt = correctedAt
            correction.reason = trimmedReason
            correction.fieldName = change.fieldName
            correction.oldValue = change.oldValue
            correction.newValue = change.newValue
            correction.entry = entry
        }

        entry.applyDraft(draft)
        entry.hasCorrections = true
        entry.lastCorrectedAt = correctedAt
        await persist(entry: entry, enqueueSync: true)
        let succeeded = (errorMessage == nil)
        if succeeded {
            errorMessage = nil
        }
        return succeeded
    }

    /// - Description: Returns effective queue state for sync status badges.
    func syncState(for entry: DiaryEntry) -> SyncState {
        SyncState.fromPersistence(entry.syncState)
    }

    /// - Description: Manually retries a failed diary sync from detail/list views.
    func retrySync(for entry: DiaryEntry) async {
        await syncQueue.retryDiary(entry)
        await loadEntries()
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
        milestoneDescription: String,
        isMealFluidOnly: Bool = false
    ) -> DiaryDraftValidation {
        var missing: [String] = []
        switch type {
        case .activity:
            if activityType.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty { missing.append("Activity type") }
            if eyfsArea.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty { missing.append("EYFS area") }
        case .meal:
            if !isMealFluidOnly && mealDescription.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                missing.append("Food description")
            }
        case .milestone:
            if milestoneDescription.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty { missing.append("Milestone description") }
        case .wellbeing:
            break
        default:
            break
        }
        if type != .wellbeing, notes.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            // Notes are required for every type in this MVP to support practitioner accountability.
            missing.append("Notes")
        }
        return DiaryDraftValidation(isValid: missing.isEmpty, missingFields: missing)
    }

    // MARK: - Private Methods

    /// - Description: Locates the `Child` entity backing this view model.
    /// - Returns: Matching child or `nil` if missing.
    private func fetchChild() throws -> Child? {
        let request = NSFetchRequest<Child>(entityName: "Child")
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
        let request = NSFetchRequest<DiaryEntry>(entityName: "DiaryEntry")
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
    private func persist(entry: DiaryEntry? = nil, enqueueSync: Bool = false) async {
        do {
            try context.save()
            if enqueueSync, let entry {
                await syncQueue.enqueueDiary(entry)
            }
            await loadEntries()
        } catch {
            if let entry {
                context.refresh(entry, mergeChanges: false)
            }
            errorMessage = "Could not update this entry."
        }
    }
}
