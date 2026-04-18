//
//  IncidentDetailView.swift
//  NurseryConnect
//
//  Feature: Incident Reporting
//  Role: Keyworker
//  Created: 9 April 2026
//  Description: Full incident record with status tracker, body map replay, and PDF export.
//
// -----------------------------------------------------------------
// Date       Name        What has done
// -----------------------------------------------------------------
// 090426     Tommy1914   Created the file with tracker UI, share sheet, and draft editing.
// 100426     Tommy1914   Vertical workflow timeline (no horizontal scroll).
// 100426     Tommy1914   Studio cards for meta + narrative sections; screen atmosphere.
// 100426     Tommy1914   Draft edit uses fullScreenCover to match list composer presentation.
// 100426     Tommy1914   Inline nav + toolbar Export PDF; bottom inset for floating tab bar.
// -----------------------------------------------------------------

import CoreData
import SwiftUI

/// - Description: Read-mostly incident screen with leadership and parent follow-up affordances.
struct IncidentDetailView: View {
    @ObservedObject var incident: Incident
    @ObservedObject var viewModel: IncidentViewModel
    @Environment(\.usesFloatingTabBarShell) private var usesFloatingTabBarShell

    @State private var annotations: [BodyMapAnnotation] = []
    @State private var side: BodyMapSide = .front
    @State private var showEdit = false

    private var status: IncidentStatus {
        IncidentStatus.fromPersistence(incident.status ?? "")
    }

    private var syncState: SyncState {
        viewModel.syncState(for: incident)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                statusTracker
                IncidentSeverityIndicator(severity: IncidentSeverity.fromPersistence(incident.severity ?? ""))
                metaSection
                textSection(title: "Description", text: incident.incidentDescription ?? "", symbol: "text.alignleft")
                textSection(title: "Immediate action", text: incident.immediateActionTaken ?? "", symbol: "cross.case.fill")
                textSection(title: "Witnesses", text: incident.witnesses ?? "", symbol: "person.2.fill")
                BodyMapView(isInteractive: false, annotations: $annotations, side: $side)
            }
            .padding()
            .padding(.bottom, usesFloatingTabBarShell ? AppConstants.floatingTabBarClearance : 0)
        }
        .scrollIndicators(.hidden)
        .scrollContentBackground(.hidden)
        .background(Color.ncBackground)
        .navigationTitle("Incident")
        .toolbarBackground(Color.ncBackground, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItemGroup(placement: .topBarTrailing) {
                if status == .draft {
                    Button("Edit") {
                        showEdit = true
                    }
                }
            }
        }
        .onAppear {
            annotations = BodyMapCodec.decode(incident.bodyMapAnnotations)
        }
        .fullScreenCover(isPresented: $showEdit) {
            NewIncidentFormView(viewModel: viewModel, existingIncident: incident)
                .environment(\.managedObjectContext, incident.managedObjectContext ?? PersistenceController.shared.container.viewContext)
        }
    }

    private var statusTracker: some View {
        IncidentWorkflowTimelineView(currentStatus: status)
    }

    private var metaSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            if let timestamp = incident.timestamp {
                Label {
                    Text("Recorded \(timestamp.formatted(date: .abbreviated, time: .shortened))")
                        .font(.headline)
                } icon: {
                    Image(systemName: "clock.fill")
                        .foregroundStyle(Color.ncPrimary)
                }
            }
            if let timing = viewModel.escalationPresentation(for: incident) {
                Label {
                    Text(timing.statusLine)
                        .font(.subheadline.weight(.semibold))
                } icon: {
                    Image(systemName: timing.isEscalationDue ? "exclamationmark.triangle.fill" : "hourglass")
                        .foregroundStyle(timing.isEscalationDue ? Color.ncDanger : Color.ncPrimary)
                }
            }
            Label {
                Text("Location: \(incident.location ?? "—")")
                    .font(.subheadline.weight(.medium))
            } icon: {
                Image(systemName: "mappin.circle.fill")
                    .foregroundStyle(Color.ncPrimary.opacity(0.9))
            }
            IncidentStatusBadge(status: status)
            HStack(spacing: 10) {
                SyncStateBadgeView(state: syncState)
                if syncState == .failed {
                    Button("Retry sync") {
                        Task { await viewModel.retrySync(for: incident) }
                    }
                    .font(.caption.weight(.semibold))
                    .buttonStyle(.borderedProminent)
                    .tint(Color.ncDanger)
                }
            }
            if syncState == .failed, let lastSyncError = incident.lastSyncError, !lastSyncError.isEmpty {
                Text(lastSyncError)
                    .font(.caption)
                    .foregroundStyle(Color.ncDanger)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .ncStudioElevatedSurface(cornerRadius: 16)
    }

    private func textSection(title: String, text: String, symbol: String) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Label(title, systemImage: symbol)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Color.primary)
            Text(text.isEmpty ? "—" : text)
                .font(.body)
                .foregroundStyle(.primary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .ncStudioElevatedSurface(cornerRadius: 16)
    }

}
