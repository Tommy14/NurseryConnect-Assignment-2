//
//  KeyworkerAttendanceBucketTests.swift
//  NurseryConnectTests
//

import XCTest
@testable import NurseryConnect

final class KeyworkerAttendanceBucketTests: XCTestCase {
    func testDepartedOverridesAbsentAndCheckIn() {
        let out = Date()
        XCTAssertEqual(
            KeyworkerAttendanceBucket.resolve(checkOutAt: out, checkInAt: Date(), markedAbsent: true),
            .departed
        )
    }

    func testAbsentWhenCheckedOutNilAndMarkedAbsent() {
        XCTAssertEqual(
            KeyworkerAttendanceBucket.resolve(checkOutAt: nil, checkInAt: nil, markedAbsent: true),
            .absent
        )
    }

    func testOnSiteWhenCheckedInAndNotAbsent() {
        let t = Date()
        XCTAssertEqual(
            KeyworkerAttendanceBucket.resolve(checkOutAt: nil, checkInAt: t, markedAbsent: false),
            .onSite
        )
    }

    func testAwaitingWhenNoCheckInAndNotMarkedAbsent() {
        XCTAssertEqual(
            KeyworkerAttendanceBucket.resolve(checkOutAt: nil, checkInAt: nil, markedAbsent: false),
            .awaiting
        )
    }
}
