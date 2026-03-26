//
//  NurseryConnectUITests.swift
//  NurseryConnectUITests
//
//  Feature: UI Tests
//  Role: Keyworker
//  Created: 11 April 2026
//  Description: Smoke UI tests for dashboard navigation and critical accessibility IDs.
//
// -----------------------------------------------------------------
// Date       Name        What has done
// -----------------------------------------------------------------
// 110426     Tommy1914   Created the file with launch and tab visibility checks.
// -----------------------------------------------------------------

import XCTest

final class NurseryConnectUITests: XCTestCase {
    /// - Description: Confirms the app launches into the keyworker dashboard shell.
    func testLaunchShowsDashboardTabs() {
        let app = XCUIApplication()
        app.launch()

        let childrenTab = app.tabBars.buttons["My Children"]
        XCTAssertTrue(childrenTab.waitForExistence(timeout: 5))

        let incidentsTab = app.tabBars.buttons["Incidents"]
        XCTAssertTrue(incidentsTab.exists)
    }
}
