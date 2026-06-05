//
//  KeyworkerMoodReminderSchedulerTests.swift
//  NurseryConnectTests
//

import XCTest
@testable import NurseryConnect

final class KeyworkerMoodReminderSchedulerTests: XCTestCase {
    func testAllowedReminderDayIsMondayToSaturdayOnly() {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(secondsFromGMT: 0)!

        let monday = cal.date(from: DateComponents(year: 2026, month: 6, day: 8, hour: 9, minute: 0))!
        let saturday = cal.date(from: DateComponents(year: 2026, month: 6, day: 13, hour: 9, minute: 0))!
        let sunday = cal.date(from: DateComponents(year: 2026, month: 6, day: 14, hour: 9, minute: 0))!

        XCTAssertTrue(KeyworkerMoodReminderScheduler.isAllowedReminderDay(monday, calendar: cal))
        XCTAssertTrue(KeyworkerMoodReminderScheduler.isAllowedReminderDay(saturday, calendar: cal))
        XCTAssertFalse(KeyworkerMoodReminderScheduler.isAllowedReminderDay(sunday, calendar: cal))
    }

    func testMaintenanceWindowIsSundayTwoToFourUtcOnly() {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(secondsFromGMT: 0)!

        let justBefore = cal.date(from: DateComponents(year: 2026, month: 6, day: 14, hour: 1, minute: 59))!
        let inside = cal.date(from: DateComponents(year: 2026, month: 6, day: 14, hour: 2, minute: 30))!
        let boundary = cal.date(from: DateComponents(year: 2026, month: 6, day: 14, hour: 4, minute: 0))!
        let weekday = cal.date(from: DateComponents(year: 2026, month: 6, day: 15, hour: 2, minute: 30))!

        XCTAssertFalse(KeyworkerMoodReminderScheduler.isWithinMaintenanceWindowUTC(justBefore))
        XCTAssertTrue(KeyworkerMoodReminderScheduler.isWithinMaintenanceWindowUTC(inside))
        XCTAssertFalse(KeyworkerMoodReminderScheduler.isWithinMaintenanceWindowUTC(boundary))
        XCTAssertFalse(KeyworkerMoodReminderScheduler.isWithinMaintenanceWindowUTC(weekday))
    }

    func testPreMealAllergyRemindersAreFiveMinutesBeforeEachMeal() {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(secondsFromGMT: 0)!
        let reference = cal.date(from: DateComponents(year: 2026, month: 6, day: 10, hour: 0, minute: 0))!

        let reminders = KeyworkerMoodReminderScheduler.preMealAllergyReminderDates(
            on: reference,
            leadMinutes: 5,
            calendar: cal
        )

        let expected = [
            DateComponents(hour: 7, minute: 55),
            DateComponents(hour: 9, minute: 55),
            DateComponents(hour: 11, minute: 55),
            DateComponents(hour: 14, minute: 25)
        ]

        XCTAssertEqual(reminders.count, expected.count)
        for (date, component) in zip(reminders, expected) {
            XCTAssertEqual(cal.component(.hour, from: date), component.hour)
            XCTAssertEqual(cal.component(.minute, from: date), component.minute)
        }
    }
}
