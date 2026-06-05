//
//  KeyworkerIPadCoordinator.swift
//  NurseryConnect
//
//  Feature: Dashboard
//  Role: Keyworker
//  Created: 29 May 2026
//  Description: Shared navigation and keyboard-command state for the adaptive iPad shell.
//

import Combine
import Foundation

/// - Description: Primary section shown in the iPad split-view content column.
enum KeyworkerIPadSection: String, CaseIterable, Hashable {
    case children
    case incidents
    case messages
}

/// - Description: Routes keyboard shortcuts and cross-column actions in the adaptive layout.
@MainActor
final class KeyworkerIPadCoordinator: ObservableObject {
    @Published var section: KeyworkerIPadSection = .children
    @Published var selectedMessageThreadID: UUID?
    @Published var journalContentSegment: ChildJournalSegment = .journal
    @Published var journalEntryTypeFilter: DiaryEntryType?
    @Published var requestNewDiaryEntry = false
    @Published var requestNewIncident = false
    @Published var dismissAllPresented = false
    @Published private(set) var incidentsNavigationResetToken = 0

    /// - Description: Opens the incident composer and switches to the incidents section.
    func openNewIncident() {
        section = .incidents
        requestNewIncident = true
    }

    /// - Description: Resets presentation flags after handling keyboard dismiss.
    func acknowledgeDismissAllPresented() {
        dismissAllPresented = false
    }

    /// - Description: Resets diary shortcut flag after the journal column handles it.
    func acknowledgeNewDiaryEntryRequest() {
        requestNewDiaryEntry = false
    }

    /// - Description: Resets incident shortcut flag after the incidents column handles it.
    func acknowledgeNewIncidentRequest() {
        requestNewIncident = false
    }

    /// - Description: Bumps when the incidents inbox should pop back to its root list (dock reselect or section change).
    func requestIncidentsNavigationReset() {
        incidentsNavigationResetToken &+= 1
    }
}
