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
    private enum ID {
        static let myChildrenTab = "tab_my_children"
        static let incidentsTab = "tab_incidents"
        static let keyworkerProfileButton = "keyworker_profile_button"
        static let legalComplianceEntry = "legal_compliance_entry"
        static let legalComplianceScreen = "legal_compliance_screen"
        static let complianceDisclaimerText = "compliance_disclaimer_text"
        static let childCardPrefix = "child_card_"
        static let addDiaryFAB = "fab_add_diary"
        static let saveDiaryEntry = "save_diary_entry"
        static let addIncidentFAB = "fab_add_incident"
        static let submitIncident = "submit_incident"
        static let dashboardQuickCheckInSave = "dashboard_quick_check_in_save"
    }

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    /// - Description: Common launch helper for every test case.
    private func launchApp() -> XCUIApplication {
        let app = XCUIApplication()
        app.launch()
        return app
    }

    /// - Description: Returns child cards currently visible on the dashboard.
    private func childCards(in app: XCUIApplication) -> XCUIElementQuery {
        app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH %@", ID.childCardPrefix))
    }

    /// - Description: Tries to navigate back to children list when a card opens diary details.
    private func navigateBackToChildrenIfNeeded(in app: XCUIApplication) {
        let backButton = app.navigationBars.buttons.element(boundBy: 0)
        if backButton.exists {
            backButton.tap()
        }
    }

    /// - Description: Confirms the app launches into the dashboard with both root tabs visible.
    func testLaunchShowsDashboardTabs() {
        let app = launchApp()
        XCTAssertTrue(app.buttons[ID.myChildrenTab].waitForExistence(timeout: 8))
        XCTAssertTrue(app.buttons[ID.incidentsTab].waitForExistence(timeout: 8))
    }

    /// - Description: Opens the profile sheet and validates the legal compliance screen entry path.
    func testProfileSheetAndLegalComplianceFlow() {
        let app = launchApp()
        let profileButton = app.buttons[ID.keyworkerProfileButton]
        XCTAssertTrue(profileButton.waitForExistence(timeout: 8))
        profileButton.tap()

        let myProfileNav = app.navigationBars["My profile"]
        XCTAssertTrue(myProfileNav.waitForExistence(timeout: 5))

        let legalEntry = app.otherElements[ID.legalComplianceEntry]
        XCTAssertTrue(legalEntry.waitForExistence(timeout: 5))
        legalEntry.tap()

        XCTAssertTrue(app.otherElements[ID.legalComplianceScreen].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts[ID.complianceDisclaimerText].waitForExistence(timeout: 5))
    }

    /// - Description: Switches to incidents and checks that the composer can be opened.
    func testIncidentsTabShowsComposerEntry() {
        let app = launchApp()
        let incidentsTab = app.buttons[ID.incidentsTab]
        XCTAssertTrue(incidentsTab.waitForExistence(timeout: 8))
        incidentsTab.tap()

        let addIncidentFAB = app.buttons[ID.addIncidentFAB]
        XCTAssertTrue(addIncidentFAB.waitForExistence(timeout: 8))
        addIncidentFAB.tap()

        XCTAssertTrue(app.buttons[ID.submitIncident].waitForExistence(timeout: 5))
    }

    /// - Description: Taps a child card and validates that one of the expected child flows appears.
    func testChildCardOpensDiaryOrQuickCheckIn() {
        let app = launchApp()
        XCTAssertTrue(app.buttons[ID.myChildrenTab].waitForExistence(timeout: 8))

        let firstChildCard = app.buttons.matching(
            NSPredicate(format: "identifier BEGINSWITH %@", ID.childCardPrefix)
        ).firstMatch
        XCTAssertTrue(firstChildCard.waitForExistence(timeout: 10))
        firstChildCard.tap()

        let diaryAddFAB = app.buttons[ID.addDiaryFAB]
        let quickCheckInSave = app.buttons[ID.dashboardQuickCheckInSave]
        let surfacedExpectedFlow = diaryAddFAB.waitForExistence(timeout: 4) || quickCheckInSave.waitForExistence(timeout: 4)
        XCTAssertTrue(surfacedExpectedFlow, "Expected diary screen or quick check-in sheet after tapping a child card.")
    }

    /// - Description: Ensures at least one child card is visible on launch.
    func testChildrenListShowsAtLeastOneChildCard() {
        let app = launchApp()
        let firstChildCard = app.buttons.matching(
            NSPredicate(format: "identifier BEGINSWITH %@", ID.childCardPrefix)
        ).firstMatch
        XCTAssertTrue(firstChildCard.waitForExistence(timeout: 10))
    }

    /// - Description: Finds a child that requires check-in, saves attendance, and verifies transition into the diary screen.
    func testCheckInChildFromDashboardQuickSheet() {
        let app = launchApp()
        XCTAssertTrue(app.buttons[ID.myChildrenTab].waitForExistence(timeout: 8))

        let cards = childCards(in: app)
        XCTAssertGreaterThan(cards.count, 0, "Expected at least one child card to exist.")

        var didCompleteCheckIn = false
        let maxAttempts = min(cards.count, 8)
        for index in 0..<maxAttempts {
            let card = cards.element(boundBy: index)
            guard card.waitForExistence(timeout: 2) else { continue }
            card.tap()

            let saveButton = app.buttons[ID.dashboardQuickCheckInSave]
            if saveButton.waitForExistence(timeout: 2) == false {
                // Card opened diary directly (already checked-in/departed); try another child.
                navigateBackToChildrenIfNeeded(in: app)
                continue
            }

            // If manual drop-off entry is required, provide a value before saving.
            let fullNameField = app.textFields["Full name"]
            if fullNameField.waitForExistence(timeout: 1) {
                fullNameField.tap()
                fullNameField.typeText("Test Parent")
            }

            saveButton.tap()
            XCTAssertTrue(app.buttons[ID.addDiaryFAB].waitForExistence(timeout: 8))
            didCompleteCheckIn = true
            break
        }

        XCTAssertTrue(didCompleteCheckIn, "No child requiring quick check-in was found during this run.")
    }
}
