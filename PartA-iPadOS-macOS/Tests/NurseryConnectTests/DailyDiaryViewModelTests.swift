//
//  DailyDiaryViewModelTests.swift
//  NurseryConnectTests
//
//  Feature: Daily Diary
//  Role: Keyworker
//  Created: 10 April 2026
//  Description: Unit tests for diary validation and persistence helpers.
//
// -----------------------------------------------------------------
// Date       Name        What has done
// -----------------------------------------------------------------
// 100426     Tommy1914   Created the file with validation and in-memory Core Data checks.
// -----------------------------------------------------------------

import CoreData
import XCTest
@testable import NurseryConnect

@MainActor
final class DailyDiaryViewModelTests: XCTestCase {
    /// - Description: Ensures activity entries require notes for accountability.
    func testValidationFlagsMissingNotesForActivity() {
        let stack = PersistenceController(inMemory: true)
        let vm = DailyDiaryViewModel(childID: UUID(), context: stack.container.viewContext)
        let result = vm.validate(
            type: .activity,
            notes: "",
            activityType: "Indoor Play",
            eyfsArea: EyfsArea.communication.rawValue,
            mealDescription: "",
            milestoneDescription: ""
        )
        XCTAssertFalse(result.isValid)
        XCTAssertTrue(result.missingFields.contains("Notes"))
    }

    /// - Description: Confirms wellbeing entries allow empty notes when mood alone is captured elsewhere.
    func testValidationAllowsEmptyNotesForWellbeing() {
        let stack = PersistenceController(inMemory: true)
        let vm = DailyDiaryViewModel(childID: UUID(), context: stack.container.viewContext)
        let result = vm.validate(
            type: .wellbeing,
            notes: "",
            activityType: "",
            eyfsArea: "",
            mealDescription: "",
            milestoneDescription: ""
        )
        XCTAssertTrue(result.isValid)
    }

    func testCorrectionRequiresReason() async {
        let stack = PersistenceController(inMemory: true)
        let context = stack.container.viewContext
        let child = makeChild(context: context)
        let entry = makeDiaryEntry(context: context, child: child)
        try? context.save()

        let vm = DailyDiaryViewModel(childID: child.id ?? UUID(), context: context)
        let draft = DiaryEntryDraftValues(
            timestamp: entry.timestamp ?? Date(),
            entryType: .activity,
            notes: "Updated notes",
            activityType: "Indoor Play",
            eyfsArea: EyfsArea.communication.rawValue,
            duration: 15,
            mealDescription: "",
            mealConsumed: nil,
            fluidIntake: 0,
            fluidType: "",
            nappyType: "",
            moodRating: 0,
            sleepPosition: "",
            milestonePhotoData: nil,
            milestonePhotoMimeType: "",
            milestonePhotoBlurredFaceCount: 0
        )

        let ok = await vm.correctEntry(entry, with: draft, reason: " ")
        XCTAssertFalse(ok)
        XCTAssertEqual(vm.errorMessage, "A correction reason is required.")
    }

    func testFirstCorrectionStoresOriginalSnapshotAndHistory() async {
        let stack = PersistenceController(inMemory: true)
        let context = stack.container.viewContext
        let child = makeChild(context: context)
        let entry = makeDiaryEntry(context: context, child: child)
        try? context.save()

        let vm = DailyDiaryViewModel(childID: child.id ?? UUID(), context: context)
        let draft = DiaryEntryDraftValues(
            timestamp: entry.timestamp ?? Date(),
            entryType: .activity,
            notes: "Corrected note",
            activityType: "Outdoor Play",
            eyfsArea: EyfsArea.physical.rawValue,
            duration: 20,
            mealDescription: "",
            mealConsumed: nil,
            fluidIntake: 0,
            fluidType: "",
            nappyType: "",
            moodRating: 0,
            sleepPosition: "",
            milestonePhotoData: nil,
            milestonePhotoMimeType: "",
            milestonePhotoBlurredFaceCount: 0
        )

        let ok = await vm.correctEntry(entry, with: draft, reason: "Typo fixed")
        XCTAssertTrue(ok)
        XCTAssertTrue(entry.hasCorrections)
        XCTAssertNotNil(entry.originalSnapshotJSON)
        XCTAssertEqual(entry.notes, "Corrected note")
        XCTAssertGreaterThan(entry.sortedCorrections.count, 0)
    }

    func testSubsequentCorrectionKeepsOriginalSnapshot() async {
        let stack = PersistenceController(inMemory: true)
        let context = stack.container.viewContext
        let child = makeChild(context: context)
        let entry = makeDiaryEntry(context: context, child: child)
        try? context.save()

        let vm = DailyDiaryViewModel(childID: child.id ?? UUID(), context: context)
        let firstDraft = DiaryEntryDraftValues(
            timestamp: entry.timestamp ?? Date(),
            entryType: .activity,
            notes: "First correction",
            activityType: "Outdoor Play",
            eyfsArea: EyfsArea.physical.rawValue,
            duration: 20,
            mealDescription: "",
            mealConsumed: nil,
            fluidIntake: 0,
            fluidType: "",
            nappyType: "",
            moodRating: 0,
            sleepPosition: "",
            milestonePhotoData: nil,
            milestonePhotoMimeType: "",
            milestonePhotoBlurredFaceCount: 0
        )
        _ = await vm.correctEntry(entry, with: firstDraft, reason: "Initial correction")
        let originalSnapshot = entry.originalSnapshotJSON

        let secondDraft = DiaryEntryDraftValues(
            timestamp: entry.timestamp ?? Date(),
            entryType: .activity,
            notes: "Second correction",
            activityType: "Reading",
            eyfsArea: EyfsArea.literacy.rawValue,
            duration: 25,
            mealDescription: "",
            mealConsumed: nil,
            fluidIntake: 0,
            fluidType: "",
            nappyType: "",
            moodRating: 0,
            sleepPosition: "",
            milestonePhotoData: nil,
            milestonePhotoMimeType: "",
            milestonePhotoBlurredFaceCount: 0
        )
        _ = await vm.correctEntry(entry, with: secondDraft, reason: "More precise wording")

        XCTAssertEqual(entry.originalSnapshotJSON, originalSnapshot)
        XCTAssertEqual(entry.notes, "Second correction")
        XCTAssertGreaterThan(entry.sortedCorrections.count, 1)
    }

    private func makeChild(context: NSManagedObjectContext) -> Child {
        guard let child = NSEntityDescription.insertNewObject(
            forEntityName: "Child",
            into: context
        ) as? Child else {
            XCTFail("Failed to create Child entity.")
            fatalError("Failed to create Child entity.")
        }
        child.id = UUID()
        child.firstName = "Test"
        child.lastName = "Child"
        child.dateOfBirth = Date()
        return child
    }

    private func makeDiaryEntry(context: NSManagedObjectContext, child: Child) -> DiaryEntry {
        guard let entry = NSEntityDescription.insertNewObject(
            forEntityName: "DiaryEntry",
            into: context
        ) as? DiaryEntry else {
            XCTFail("Failed to create DiaryEntry entity.")
            fatalError("Failed to create DiaryEntry entity.")
        }
        entry.id = UUID()
        entry.child = child
        entry.timestamp = Date()
        entry.submittedAt = Date()
        entry.entryType = DiaryEntryType.activity.persistenceValue
        entry.notes = "Original note"
        entry.activityType = "Indoor Play"
        entry.eyfsArea = EyfsArea.communication.rawValue
        entry.duration = 15
        entry.isSubmittedToManager = false
        return entry
    }
}
