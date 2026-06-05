//
//  SpatialHubView.swift
//  NurseryConnect Spatial
//
//  Feature: Spatial
//  Created: 2 June 2026
//  Description: Nursery home screen linking all spatial workspaces with live stat tiles and 3D orbs.
//

import Combine
import CoreData
import SwiftUI

/// - Description: Home screen for all spatial workspaces.
struct SpatialHubView: View {
    @Environment(\.openWindow) private var openWindow
    @EnvironmentObject private var dataStore: SpatialDataStore

    @StateObject private var statsViewModel: SpatialSettingManagerViewModel
    @State private var currentDate = Date()
    @State private var showsIncidentSheet = false

    init(managedObjectContext: NSManagedObjectContext) {
        _statsViewModel = StateObject(wrappedValue: SpatialSettingManagerViewModel(context: managedObjectContext))
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 28) {
                hubHeader
                statsRail
                workspacesSection
            }
            .padding(28)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background {
            LinearGradient(
                colors: [Color.ncBackground, Color.ncGlowViolet.opacity(0.10), Color.ncGlowBlue.opacity(0.08)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
        .refreshable { await statsViewModel.refresh() }
        .task { await statsViewModel.refresh() }
        .onReceive(Timer.publish(every: 60, on: .main, in: .common).autoconnect()) { tick in
            currentDate = tick
        }
        .sheet(isPresented: $showsIncidentSheet) {
            SpatialIncidentsSheet(nurseryWide: true)
        }
    }

    // MARK: - Header

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
                    .font(.ncLargeTitle)
                Text(greetingLine)
                    .font(.ncTitle3)
                    .foregroundStyle(.secondary)
                Text(AppConstants.nurseryDisplayName)
                    .font(.ncBody)
                    .foregroundStyle(.secondary)
                Text(currentDate.formattedMediumDate())
                    .font(.ncCaption.weight(.medium))
                    .foregroundStyle(Color.ncPrimary)
            }
        }
    }

    // MARK: - Stats rail

    private var statsRail: some View {
        HStack(spacing: 12) {
            ForEach(hubStats) { stat in
                statCard(stat)
            }
        }
    }

    private func statCard(_ stat: SpatialSnapshotStat) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            ZStack {
                Circle()
                    .fill(stat.tint.opacity(0.18))
                    .frame(width: 42, height: 42)
                Image(systemName: stat.systemImage)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(stat.tint)
            }
            Text(stat.value)
                .font(.system(.largeTitle, design: .rounded, weight: .bold).monospacedDigit())
            Text(stat.title)
                .font(.ncCaption)
                .foregroundStyle(.secondary)
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Color.white.opacity(0.15), lineWidth: 1)
        )
        #if os(visionOS)
        .hoverEffect(.highlight)
        #endif
        .accessibilityLabel(stat.title)
        .accessibilityValue(stat.value)
    }

    private var hubStats: [SpatialSnapshotStat] {
        [
            SpatialSnapshotStat(id: "enrolled", title: "Enrolled children",
                                value: "\(statsViewModel.totalChildren)",
                                systemImage: "person.3.fill", tint: Color.ncPrimary),
            SpatialSnapshotStat(id: "onSite", title: "On site now",
                                value: "\(statsViewModel.onSiteCount)",
                                systemImage: "figure.and.child.holdinghands", tint: Color.ncSecondary),
            SpatialSnapshotStat(id: "incidents", title: "Open incidents",
                                value: "\(statsViewModel.openIncidentCount)",
                                systemImage: "exclamationmark.shield.fill", tint: Color.ncDanger),
            SpatialSnapshotStat(id: "messages", title: "Unread messages",
                                value: "\(statsViewModel.unreadMessageCount)",
                                systemImage: "envelope.badge", tint: Color.ncAccentWarm),
        ]
    }

    // MARK: - Workspaces grid

    private var workspacesSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Workspaces")
                .font(.ncHeadline)
            LazyVGrid(
                columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())],
                spacing: 16
            ) {
                ForEach(SpatialExperienceKind.allCases) { experience in
                    Button {
                        openWindow(id: experience.windowID)
                    } label: {
                        experienceCard(experience)
                    }
                    .buttonStyle(.plain)
                    .buttonBorderShape(.roundedRectangle(radius: 20))
                }
            }
        }
    }

    private func experienceCard(_ experience: SpatialExperienceKind) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(Color.ncPrimary.opacity(0.14))
                    .frame(width: 48, height: 48)
                Image(systemName: experience.systemImage)
                    .font(.title2)
                    .foregroundStyle(Color.ncPrimary)
            }
            Text(experience.title)
                .font(.ncHeadline)
                .foregroundStyle(.primary)
            Text(experience.subtitle)
                .font(.ncCaption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.leading)
                .lineLimit(3)
                .fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: 0)
            HStack {
                Text("Open")
                    .font(.system(.subheadline, design: .rounded, weight: .semibold))
                Image(systemName: "chevron.right")
                    .font(.caption.weight(.bold))
            }
            .foregroundStyle(Color.ncPrimary)
            .accessibilityLabel(experience.actionLabel)
        }
        .padding(18)
        .frame(maxWidth: .infinity, minHeight: 180, alignment: .topLeading)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(Color.white.opacity(0.15), lineWidth: 1)
        )
        .contentShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        #if os(visionOS)
        .hoverEffect(.highlight)
        #endif
    }

    // MARK: - Helpers

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
        case 5..<12:  return "Good morning"
        case 12..<17: return "Good afternoon"
        case 17..<22: return "Good evening"
        default:      return "Good night"
        }
    }
}

/// - Description: Window identifiers for multi-window spatial scenes.
enum SpatialWindowID {
    static let hub               = "spatial-hub"
    static let keyworkerDashboard = "keyworker-dashboard"
    static let settingManager    = "setting-manager"
}
