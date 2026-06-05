//
//  IncidentViewModelTests.swift
//  NurseryConnectTests
//
//  Feature: Incident Reporting
//  Role: Keyworker
//  Created: 10 April 2026
//  Description: Unit tests for incident helpers, RIDDOR hints, and body map encoding.
//
// -----------------------------------------------------------------
// Date       Name        What has done
// -----------------------------------------------------------------
// 100426     Tommy1914   Created the file with codec round-trip and severity mapping tests.
// -----------------------------------------------------------------

import CoreData
import XCTest
@testable import NurseryConnect

@MainActor
final class IncidentViewModelTests: XCTestCase {
    /// - Description: Verifies category-driven RIDDOR suggestions align with policy metadata.
    func testRiddorSuggestionForSeriousCategories() {
        let stack = PersistenceController(inMemory: true)
        let vm = IncidentViewModel(context: stack.container.viewContext)
        XCTAssertTrue(vm.suggestsRiddor(for: .seriousIncident))
        XCTAssertFalse(vm.suggestsRiddor(for: .safeguardingConcern))
        XCTAssertFalse(vm.suggestsRiddor(for: .nearMiss))
    }

    /// - Description: Ensures body map annotations survive a JSON encode/decode cycle.
    func testBodyMapCodecRoundTrip() {
        let markers = [
            BodyMapAnnotation(side: .front, normalizedX: 0.4, normalizedY: 0.5),
            BodyMapAnnotation(side: .back, normalizedX: 0.6, normalizedY: 0.3)
        ]
        let data = BodyMapCodec.encode(markers)
        XCTAssertNotNil(data)
        let decoded = BodyMapCodec.decode(data)
        XCTAssertEqual(decoded.count, 2)
        XCTAssertEqual(decoded.first?.side, .front)
    }

    /// - Description: Confirms severity defaults track the selected incident category.
    func testCategoryMapsDefaultSeverity() {
        XCTAssertEqual(IncidentCategory.accidentMinor.defaultSeverity, .minor)
        XCTAssertEqual(IncidentCategory.allergicReaction.defaultSeverity, .allergicReaction)
        XCTAssertEqual(IncidentCategory.seriousIncident.defaultSeverity, .serious)
    }
}
