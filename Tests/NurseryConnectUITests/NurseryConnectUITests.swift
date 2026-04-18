//
//  NurseryConnectUITests.swift
//  NurseryConnectUITests
//
//  Feature: UI Tests
//  Role: Keyworker
//  Created: 10 April 2026
//  Description: Smoke UI tests for dashboard navigation and critical accessibility IDs.
//
// -----------------------------------------------------------------
// Date       Name        What has done
// -----------------------------------------------------------------
// 100426     Tommy1914   Created the file with launch and tab visibility checks.
// 150426     Tommy1914   Keyworker profile sheet smoke test.
// -----------------------------------------------------------------

import XCTest

final class NurseryConnectUITests: XCTestCase {
    /// - Description: Confirms the app launches into the keyworker dashboard shell.
    func testLaunchShowsDashboardTabs() {
        let app = XCUIApplication()
        app.launch()

        let childrenTab = app.buttons["Children"]
        XCTAssertTrue(childrenTab.waitForExistence(timeout: 5))

        let incidentsTab = app.buttons["Incidents"]
        XCTAssertTrue(incidentsTab.exists)
    }

    /// - Description: Opens the keyworker profile from the Children toolbar and confirms the sheet appears.
    func testKeyworkerProfileSheetFromChildrenToolbar() {
        let app = XCUIApplication()
        app.launch()

        let profileButton = app.buttons["My profile"]
        XCTAssertTrue(profileButton.waitForExistence(timeout: 5))
        profileButton.tap()

        let myProfileNav = app.navigationBars["My profile"]
        XCTAssertTrue(myProfileNav.waitForExistence(timeout: 3))
    }
}
