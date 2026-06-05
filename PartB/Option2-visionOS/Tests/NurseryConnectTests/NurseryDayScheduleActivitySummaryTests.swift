//
//  NurseryDayScheduleActivitySummaryTests.swift
//  NurseryConnectTests
//

import XCTest
@testable import NurseryConnect

final class NurseryDayScheduleActivitySummaryTests: XCTestCase {
    func testCheckedOutOverridesSchedule() {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(secondsFromGMT: 0)!
        guard let day = cal.date(from: DateComponents(year: 2026, month: 6, day: 10, hour: 0, minute: 0)) else {
            XCTFail("day")
            return
        }
        guard let noon = cal.date(byAdding: .hour, value: 12, to: cal.startOfDay(for: day)) else {
            XCTFail("noon")
            return
        }
        let out = noon
        let summary = NurseryDaySchedule.currentActivitySummary(
            referenceNow: noon,
            day: day,
            sleepIntervals: [],
            checkInAt: cal.date(byAdding: .hour, value: 8, to: cal.startOfDay(for: day)),
            checkOutAt: out,
            usesAttendanceForActivityLine: true,
            calendar: cal
        )
        XCTAssertEqual(summary, "Checked out")
    }

    func testNotCheckedInWhenAttendanceRowExists() {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(secondsFromGMT: 0)!
        guard let day = cal.date(from: DateComponents(year: 2026, month: 6, day: 10, hour: 0, minute: 0)) else {
            XCTFail("day")
            return
        }
        guard let noon = cal.date(byAdding: .hour, value: 12, to: cal.startOfDay(for: day)) else {
            XCTFail("noon")
            return
        }
        let summary = NurseryDaySchedule.currentActivitySummary(
            referenceNow: noon,
            day: day,
            sleepIntervals: [],
            checkInAt: nil,
            checkOutAt: nil,
            usesAttendanceForActivityLine: true,
            calendar: cal
        )
        XCTAssertEqual(summary, "Not checked in")
    }

    func testIgnoresAttendanceWhenNotTrackedUsesSchedule() {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(secondsFromGMT: 0)!
        guard let day = cal.date(from: DateComponents(year: 2026, month: 6, day: 10, hour: 0, minute: 0)) else {
            XCTFail("day")
            return
        }
        guard let lunchTime = cal.date(byAdding: .minute, value: 12 * 60 + 30, to: cal.startOfDay(for: day)) else {
            XCTFail("lunch")
            return
        }
        let summary = NurseryDaySchedule.currentActivitySummary(
            referenceNow: lunchTime,
            day: day,
            sleepIntervals: [],
            checkInAt: nil,
            checkOutAt: nil,
            usesAttendanceForActivityLine: false,
            calendar: cal
        )
        XCTAssertTrue(summary.hasPrefix("Now:"))
    }

    func testScheduleOnlyFallbackOutsideHours() {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(secondsFromGMT: 0)!
        guard let day = cal.date(from: DateComponents(year: 2026, month: 6, day: 10, hour: 0, minute: 0)) else {
            XCTFail("day")
            return
        }
        guard let late = cal.date(byAdding: .hour, value: 19, to: cal.startOfDay(for: day)) else {
            XCTFail("late")
            return
        }
        let summary = NurseryDaySchedule.currentActivitySummary(
            referenceNow: late,
            day: day,
            sleepIntervals: [],
            calendar: cal
        )
        XCTAssertEqual(summary, "Outside nursery hours")
    }

    func testDiaryLoggingPermittedOnlyBetweenSessionOpenAndTwoHoursAfterClose() {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(secondsFromGMT: 0)!
        let sod = cal.date(from: DateComponents(year: 2026, month: 6, day: 10, hour: 0, minute: 0))!
        func time(hour: Int, minute: Int) -> Date {
            cal.date(byAdding: DateComponents(hour: hour, minute: minute), to: sod)!
        }

        XCTAssertFalse(NurseryDaySchedule.isDiaryLoggingPermitted(at: time(hour: 7, minute: 59), calendar: cal))
        XCTAssertTrue(NurseryDaySchedule.isDiaryLoggingPermitted(at: time(hour: 8, minute: 0), calendar: cal))
        XCTAssertTrue(NurseryDaySchedule.isDiaryLoggingPermitted(at: time(hour: 12, minute: 0), calendar: cal))
        XCTAssertTrue(NurseryDaySchedule.isDiaryLoggingPermitted(at: time(hour: 20, minute: 0), calendar: cal))
        XCTAssertFalse(NurseryDaySchedule.isDiaryLoggingPermitted(at: time(hour: 20, minute: 1), calendar: cal))
    }
}
