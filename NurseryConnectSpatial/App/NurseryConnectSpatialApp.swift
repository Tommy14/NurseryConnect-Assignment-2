//
//  NurseryConnectSpatialApp.swift
//  NurseryConnect Spatial
//
//  Feature: Spatial
//  Role: Keyworker
//  Created: 30 May 2026
//  Description: visionOS entry point — home hub, keyworker dashboard, Setting Manager overview, mood chart.
//

import CoreData
import SwiftUI

@main
struct NurseryConnectSpatialApp: App {
    // Production: replace with shared CloudKit / App Group container
    private let persistence = PersistenceController(inMemory: true)

    init() {
        let context = persistence.container.viewContext
        DataSeeder.seedSpatialDemoStore(in: context)
    }

    var body: some Scene {
        spatialHubWindow
        keyworkerDashboardWindow
        settingManagerWindow
        #if arch(simulator)
        moodChartPlainWindow
        #else
        moodChartVolumetricWindow
        #endif
    }

    private var spatialHubWindow: some Scene {
        WindowGroup(id: SpatialWindowID.hub) {
            SpatialHubView(managedObjectContext: persistence.container.viewContext)
                .environment(\.managedObjectContext, persistence.container.viewContext)
                .ncSpatialWindowChrome()
        }
        .windowStyle(.plain)
        .defaultSize(width: 920, height: 640, depth: 0)
    }

    private var keyworkerDashboardWindow: some Scene {
        WindowGroup(id: SpatialWindowID.keyworkerDashboard) {
            SpatialInboxView(managedObjectContext: persistence.container.viewContext)
                .environment(\.managedObjectContext, persistence.container.viewContext)
                .ncSpatialWindowChrome()
        }
        .windowStyle(.plain)
        .defaultSize(width: 980, height: 720, depth: 0)
    }

    private var settingManagerWindow: some Scene {
        WindowGroup(id: SpatialWindowID.settingManager) {
            SpatialSettingManagerView(managedObjectContext: persistence.container.viewContext)
                .environment(\.managedObjectContext, persistence.container.viewContext)
                .ncSpatialWindowChrome()
        }
        .windowStyle(.plain)
        .defaultSize(width: 980, height: 720, depth: 0)
    }

    #if arch(simulator)
    private var moodChartPlainWindow: some Scene {
        moodChartWindowGroup
            .windowStyle(.plain)
            .defaultSize(width: 540, height: 520)
    }
    #else
    private var moodChartVolumetricWindow: some Scene {
        moodChartWindowGroup
            .windowStyle(.volumetric)
            .defaultSize(width: 0.48, height: 0.58, depth: 0.42, in: .meters)
    }
    #endif

    private var moodChartWindowGroup: some Scene {
        WindowGroup("Mood Chart", id: "mood-chart", for: MoodChartWindowID.self) { $windowValue in
            Group {
                if let windowValue {
                    MoodChartVolumeView(childID: windowValue.childID)
                } else {
                    ContentUnavailableView("No child selected", systemImage: "person.crop.circle.badge.questionmark")
                }
            }
            .environment(\.managedObjectContext, persistence.container.viewContext)
        }
    }
}
