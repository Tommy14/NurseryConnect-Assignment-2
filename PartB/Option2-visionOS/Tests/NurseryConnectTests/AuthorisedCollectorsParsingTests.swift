//
//  AuthorisedCollectorsParsingTests.swift
//  NurseryConnectTests
//
//  Feature: Core
//  Role: Keyworker
//  Created: 16 April 2026
//  Description: Unit tests for authorised collector line parsing and checkout validation.
//

import XCTest
@testable import NurseryConnect

final class AuthorisedCollectorsParsingTests: XCTestCase {
    func testLinesEmptyWhenNil() {
        XCTAssertEqual(AuthorisedCollectorsParsing.lines(from: nil), [])
    }

    func testLinesEmptyWhenBlank() {
        XCTAssertEqual(AuthorisedCollectorsParsing.lines(from: "   \n  \n"), [])
    }

    func testLinesSingleTrimmed() {
        XCTAssertEqual(
            AuthorisedCollectorsParsing.lines(from: "  Maya Perera  "),
            ["Maya Perera"]
        )
    }

    func testLinesMultipleNewlines() {
        let raw = "Tharani Adithya\nRohan Adithya\nMaya Perera (aunt)"
        XCTAssertEqual(
            AuthorisedCollectorsParsing.lines(from: raw),
            ["Tharani Adithya", "Rohan Adithya", "Maya Perera (aunt)"]
        )
    }

    func testIsAuthorisedCollectorExactMatch() {
        let allowed = ["Alice", "Bob"]
        XCTAssertTrue(AuthorisedCollectorsParsing.isAuthorisedCollector("Alice", allowedLines: allowed))
        XCTAssertTrue(AuthorisedCollectorsParsing.isAuthorisedCollector("Alice ", allowedLines: allowed))
        XCTAssertFalse(AuthorisedCollectorsParsing.isAuthorisedCollector("Alicia", allowedLines: allowed))
        XCTAssertFalse(AuthorisedCollectorsParsing.isAuthorisedCollector("Stranger", allowedLines: allowed))
    }

    func testIsAuthorisedCollectorTrimsSelection() {
        let allowed = ["Alice Smith"]
        XCTAssertTrue(AuthorisedCollectorsParsing.isAuthorisedCollector("  Alice Smith  ", allowedLines: allowed))
    }

    func testIsAuthorisedCollectorEmptySelectionFalse() {
        XCTAssertFalse(AuthorisedCollectorsParsing.isAuthorisedCollector("   ", allowedLines: ["A"]))
    }
}
