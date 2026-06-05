//
//  KeyworkerCommands.swift
//  NurseryConnect
//
//  Feature: App
//  Role: Keyworker
//  Created: 29 May 2026
//  Description: Keyboard shortcuts for diary, incident, messages, and sheet dismissal.
//

import SwiftUI

/// - Description: Registers keyworker keyboard commands on the app window.
struct KeyworkerCommands: Commands {
    let coordinator: KeyworkerIPadCoordinator

    var body: some Commands {
        CommandMenu("Keyworker") {
            Button("New Diary Entry") {
                coordinator.requestNewDiaryEntry = true
            }
            .keyboardShortcut("n", modifiers: .command)

            Button("New Incident") {
                coordinator.openNewIncident()
            }
            .keyboardShortcut("i", modifiers: .command)

            Button("Messages") {
                coordinator.section = .messages
            }
            .keyboardShortcut("m", modifiers: .command)

            Divider()

            Button("Dismiss Sheet") {
                coordinator.dismissAllPresented = true
            }
            .keyboardShortcut(.escape, modifiers: [])
        }
    }
}
