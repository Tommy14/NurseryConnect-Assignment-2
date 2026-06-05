//
//  SpatialSettingManagerView.swift
//  NurseryConnect Spatial
//
//  Feature: Spatial
//  Role: Setting Manager
//  Created: 2 June 2026
//  Description: Nursery-wide spatial dashboard for Setting Managers.
//

import Combine
import CoreData
import SwiftUI

/// - Description: Setting Manager spatial overview for nursery-wide operations.
struct SpatialSettingManagerView: View {
    @Environment(\.managedObjectContext) private var context
    @Environment(\.dismissWindow) private var dismissWindow

    @StateObject private var viewModel: SpatialSettingManagerViewModel
    @State private var showsIncidents = false
    @State private var currentDate = Date()

    init(managedObjectContext: NSManagedObjectContext) {
        _viewModel = StateObject(wrappedValue: SpatialSettingManagerViewModel(context: managedObjectContext))
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                header
                SpatialTodaySnapshotView(stats: managerStats)
                HStack(alignment: .top, spacing: 20) {
                    engagementPanel
                        .frame(maxWidth: .infinity)
                    keyworkerPanel
                        .frame(maxWidth: .infinity)
                }
                SpatialRecentIncidentsPanel(nurseryWide: true) {
                    showsIncidents = true
                }
                if viewModel.openIncidentCount > 0 {
                    IncidentBeaconView(openCount: viewModel.openIncidentCount)
                }
                dietaryPanel
                managerActions
            }
            .padding(28)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background {
            LinearGradient(
                colors: [Color.ncBackground, Color.ncGlowViolet.opacity(0.1)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
        .refreshable { await viewModel.refresh() }
        .task { await viewModel.refresh() }
        .onReceive(Timer.publish(every: 60, on: .main, in: .common).autoconnect()) { tick in
            currentDate = tick
        }
        .sheet(isPresented: $showsIncidents) {
            SpatialIncidentsSheet(nurseryWide: true)
                .environment(\.managedObjectContext, context)
        }
    }

    private var header: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 6) {
                Text("Setting Manager overview")
                    .font(.largeTitle.weight(.bold))
                Text("\(AppConstants.settingManagerDisplayName) · \(AppConstants.nurseryDisplayName)")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Text(currentDate.formattedMediumDate())
                    .font(.caption.weight(.medium))
                    .foregroundStyle(Color.ncPrimary)
            }
            Spacer()
            Button("Done") { dismissWindow(id: SpatialWindowID.settingManager) }
                .buttonStyle(.bordered)
        }
    }

    private var managerStats: [SpatialSnapshotStat] {
        [
            SpatialSnapshotStat(
                id: "enrolled",
                title: "Enrolled children",
                value: "\(viewModel.totalChildren)",
                systemImage: "person.3.fill",
                tint: Color.ncPrimary
            ),
            SpatialSnapshotStat(
                id: "onSite",
                title: "On site now",
                value: "\(viewModel.onSiteCount)",
                systemImage: "figure.and.child.holdinghands",
                tint: Color.ncSecondary
            ),
            SpatialSnapshotStat(
                id: "incidents",
                title: "Open incidents",
                value: "\(viewModel.openIncidentCount)",
                systemImage: "exclamationmark.shield.fill",
                tint: Color.ncDanger
            ),
            SpatialSnapshotStat(
                id: "messages",
                title: "Unread messages",
                value: "\(viewModel.unreadMessageCount)",
                systemImage: "envelope.badge",
                tint: Color.ncAccentWarm
            )
        ]
    }

    private var engagementPanel: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Parent engagement (7 days)")
                .font(.headline)
            MessageActivityChart()
            Text("Nursery-wide parent message volume — use dips to spot engagement risk.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(20)
        .frame(minHeight: 280, alignment: .top)
        .glassBackgroundEffect(in: RoundedRectangle(cornerRadius: 20, style: .continuous))
    }

    private var keyworkerPanel: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Keyworker cohorts")
                .font(.headline)
            if viewModel.keyworkerRows.isEmpty {
                Text("No keyworker data")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            } else {
                ForEach(viewModel.keyworkerRows) { row in
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(row.keyworkerName)
                                .font(.subheadline.weight(.semibold))
                            Text("\(row.assignedCount) assigned")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        Text("\(row.onSiteCount) on site")
                            .font(.caption.weight(.bold))
                            .foregroundStyle(Color.ncSecondary)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 4)
                            .background(Color.ncSecondary.opacity(0.14), in: Capsule())
                    }
                    .padding(.vertical, 4)
                }
            }
        }
        .padding(20)
        .frame(minHeight: 280, alignment: .top)
        .glassBackgroundEffect(in: RoundedRectangle(cornerRadius: 20, style: .continuous))
    }

    private var dietaryPanel: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Dietary & allergy register")
                .font(.headline)
            if viewModel.dietaryAlerts.isEmpty {
                Text("No dietary requirements on file.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            } else {
                ForEach(viewModel.dietaryAlerts.prefix(6)) { alert in
                    HStack(alignment: .top, spacing: 8) {
                        Image(systemName: "allergens")
                            .foregroundStyle(Color.ncAccentWarm)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(alert.childName)
                                .font(.subheadline.weight(.semibold))
                            Text(alert.detail)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
        }
        .padding(20)
        .glassBackgroundEffect(in: RoundedRectangle(cornerRadius: 20, style: .continuous))
    }

    private var managerActions: some View {
        HStack(spacing: 12) {
            Button {
                showsIncidents = true
            } label: {
                Label("Review all incidents", systemImage: "exclamationmark.shield.fill")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .tint(Color.ncPrimary)
        }
    }
}
