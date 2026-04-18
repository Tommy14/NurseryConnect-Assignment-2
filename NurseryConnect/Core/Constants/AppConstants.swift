//
//  AppConstants.swift
//  NurseryConnect
//
//  Feature: Core
//  Role: Keyworker
//  Created: 28 March 2026
//  Description: Centralises strings, thresholds, and layout tokens used across the app.
//
// -----------------------------------------------------------------
// Date       Name        What has done
// -----------------------------------------------------------------
// 280326     Tommy1914   Created the file with keyworker, nursery, and diary completeness rules.
// 140426     Tommy1914   Keyworker root list navigation title (`Children`).
// 140426     Tommy1914   Keyworker incidents inbox navigation title (`Incidents`).
// 150426     Tommy1914   Keyworker profile toolbar button accessibility ID.
// -----------------------------------------------------------------

import CoreGraphics
import Foundation

// MARK: - App Identity

/// - Description: Application-wide identity and branding strings for the keyworker MVP.
enum AppConstants {
    /// - Description: Display name shown in greetings and sample data for the logged-in keyworker (no auth UI in MVP).
    static let keyworkerDisplayName = "Thamindu V D"

    /// - Description: Official setting name for assignment copy and seed data.
    static let nurseryDisplayName = "Little Stars Nursery & Daycare"

    /// - Description: Navigation title for the keyworker children list (large title; compact when scrolled).
    static let navTitleKeyworkerChildrenList = "Children"

    /// - Description: Navigation title for the keyworker incidents inbox (large title; compact when scrolled).
    static let navTitleKeyworkerIncidentsList = "Incidents"

    /// - Description: `UserDefaults` key indicating sample children have been inserted.
    static let hasSeededSampleDataKey = "com.nurseryconnect.hasSeededSampleData"

    // MARK: Diary completeness

    /// - Description: Dashboard “complete” (green dot) requires every planned session segment for today to have at least one non-sleep log — see `DayTimelineMerger.allPlannedSessionsHaveAtLeastOneLog`.
    /// - Description: Gap threshold (seconds) beyond which a diary log is flagged for manager review when event time and submission time are far apart.
    static let diaryLateLogReviewThresholdSeconds: TimeInterval = 2 * 60 * 60

    // MARK: Incident compliance

    /// - Description: EYFS-aligned threshold (seconds) for parent notification follow-up warnings in the UI.
    // EYFS: Prompt parent communication within statutory safeguarding expectations; banner uses a 2-hour demo threshold.
    static let parentNotificationWarningThresholdSeconds: TimeInterval = 2 * 60 * 60

    // MARK: Layout

    /// - Description: Minimum touch target (points) for interactive controls.
    static let minimumTouchTarget: CGFloat = 44

    /// - Description: Standard card corner radius (points).
    static let cardCornerRadius: CGFloat = 16

    /// - Description: Standard button corner radius (points).
    static let buttonCornerRadius: CGFloat = 12

    /// - Description: Floating action button corner radius (points).
    static let fabCornerRadius: CGFloat = 24

    /// - Description: Extra bottom inset for FABs when `KeyworkerDashboardView`’s floating glass tab bar sits above the home indicator (system safe area does not always reserve enough for custom `safeAreaInset` chrome).
    static let floatingTabBarClearance: CGFloat = 100

    /// - Description: Maximum characters for incident free-text fields where a cap improves form usability.
    static let incidentDescriptionMaxLength = 2_000

    /// - Description: Accessibility identifiers for UI tests (stable across locales).
    enum AccessibilityID {
        static let myChildrenTab = "tab_my_children"
        static let incidentsTab = "tab_incidents"
        static let keyworkerProfileButton = "keyworker_profile_button"
        static let childCardPrefix = "child_card_"
        static let childCardCurrentActivity = "child_card_current_activity"
        static let childCardAllergies = "child_card_allergies"
        static let addDiaryFAB = "fab_add_diary"
        static let saveDiaryEntry = "save_diary_entry"
        static let addIncidentFAB = "fab_add_incident"
        static let submitIncident = "submit_incident"
        static let incidentRowPrefix = "incident_row_"
        static let reportUnauthorisedCollection = "report_unauthorised_collection"
        static let dashboardQuickCheckInSave = "dashboard_quick_check_in_save"
    }
}
