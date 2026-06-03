//
//  SpatialHubView.swift
//  NurseryConnect Spatial
//
//  Feature: Spatial
//  Created: 2 June 2026
//  Description: Nursery home screen linking keyworker and Setting Manager spatial dashboards.
//

import Combine
import CoreData
import SwiftUI

/// - Description: Home screen for keyworker and Setting Manager spatial workspaces.
struct SpatialHubView: View {
    @Environment(\.openWindow) private var openWindow

    @StateObject private var statsViewModel: SpatialSettingManagerViewModel
    @State private var currentDate = Date()

    init(managedObjectContext: NSManagedObjectContext) {
        _statsViewModel = StateObject(wrappedValue: SpatialSettingManagerViewModel(context: managedObjectContext))
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                hubHeader
                SpatialTodaySnapshotView(stats: hubStats)
                workspacesSection
            }
            .padding(28)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background {
            LinearGradient(
                colors: [Color.ncBackground, Color.ncGlowViolet.opacity(0.1), Color.ncGlowBlue.opacity(0.08)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
        .refreshable { await statsViewModel.refresh() }
        .task { await statsViewModel.refresh() }
        .onReceive(Timer.publish(every: 60, on: .main, in: .common).autoconnect()) { tick in
            currentDate = tick
        }
    }

    private var hubHeader: some View {
        HStack(alignment: .top, spacing: 16) {
            Image("NurseryConnectNavLogo")
                .resizable()
                .scaledToFit()
                .frame(width: 52, height: 52)
                .frame(width: 72, height: 72)
                .background(Color.white.opacity(0.62), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                .accessibilityLabel("NurseryConnect")

            VStack(alignment: .leading, spacing: 6) {
                Text("NurseryConnect")
                    .font(.largeTitle.weight(.bold))
                Text(greetingLine)
                    .font(.title3.weight(.medium))
                    .foregroundStyle(.secondary)
                Text(AppConstants.nurseryDisplayName)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Text(currentDate.formattedMediumDate())
                    .font(.caption.weight(.medium))
                    .foregroundStyle(Color.ncPrimary)
            }
        }
    }

    private var workspacesSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Workspaces")
                .font(.headline)
            experienceGrid
        }
    }

    private var experienceGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
            ForEach(SpatialExperienceKind.allCases) { experience in
                Button {
                    open(experience)
                } label: {
                    experienceCard(experience)
                }
                .buttonStyle(.plain)
                .buttonBorderShape(.roundedRectangle(radius: 20))
            }
        }
    }

    private func experienceCard(_ experience: SpatialExperienceKind) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Image(systemName: experience.systemImage)
                .font(.title)
                .foregroundStyle(Color.ncPrimary)
                .frame(width: 48, height: 48)
                .background(Color.ncPrimary.opacity(0.12), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
            Text(experience.title)
                .font(.headline)
                .foregroundStyle(.primary)
            Text(experience.subtitle)
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.leading)
                .lineLimit(3)
                .fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: 0)
            HStack {
                Text("Open")
                    .font(.subheadline.weight(.semibold))
                Image(systemName: "chevron.right")
                    .font(.caption.weight(.bold))
            }
            .foregroundStyle(Color.ncPrimary)
            .accessibilityLabel(experience.actionLabel)
        }
        .padding(18)
        .frame(maxWidth: .infinity, minHeight: 180, alignment: .topLeading)
        .glassBackgroundEffect(in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        .contentShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        #if os(visionOS)
        .hoverEffect(.highlight)
        #endif
    }

    private var hubStats: [SpatialSnapshotStat] {
        [
            SpatialSnapshotStat(
                id: "enrolled",
                title: "Enrolled children",
                value: "\(statsViewModel.totalChildren)",
                systemImage: "person.3.fill",
                tint: Color.ncPrimary
            ),
            SpatialSnapshotStat(
                id: "onSite",
                title: "On site now",
                value: "\(statsViewModel.onSiteCount)",
                systemImage: "figure.and.child.holdinghands",
                tint: Color.ncSecondary
            ),
            SpatialSnapshotStat(
                id: "incidents",
                title: "Open incidents",
                value: "\(statsViewModel.openIncidentCount)",
                systemImage: "exclamationmark.shield.fill",
                tint: Color.ncDanger
            ),
            SpatialSnapshotStat(
                id: "messages",
                title: "Unread messages",
                value: "\(statsViewModel.unreadMessageCount)",
                systemImage: "envelope.badge",
                tint: Color.ncAccentWarm
            )
        ]
    }

    private var greetingLine: String {
        let firstName = AppConstants.keyworkerDisplayName
            .split(separator: " ")
            .first
            .map(String.init) ?? AppConstants.keyworkerDisplayName
        return "\(greetingText), \(firstName)"
    }

    private var greetingText: String {
        let hour = Calendar.current.component(.hour, from: currentDate)
        switch hour {
        case 5..<12: return "Good morning"
        case 12..<17: return "Good afternoon"
        case 17..<22: return "Good evening"
        default: return "Good night"
        }
    }

    private func open(_ experience: SpatialExperienceKind) {
        switch experience {
        case .keyworkerDashboard:
            openWindow(id: SpatialWindowID.keyworkerDashboard)
        case .settingManagerOverview:
            openWindow(id: SpatialWindowID.settingManager)
        }
    }
}

/// - Description: Window identifiers for multi-window spatial scenes.
enum SpatialWindowID {
    static let hub = "spatial-hub"
    static let keyworkerDashboard = "keyworker-dashboard"
    static let settingManager = "setting-manager"
}
