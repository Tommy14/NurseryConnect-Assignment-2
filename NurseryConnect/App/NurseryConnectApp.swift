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
// 130426     Tommy1914   Added UK nursery-themed launch loading animation before dashboard handoff.
// 130426     Tommy1914   Configurable splash duration (shorter on simulator, longer on device).
// -----------------------------------------------------------------

import Combine
import CoreData
import SwiftUI
import UIKit

@MainActor
@main
struct NurseryConnectApp: App {
    @Environment(\.scenePhase) private var scenePhase
    private let persistence = PersistenceController.shared
    @StateObject private var networkMonitor = NetworkMonitor.shared
    private let syncQueue = SyncQueueService.shared
    @State private var isShowingLaunchAnimation = true
    @State private var syncTimer = Timer.publish(every: 90, on: .main, in: .common).autoconnect()
    private let launchDurationNanoseconds: UInt64 = {
#if targetEnvironment(simulator)
        return 1_200_000_000
#else
        return 2_000_000_000
#endif
    }()

    init() {
        let appearance = UINavigationBarAppearance()
        appearance.configureWithTransparentBackground()
        appearance.backgroundEffect = UIBlurEffect(style: .systemThinMaterial)
        appearance.backgroundColor = UIColor.systemBackground.withAlphaComponent(0.18)
        appearance.shadowColor = UIColor.white.withAlphaComponent(0.18)

        UINavigationBar.appearance().standardAppearance = appearance
        UINavigationBar.appearance().scrollEdgeAppearance = appearance
        UINavigationBar.appearance().compactAppearance = appearance
        UINavigationBar.appearance().isTranslucent = true
    }

    var body: some Scene {
        WindowGroup {
            ZStack {
                if isShowingLaunchAnimation {
                    NurseryLaunchView()
                        .transition(.opacity)
                } else {
                    KeyworkerDashboardView(managedObjectContext: persistence.container.viewContext)
                        .environment(\.managedObjectContext, persistence.container.viewContext)
                        .transition(.opacity)
                }
            }
            .task {
                networkMonitor.startIfNeeded()
                await syncQueue.processQueueIfPossible()
                guard isShowingLaunchAnimation else { return }
                try? await Task.sleep(nanoseconds: launchDurationNanoseconds)
                withAnimation(.easeOut(duration: 0.35)) {
                    isShowingLaunchAnimation = false
                }
            }
            .onChange(of: networkMonitor.isOnline) { _, isOnline in
                guard isOnline else { return }
                Task { await syncQueue.processQueueIfPossible(force: true) }
            }
            .onReceive(syncTimer) { _ in
                Task { await syncQueue.processQueueIfPossible() }
            }
            .onChange(of: scenePhase) { _, nextPhase in
                guard nextPhase == .active else { return }
                Task { await syncQueue.processQueueIfPossible(force: true) }
            }
        }
    }
}
