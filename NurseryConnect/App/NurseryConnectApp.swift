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
// 100426     Tommy1914   Seeding moved into dashboard refresh to avoid racing tasks.
// 100426     Tommy1914   Added UK nursery-themed launch loading animation before dashboard handoff.
// 100426     Tommy1914   Configurable splash duration (shorter on simulator, longer on device).
// 180426     Tommy1914   Split nav bar: clear scroll-edge (large title) vs translucent standard (scrolled).
// 180426     Tommy1914   Lighter standard bar tint so collapsed chrome reads more transparent.
// 180426     Tommy1914   Scroll-edge large title: bold rounded “Children” matches app typography.
// 180426     Tommy1914   Removed large-title font attrs (children list uses inline title only).
// 180426     Tommy1914   Large title + transparent collapsed bar; compact title centered when scrolled.
// 180426     Tommy1914   iOS 26: default bar materials for Liquid Glass; legacy path keeps transparent strip.
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
        Self.configureNavigationBarAppearances()
    }

    /// - Description: iOS 26 uses system default bar materials so Liquid Glass can show; older OS keeps the prior flat transparent strip.
    private static func configureNavigationBarAppearances() {
        if #available(iOS 26.0, *) {
            applyLiquidGlassFriendlyNavigationChrome()
        } else {
            applyLegacyTransparentNavigationChrome()
        }
    }

    @available(iOS 26.0, *)
    private static func applyLiquidGlassFriendlyNavigationChrome() {
        // Large-title / scroll-edge: stay transparent so list content shows through (default material here reads as a solid white sheet in SwiftUI).
        let scrollEdgeAppearance = UINavigationBarAppearance()
        scrollEdgeAppearance.configureWithTransparentBackground()
        scrollEdgeAppearance.backgroundColor = .clear
        scrollEdgeAppearance.backgroundEffect = nil
        scrollEdgeAppearance.shadowColor = .clear
        let largeTitleDescriptor = UIFontDescriptor.preferredFontDescriptor(withTextStyle: .largeTitle)
        if let roundedLarge = largeTitleDescriptor.withDesign(.rounded)?.withSymbolicTraits(.traitBold) {
            let largeParagraph = NSMutableParagraphStyle()
            largeParagraph.alignment = .natural
            scrollEdgeAppearance.largeTitleTextAttributes = [
                .foregroundColor: UIColor.label,
                .font: UIFont(descriptor: roundedLarge, size: 34),
                .paragraphStyle: largeParagraph
            ]
        }

        // Collapsed inline title: system default bar material (Liquid Glass when running on iOS 26).
        let standardAppearance = UINavigationBarAppearance()
        standardAppearance.configureWithDefaultBackground()
        standardAppearance.shadowColor = .clear
        let titleParagraph = NSMutableParagraphStyle()
        titleParagraph.alignment = .center
        standardAppearance.titleTextAttributes = [
            .foregroundColor: UIColor.label,
            .font: UIFont.systemFont(ofSize: 17, weight: .semibold),
            .paragraphStyle: titleParagraph
        ]

        let nav = UINavigationBar.appearance()
        nav.scrollEdgeAppearance = scrollEdgeAppearance
        nav.compactScrollEdgeAppearance = scrollEdgeAppearance
        nav.standardAppearance = standardAppearance
        nav.compactAppearance = standardAppearance
        nav.isTranslucent = true
    }

    private static func applyLegacyTransparentNavigationChrome() {
        let scrollEdgeAppearance = UINavigationBarAppearance()
        scrollEdgeAppearance.configureWithTransparentBackground()
        scrollEdgeAppearance.backgroundColor = .clear
        scrollEdgeAppearance.backgroundEffect = nil
        scrollEdgeAppearance.shadowColor = .clear
        let largeTitleDescriptor = UIFontDescriptor.preferredFontDescriptor(withTextStyle: .largeTitle)
        if let roundedLarge = largeTitleDescriptor.withDesign(.rounded)?.withSymbolicTraits(.traitBold) {
            let largeParagraph = NSMutableParagraphStyle()
            largeParagraph.alignment = .natural
            scrollEdgeAppearance.largeTitleTextAttributes = [
                .foregroundColor: UIColor.label,
                .font: UIFont(descriptor: roundedLarge, size: 34),
                .paragraphStyle: largeParagraph
            ]
        }

        let standardAppearance = UINavigationBarAppearance()
        standardAppearance.configureWithTransparentBackground()
        standardAppearance.backgroundColor = .clear
        standardAppearance.backgroundEffect = nil
        standardAppearance.shadowColor = .clear
        let titleParagraph = NSMutableParagraphStyle()
        titleParagraph.alignment = .center
        standardAppearance.titleTextAttributes = [
            .foregroundColor: UIColor.label,
            .font: UIFont.systemFont(ofSize: 17, weight: .semibold),
            .paragraphStyle: titleParagraph
        ]

        let nav = UINavigationBar.appearance()
        nav.scrollEdgeAppearance = scrollEdgeAppearance
        nav.compactScrollEdgeAppearance = scrollEdgeAppearance
        nav.standardAppearance = standardAppearance
        nav.compactAppearance = standardAppearance
        nav.isTranslucent = true
    }

    var body: some Scene {
        WindowGroup {
            ZStack {
                Color.ncBackground.ignoresSafeArea()
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
                Task { await syncQueue.processQueueIfPossible() }
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
