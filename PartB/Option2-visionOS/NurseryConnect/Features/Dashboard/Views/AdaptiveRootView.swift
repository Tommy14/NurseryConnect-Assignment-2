//
//  AdaptiveRootView.swift
//  NurseryConnect
//
//  Feature: Dashboard
//  Role: Keyworker
//  Created: 29 May 2026
//  Description: Size-class adaptive root that preserves iPhone navigation and adds iPad split view.
//

import CoreData
import SwiftUI

/// - Description: Chooses compact phone dashboard or regular-width iPad split shell after launch.
struct AdaptiveRootView: View {
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @EnvironmentObject private var coordinator: KeyworkerIPadCoordinator

    let managedObjectContext: NSManagedObjectContext

    init(managedObjectContext: NSManagedObjectContext) {
        self.managedObjectContext = managedObjectContext
    }

    var body: some View {
        Group {
            if horizontalSizeClass == .regular {
                KeyworkerIPadShellView(managedObjectContext: managedObjectContext)
            } else {
                KeyworkerDashboardView(managedObjectContext: managedObjectContext)
            }
        }
        .environmentObject(coordinator)
    }
}