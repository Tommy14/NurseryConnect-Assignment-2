//
//  DayTimelineMergerTests.swift
//  NurseryConnectTests
//
//  Feature: Daily Diary
//  Role: Keyworker
//  Created: 18 April 2026
//  Description: Unit tests for nursery schedule helpers and merged diary timeline.
//

import CoreData
import XCTest
@testable import NurseryConnect

final class DayTimelineMergerTests: XCTestCase {
    /// - Description: Last 10 minutes before lunch end (12:00–13:00) triggers meal-end allergy window.
    func testMealEndAllergyWindowLastTenMinutesBeforeLunchEnd() {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(secondsFromGMT: 0)!
        guard let noonDay = cal.date(from: DateComponents(year: 2026, month: 6, day: 10, hour: 0, minute: 0, second: 0)) else {
            XCTFail("Date")
            return
        }
        let dayStart = cal.startOfDay(for: noonDay)
        // Lunch ends 13:00 → 780 minutes; window [770, 780).
        guard let inWindow = cal.date(byAdding: .minute, value: 775, to: dayStart),
              let beforeWindow = cal.date(byAdding: .minute, value: 769, to: dayStart),
              let atEnd = cal.date(byAdding: .minute, value: 780, to: dayStart) else {
            XCTFail("Dates")
            return
        }
        XCTAssertTrue(NurseryDaySchedule.isWithinMinutesBeforeAnyMealEnd(reference: inWindow, minutes: 10, calendar: cal))
        XCTAssertFalse(NurseryDaySchedule.isWithinMinutesBeforeAnyMealEnd(reference: beforeWindow, minutes: 10, calendar: cal))
        XCTAssertFalse(NurseryDaySchedule.isWithinMinutesBeforeAnyMealEnd(reference: atEnd, minutes: 10, calendar: cal))
    }

    /// - Description: Allergy visibility shows 5 minutes before a meal and throughout the meal, then hides at meal end.
    func testMealVisibilityWindowFiveMinutesBeforeStartThroughMealEnd() {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(secondsFromGMT: 0)!
        guard let day = cal.date(from: DateComponents(year: 2026, month: 6, day: 10, hour: 0, minute: 0, second: 0)) else {
            XCTFail("Date")
            return
        }
        let dayStart = cal.startOfDay(for: day)
        // Lunch is [12:00, 13:00) => show allergies in [11:55, 13:00).
        guard let beforeWindow = cal.date(byAdding: .minute, value: 714, to: dayStart), // 11:54
              let atWindowStart = cal.date(byAdding: .minute, value: 715, to: dayStart), // 11:55
              let midMeal = cal.date(byAdding: .minute, value: 750, to: dayStart), // 12:30
              let atMealEnd = cal.date(byAdding: .minute, value: 780, to: dayStart) else { // 13:00
            XCTFail("Dates")
            return
        }

        XCTAssertFalse(NurseryDaySchedule.isWithinMealVisibilityWindow(reference: beforeWindow, minutesBeforeStart: 5, calendar: cal))
        XCTAssertTrue(NurseryDaySchedule.isWithinMealVisibilityWindow(reference: atWindowStart, minutesBeforeStart: 5, calendar: cal))
        XCTAssertTrue(NurseryDaySchedule.isWithinMealVisibilityWindow(reference: midMeal, minutesBeforeStart: 5, calendar: cal))
        XCTAssertFalse(NurseryDaySchedule.isWithinMealVisibilityWindow(reference: atMealEnd, minutesBeforeStart: 5, calendar: cal))
    }

    /// - Description: Sleep overlapping an activity block yields two planned session fragments for quiet rest plus one sleep row.
    func testSleepSplitsQuietRestActivityBlock() {
        let stack = PersistenceController(inMemory: true)
        let ctx = stack.container.viewContext
        let child = Child(context: ctx)
        child.id = UUID()
        child.firstName = "Test"
        child.lastName = "Child"

        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(identifier: "UTC")!
        guard let anchor = cal.date(from: DateComponents(year: 2026, month: 8, day: 1)) else {
            XCTFail("anchor")
            return
        }
        let dayStart = cal.startOfDay(for: anchor)
        guard let sleepStart = cal.date(bySettingHour: 13, minute: 30, second: 0, of: dayStart) else {
            XCTFail("sleepStart")
            return
        }

        let sleep = DiaryEntry(context: ctx)
        sleep.id = UUID()
        sleep.timestamp = sleepStart
        sleep.duration = 45
        sleep.entryType = DiaryEntryType.sleep.persistenceValue
        sleep.child = child

        let rows = DayTimelineMerger.mergedRows(entries: [sleep], referenceDay: dayStart, calendar: cal)
        let quietPieces = rows.compactMap { row -> String? in
            if case .plannedSession(let seg, _) = row, seg.block.id == "quiet_rest" {
                return "\(seg.start.timeIntervalSince1970)"
            }
            return nil
        }
        XCTAssertEqual(quietPieces.count, 2, "Quiet rest should split into two planned session fragments around sleep.")
        XCTAssertTrue(rows.contains { if case .sleep = $0 { return true }; return false })
    }

