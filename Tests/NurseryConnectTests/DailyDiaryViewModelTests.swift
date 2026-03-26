//
//  DailyDiaryViewModelTests.swift
//  NurseryConnectTests
//
//  Feature: Daily Diary
//  Role: Keyworker
//  Created: 11 April 2026
//  Description: Unit tests for diary validation and persistence helpers.
//
// -----------------------------------------------------------------
// Date       Name        What has done
// -----------------------------------------------------------------
// 110426     Tommy1914   Created the file with validation and in-memory Core Data checks.
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
}
