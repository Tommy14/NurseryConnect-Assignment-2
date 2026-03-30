//
//  NurseryConnectApp.swift
//  NurseryConnect
//
//  Feature: App
//  Role: Keyworker
//  Created: 10 April 2026
//  Description: Application entry point injecting Core Data and the keyworker dashboard root.
//
// -----------------------------------------------------------------
// Date       Name        What has done
// -----------------------------------------------------------------
// 100426     Tommy1914   Created the file with persistence, seeding, and environment wiring.
// 120426     Tommy1914   Seeding moved into dashboard refresh to avoid racing tasks.
// -----------------------------------------------------------------

import CoreData
import SwiftUI

@main
struct NurseryConnectApp: App {
    private let persistence = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            KeyworkerDashboardView(managedObjectContext: persistence.container.viewContext)
                .environment(\.managedObjectContext, persistence.container.viewContext)
        }
    }
}