    /// - Description: A meal log in the lunch window appears only nested under the lunch planned session, not as a top-level diary row.
    func testMealLogNestsOnlyUnderLunchPlannedSession() {
        let stack = PersistenceController(inMemory: true)
        let ctx = stack.container.viewContext
        let child = Child(context: ctx)
        child.id = UUID()
        child.firstName = "Test"
        child.lastName = "Child"

        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(identifier: "UTC")!
        guard let anchor = cal.date(from: DateComponents(year: 2026, month: 8, day: 2)) else {
            XCTFail("anchor")
            return
        }
        let dayStart = cal.startOfDay(for: anchor)
        guard let lunchTime = cal.date(bySettingHour: 12, minute: 20, second: 0, of: dayStart) else {
            XCTFail("lunch")
            return
        }

        let meal = DiaryEntry(context: ctx)
        meal.id = UUID()
        meal.timestamp = lunchTime
        meal.entryType = DiaryEntryType.meal.persistenceValue
        meal.activityType = MealSlot.lunch.rawValue
        meal.mealDescription = "Pasta"
        meal.child = child

        let rows = DayTimelineMerger.mergedRows(entries: [meal], referenceDay: dayStart, calendar: cal)
        let lunchRow = rows.compactMap { row -> [DiaryEntry]? in
            if case .plannedSession(let seg, let nested) = row, seg.block.id == "lunch" { return nested }
            return nil
        }.first
        XCTAssertNotNil(lunchRow)
        XCTAssertEqual(lunchRow?.count, 1)
        XCTAssertEqual(lunchRow?.first?.objectID, meal.objectID)
        let topLevelMeal = rows.contains { row in
            if case .orphanDiary(let e) = row { return e.objectID == meal.objectID }
            return false
        }
        XCTAssertFalse(topLevelMeal, "Meal should not appear as an orphan row when it falls inside lunch.")
    }

    /// - Description: Activity log timestamp inside an activity block nests under that planned session only.
    func testActivityLogNestsUnderMidMorningSession() {
        let stack = PersistenceController(inMemory: true)
        let ctx = stack.container.viewContext
        let child = Child(context: ctx)
        child.id = UUID()
        child.firstName = "Test"
        child.lastName = "Child"

        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(identifier: "UTC")!
        guard let anchor = cal.date(from: DateComponents(year: 2026, month: 9, day: 1)) else {
            XCTFail("anchor")
            return
        }
        let dayStart = cal.startOfDay(for: anchor)
        guard let activityTime = cal.date(bySettingHour: 11, minute: 0, second: 0, of: dayStart) else {
            XCTFail("activity")
            return
        }

        let activity = DiaryEntry(context: ctx)
        activity.id = UUID()
        activity.timestamp = activityTime
        activity.entryType = DiaryEntryType.activity.persistenceValue
        activity.activityType = DiaryActivityKind.indoorPlay.rawValue
        activity.eyfsArea = EyfsArea.communication.rawValue
        activity.duration = 20
        activity.notes = "Building blocks."
        activity.child = child

        let rows = DayTimelineMerger.mergedRows(entries: [activity], referenceDay: dayStart, calendar: cal)
        let midMorningNested = rows.compactMap { row -> [DiaryEntry]? in
            if case .plannedSession(let seg, let nested) = row, seg.block.id == "mid_morning" { return nested }
            return nil
        }.first
        XCTAssertEqual(midMorningNested?.count, 1)
        XCTAssertEqual(midMorningNested?.first?.objectID, activity.objectID)
        XCTAssertFalse(rows.contains { if case .orphanDiary(let e) = $0 { return e.objectID == activity.objectID }; return false })
    }

    /// - Description: Entry timestamp outside any schedule segment is emitted as an orphan row.
    func testOrphanDiaryWhenOutsideScheduleSegments() {
        let stack = PersistenceController(inMemory: true)
        let ctx = stack.container.viewContext
        let child = Child(context: ctx)
        child.id = UUID()
        child.firstName = "Test"
        child.lastName = "Child"

        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(identifier: "UTC")!
        guard let anchor = cal.date(from: DateComponents(year: 2026, month: 9, day: 2)) else {
            XCTFail("anchor")
            return
        }
        let dayStart = cal.startOfDay(for: anchor)
        guard let lateTime = cal.date(bySettingHour: 19, minute: 0, second: 0, of: dayStart) else {
            XCTFail("late")
            return
        }

        let nappy = DiaryEntry(context: ctx)
        nappy.id = UUID()
        nappy.timestamp = lateTime
        nappy.entryType = DiaryEntryType.nappy.persistenceValue
        nappy.nappyType = NappyObservationKind.wet.rawValue
        nappy.notes = "Changed."
        nappy.child = child

        let rows = DayTimelineMerger.mergedRows(entries: [nappy], referenceDay: dayStart, calendar: cal)
        XCTAssertTrue(rows.contains { if case .orphanDiary(let e) = $0 { return e.objectID == nappy.objectID }; return false })
    }

