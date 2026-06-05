//
//  NurseryConnectSpatialApp.swift
//  NurseryConnect Spatial
//
//  Feature: Spatial
//  Role: Keyworker
//  Created: 30 May 2026
//  Description: visionOS entry point — home hub, keyworker dashboard, Setting Manager overview, mood chart,
//               and six new feature windows (attendance, transport, meal plan, messaging, daily diary, incidents).
//

import CoreData
import SwiftUI

@main
struct NurseryConnectSpatialApp: App {
    private let persistence = PersistenceController(inMemory: true)
    @StateObject private var dataStore = SpatialDataStore()

    init() {
        let context = persistence.container.viewContext
        DataSeeder.seedSpatialDemoStore(in: context)
    }

    var body: some Scene {
        spatialHubWindow
        keyworkerDashboardWindow
        settingManagerWindow
        attendanceWindow
        transportWindow
        mealPlanWindow
        messagingWindow
        #if arch(simulator)
        moodChartPlainWindow
        #else
        moodChartVolumetricWindow
        #endif
    }

    // MARK: - Existing windows

    private var spatialHubWindow: some Scene {
        WindowGroup(id: SpatialWindowID.hub) {
            SpatialHubView(managedObjectContext: persistence.container.viewContext)
                .environment(\.managedObjectContext, persistence.container.viewContext)
                .environmentObject(dataStore)
                .ncSpatialWindowChrome()
        }
        .windowStyle(.plain)
        .defaultSize(width: 1000, height: 700, depth: 0)
    }

    private var keyworkerDashboardWindow: some Scene {
        WindowGroup(id: SpatialWindowID.keyworkerDashboard) {
            SpatialInboxView(managedObjectContext: persistence.container.viewContext)
                .environment(\.managedObjectContext, persistence.container.viewContext)
                .environmentObject(dataStore)
                .ncSpatialWindowChrome()
        }
        .windowStyle(.plain)
        .defaultSize(width: 980, height: 720, depth: 0)
    }

    private var settingManagerWindow: some Scene {
        WindowGroup(id: SpatialWindowID.settingManager) {
            SpatialSettingManagerView(managedObjectContext: persistence.container.viewContext)
                .environment(\.managedObjectContext, persistence.container.viewContext)
                .environmentObject(dataStore)
                .ncSpatialWindowChrome()
        }
        .windowStyle(.plain)
        .defaultSize(width: 980, height: 720, depth: 0)
    }

    // MARK: - New feature windows

    private var attendanceWindow: some Scene {
        WindowGroup(id: SpatialWindowID.attendance) {
            SpatialAttendanceView()
                .environmentObject(dataStore)
                .ncSpatialWindowChrome()
        }
        .windowStyle(.plain)
        .defaultSize(width: 1040, height: 760, depth: 0)
    }

    private var transportWindow: some Scene {
        WindowGroup(id: SpatialWindowID.transport) {
            SpatialTransportTrackerView()
                .environmentObject(dataStore)
                .ncSpatialWindowChrome()
        }
        .windowStyle(.plain)
        .defaultSize(width: 1060, height: 720, depth: 0)
    }

    private var mealPlanWindow: some Scene {
        WindowGroup(id: SpatialWindowID.mealPlan) {
            SpatialMealPlanView()
                .environmentObject(dataStore)
                .ncSpatialWindowChrome()
        }
        .windowStyle(.plain)
        .defaultSize(width: 1100, height: 720, depth: 0)
    }

    private var messagingWindow: some Scene {
        WindowGroup(id: SpatialWindowID.messaging) {
            SpatialSecureMessagingView()
                .environmentObject(dataStore)
                .ncSpatialWindowChrome()
        }
        .windowStyle(.plain)
        .defaultSize(width: 980, height: 700, depth: 0)
    }

    // MARK: - Mood chart (volumetric on device, plain on simulator)

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

// MARK: - Window identifier constants

extension SpatialWindowID {
    static let attendance = "spatial-attendance"
    static let transport  = "spatial-transport"
    static let mealPlan   = "spatial-meal-plan"
    static let messaging  = "spatial-messaging"
}
