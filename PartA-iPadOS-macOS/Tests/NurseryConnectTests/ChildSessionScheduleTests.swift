//
//  ChildSessionScheduleTests.swift
//  NurseryConnectTests
//

import XCTest
@testable import NurseryConnect

final class ChildSessionScheduleTests: XCTestCase {
    private var calendar: Calendar {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(secondsFromGMT: 0)!
        return cal
    }

    func testDefaultWeekdaysAreMondayThroughFriday() {
        XCTAssertEqual(ChildSessionSchedule.weekdays(from: nil), [2, 3, 4, 5, 6])
        XCTAssertEqual(ChildSessionSchedule.weekdays(from: ""), [2, 3, 4, 5, 6])
    }

    func testParsesStoredWeekdayList() {
        XCTAssertEqual(ChildSessionSchedule.weekdays(from: "2,4,6"), [2, 4, 6])
    }

    func testIsExpectedOnScheduledWeekday() {
        let monday = calendar.date(from: DateComponents(year: 2026, month: 6, day: 15, hour: 8))!
        XCTAssertTrue(ChildSessionSchedule.isExpected(on: monday, sessionWeekdays: "2,3,4,5,6", calendar: calendar))
    }

    func testIsNotExpectedOnUnscheduledWeekday() {
        let sunday = calendar.date(from: DateComponents(year: 2026, month: 6, day: 14, hour: 8))!
        XCTAssertFalse(ChildSessionSchedule.isExpected(on: sunday, sessionWeekdays: "2,3,4,5,6", calendar: calendar))
    }
}