    /// - Description: Current activity resolves to Sleeping when now lies inside a logged sleep interval.
    func testCurrentActivitySummarySleepingWhenInsideSleepInterval() {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(identifier: "UTC")!
        guard let anchor = cal.date(from: DateComponents(year: 2026, month: 8, day: 3)) else {
            XCTFail("anchor")
            return
        }
        let dayStart = cal.startOfDay(for: anchor)
        guard let sleepStart = cal.date(bySettingHour: 13, minute: 0, second: 0, of: dayStart),
              let now = cal.date(bySettingHour: 13, minute: 15, second: 0, of: dayStart) else {
            XCTFail("times")
            return
        }
        let end = sleepStart.addingTimeInterval(60 * 60)
        let summary = NurseryDaySchedule.currentActivitySummary(
            referenceNow: now,
            day: dayStart,
            sleepIntervals: [(sleepStart, end)],
            calendar: cal
        )
        XCTAssertEqual(summary, "Sleeping")
    }

    /// - Description: No logs means no planned session is covered.
    func testAllPlannedSessionsFalseWhenNoEntries() {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(identifier: "UTC")!
        guard let anchor = cal.date(from: DateComponents(year: 2026, month: 10, day: 1)) else {
            XCTFail("anchor")
            return
        }
        let dayStart = cal.startOfDay(for: anchor)
        XCTAssertFalse(DayTimelineMerger.allPlannedSessionsHaveAtLeastOneLog(entries: [], referenceDay: dayStart, calendar: cal))
    }

    /// - Description: A single meal log leaves other planned sessions empty.
    func testAllPlannedSessionsFalseWhenOnlyOneSegmentFilled() {
        let stack = PersistenceController(inMemory: true)
        let ctx = stack.container.viewContext
        let child = Child(context: ctx)
        child.id = UUID()
        child.firstName = "Test"
        child.lastName = "Child"

        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(identifier: "UTC")!
        guard let anchor = cal.date(from: DateComponents(year: 2026, month: 10, day: 2)) else {
            XCTFail("anchor")
            return
        }
        let dayStart = cal.startOfDay(for: anchor)
        guard let lunchTime = cal.date(bySettingHour: 12, minute: 20, second: 0, of: dayStart) else {
            XCTFail("lunch")
            return
        }

        let meal = DiaryEntry(context: ctx)
        meal.id = UUID()
        meal.timestamp = lunchTime
        meal.entryType = DiaryEntryType.meal.persistenceValue
        meal.activityType = MealSlot.lunch.rawValue
        meal.mealDescription = "Pasta"
        meal.child = child

        XCTAssertFalse(DayTimelineMerger.allPlannedSessionsHaveAtLeastOneLog(entries: [meal], referenceDay: dayStart, calendar: cal))
    }

    /// - Description: Dashboard “complete” when every timetable segment has at least one non-sleep log.
    func testAllPlannedSessionsTrueWhenEachSegmentHasNonSleepLog() {
        let stack = PersistenceController(inMemory: true)
        let ctx = stack.container.viewContext
        let child = Child(context: ctx)
        child.id = UUID()
        child.firstName = "Test"
        child.lastName = "Child"

        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(identifier: "UTC")!
        guard let anchor = cal.date(from: DateComponents(year: 2026, month: 10, day: 6)) else {
            XCTFail("anchor")
            return
        }
        let dayStart = cal.startOfDay(for: anchor)
        let segments = DayTimelineMerger.plannedSegmentsForDay(entries: [], referenceDay: dayStart, calendar: cal)
        XCTAssertGreaterThanOrEqual(segments.count, 1)

        for seg in segments {
            let e = DiaryEntry(context: ctx)
            e.id = UUID()
            e.timestamp = seg.start.addingTimeInterval(120)
            e.entryType = DiaryEntryType.nappy.persistenceValue
            e.nappyType = NappyObservationKind.wet.rawValue
            e.notes = "ok"
            e.child = child
        }
        try? ctx.save()

        let fetch = DiaryEntry.fetchRequest()
        fetch.predicate = NSPredicate(format: "child == %@", child)
        let all = (try? ctx.fetch(fetch)) ?? []
        XCTAssertTrue(DayTimelineMerger.allPlannedSessionsHaveAtLeastOneLog(entries: all, referenceDay: dayStart, calendar: cal))
    }
}
