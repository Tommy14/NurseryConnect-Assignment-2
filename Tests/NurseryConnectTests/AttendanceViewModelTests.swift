//
//  AttendanceViewModelTests.swift
//  NurseryConnectTests
//
//  Feature: Attendance
//  Role: Keyworker
//  Created: 16 April 2026
//  Description: Unit tests for today’s attendance persistence and validation.
//

import CoreData
import XCTest
@testable import NurseryConnect

@MainActor
final class AttendanceViewModelTests: XCTestCase {
    func testCheckInThenCheckOutHappyPath() async {
        let stack = PersistenceController(inMemory: true)
        let ctx = stack.container.viewContext
        let childId = insertChild(authorisedCollectors: "Parent One\nParent Two", in: ctx)

        let vm = AttendanceViewModel(childID: childId, context: ctx)
        await vm.load()
        XCTAssertEqual(vm.phase, .expected)

        let arrival = Date()
        await vm.checkIn(at: arrival, droppedOffBy: "Grandparent")
        XCTAssertNil(vm.errorMessage)
        XCTAssertEqual(vm.phase, .onPremises)
        XCTAssertEqual(vm.droppedOffBy, "Grandparent")

        let departure = arrival.addingTimeInterval(3600)
        await vm.checkOut(at: departure, collectedBy: "Parent One")
        XCTAssertNil(vm.errorMessage)
        XCTAssertEqual(vm.phase, .departed)
        XCTAssertEqual(vm.collectedBy, "Parent One")
    }

    func testCheckOutRejectsNonAuthorisedName() async {
        let stack = PersistenceController(inMemory: true)
        let ctx = stack.container.viewContext
        let childId = insertChild(authorisedCollectors: "Only Authorised", in: ctx)

        let vm = AttendanceViewModel(childID: childId, context: ctx)
        await vm.load()
        await vm.checkIn(at: Date(), droppedOffBy: "Someone")

        await vm.checkOut(at: Date(), collectedBy: "Not On List")
        XCTAssertNotNil(vm.errorMessage)
        XCTAssertEqual(vm.phase, .onPremises)
    }

    func testCheckOutBlockedWhenNoAuthorisedCollectors() async {
        let stack = PersistenceController(inMemory: true)
        let ctx = stack.container.viewContext
        let childId = insertChild(authorisedCollectors: "", in: ctx)

        let vm = AttendanceViewModel(childID: childId, context: ctx)
        await vm.load()
        await vm.checkIn(at: Date(), droppedOffBy: "Drop off")

        await vm.checkOut(at: Date(), collectedBy: "Anyone")
        XCTAssertNotNil(vm.errorMessage)
        XCTAssertEqual(vm.phase, .onPremises)
    }

    func testReportUnauthorisedCollectionCreatesSafeguardingIncident() async throws {
        let stack = PersistenceController(inMemory: true)
        let ctx = stack.container.viewContext
        let childId = insertChild(authorisedCollectors: "Parent One", in: ctx)

        let vm = AttendanceViewModel(childID: childId, context: ctx)
        await vm.load()
        await vm.checkIn(at: Date(), droppedOffBy: "Parent One")

        let ok = await vm.reportUnauthorisedCollectionAttempt(additionalNotes: "Claimed to be uncle.")
        XCTAssertTrue(ok)
        XCTAssertNil(vm.errorMessage)

        let req: NSFetchRequest<Incident> = Incident.fetchRequest()
        let incidents = try ctx.fetch(req)
        XCTAssertEqual(incidents.count, 1)
        let incident = try XCTUnwrap(incidents.first)
        XCTAssertEqual(incident.category, IncidentCategory.safeguardingConcern.persistenceValue)
        XCTAssertEqual(incident.status, IncidentStatus.submitted.persistenceValue)
        XCTAssertTrue(incident.incidentDescription?.contains("uncle") == true)
    }

    func testMarkAbsentTodayThenClear() async throws {
        let stack = PersistenceController(inMemory: true)
        let ctx = stack.container.viewContext
        let childId = insertChild(authorisedCollectors: "Parent", in: ctx)

        let vm = AttendanceViewModel(childID: childId, context: ctx)
        await vm.load()
        XCTAssertEqual(vm.phase, .expected)

        await vm.markAbsentToday()
        XCTAssertNil(vm.errorMessage)
        XCTAssertEqual(vm.phase, .absent)

        await vm.clearMarkedAbsent()
        XCTAssertNil(vm.errorMessage)
        XCTAssertEqual(vm.phase, .expected)
    }

    func testCheckInClearsMarkedAbsent() async throws {
        let stack = PersistenceController(inMemory: true)
        let ctx = stack.container.viewContext
        let childId = insertChild(authorisedCollectors: "Parent", in: ctx)

        let vm = AttendanceViewModel(childID: childId, context: ctx)
        await vm.load()
        await vm.markAbsentToday()
        XCTAssertEqual(vm.phase, .absent)

        await vm.checkIn(at: Date(), droppedOffBy: "Parent")
        XCTAssertNil(vm.errorMessage)
        XCTAssertEqual(vm.phase, .onPremises)

        let req: NSFetchRequest<AttendanceRecord> = AttendanceRecord.fetchRequest()
        let records = try ctx.fetch(req)
        XCTAssertEqual(records.count, 1)
        XCTAssertEqual(records.first?.markedAbsent, false)
    }

    func testFetchOrCreateSingleRecordPerDay() async throws {
        let stack = PersistenceController(inMemory: true)
        let ctx = stack.container.viewContext
        let childId = insertChild(authorisedCollectors: "A", in: ctx)

        let fetch: NSFetchRequest<AttendanceRecord> = AttendanceRecord.fetchRequest()
        XCTAssertEqual(try ctx.count(for: fetch), 0)

        let vm = AttendanceViewModel(childID: childId, context: ctx)
        await vm.load()
        await vm.checkIn(at: Date(), droppedOffBy: "First")
        XCTAssertEqual(try ctx.count(for: fetch), 1)

        await vm.checkIn(at: Date(), droppedOffBy: "Second correction")
        XCTAssertEqual(try ctx.count(for: fetch), 1)
        XCTAssertEqual(vm.droppedOffBy, "Second correction")
    }

    // MARK: - Helpers

    private func insertChild(authorisedCollectors: String, in ctx: NSManagedObjectContext) -> UUID {
        let child = Child(context: ctx)
        let id = UUID()
        child.id = id
        child.firstName = "Test"
        child.lastName = "Pupil"
        child.dateOfBirth = Date()
        child.keyworkerName = AppConstants.keyworkerDisplayName
        child.authorisedCollectors = authorisedCollectors
        try! ctx.save()
        return id
    }
}
