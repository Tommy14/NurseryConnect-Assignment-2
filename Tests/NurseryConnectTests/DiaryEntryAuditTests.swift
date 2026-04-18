//
//  DiaryEntryAuditTests.swift
//  NurseryConnectTests
//
//  Feature: Daily Diary
//  Role: Keyworker
//  Created: 16 April 2026
//  Description: Unit tests for event/submission audit gap flags.
//

import CoreData
import XCTest
@testable import NurseryConnect

@MainActor
final class DiaryEntryAuditTests: XCTestCase {
    func testNeedsLateLogManagerReviewFalseWhenNoSubmittedAt() {
        let stack = PersistenceController(inMemory: true)
        let entry = DiaryEntry(context: stack.container.viewContext)
        entry.timestamp = Date()
        entry.submittedAt = nil

        XCTAssertFalse(entry.needsLateLogManagerReview)
    }

    func testNeedsLateLogManagerReviewFalseAtExactThreshold() {
        let stack = PersistenceController(inMemory: true)
        let entry = DiaryEntry(context: stack.container.viewContext)
        let eventTime = Date()
        entry.timestamp = eventTime
        entry.submittedAt = eventTime.addingTimeInterval(AppConstants.diaryLateLogReviewThresholdSeconds)

        XCTAssertFalse(entry.needsLateLogManagerReview)
    }

    func testNeedsLateLogManagerReviewTrueJustOverThreshold() {
        let stack = PersistenceController(inMemory: true)
        let entry = DiaryEntry(context: stack.container.viewContext)
        let eventTime = Date()
        entry.timestamp = eventTime
        entry.submittedAt = eventTime.addingTimeInterval(AppConstants.diaryLateLogReviewThresholdSeconds + 1)

        XCTAssertTrue(entry.needsLateLogManagerReview)
    }

    func testNeedsLateLogManagerReviewUsesAbsoluteGapForFutureEventTime() {
        let stack = PersistenceController(inMemory: true)
        let entry = DiaryEntry(context: stack.container.viewContext)
        let submittedAt = Date()
        entry.submittedAt = submittedAt
        entry.timestamp = submittedAt.addingTimeInterval(AppConstants.diaryLateLogReviewThresholdSeconds + 1)

        XCTAssertTrue(entry.needsLateLogManagerReview)
    }
}
