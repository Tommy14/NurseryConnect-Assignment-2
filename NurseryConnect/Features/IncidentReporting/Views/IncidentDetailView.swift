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
// 120426     Tommy1914   Vertical workflow timeline (no horizontal scroll).
// 120426     Tommy1914   Studio cards for meta + narrative sections; screen atmosphere.
// 130426     Tommy1914   Draft edit uses fullScreenCover to match list composer presentation.
// 130426     Tommy1914   Inline nav + toolbar Export PDF; bottom inset for floating tab bar.
// -----------------------------------------------------------------

import Combine
import CoreData
import SwiftUI

/// - Description: Read-mostly incident screen with leadership and parent follow-up affordances.
struct IncidentDetailView: View {
    @ObservedObject var incident: Incident
    @ObservedObject var viewModel: IncidentViewModel
    @Environment(\.usesFloatingTabBarShell) private var usesFloatingTabBarShell

    @State private var annotations: [BodyMapAnnotation] = []
    @State private var side: BodyMapSide = .front
    @State private var showShare = false
    @State private var shareItems: [Any] = []
    @State private var showEdit = false

    private var status: IncidentStatus {
        IncidentStatus.fromPersistence(incident.status ?? "")
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
        .toolbarBackground(.thinMaterial, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItemGroup(placement: .topBarTrailing) {
                if status == .draft {
                    Button("Edit") {
                        showEdit = true
                    }
                }
                Button {
                    exportPDF()
                } label: {
                    Label("Export PDF", systemImage: "arrow.up.doc.fill")
                }
                .accessibilityIdentifier("export_incident_pdf")
            }
        }
        .onAppear {
            annotations = BodyMapCodec.decode(incident.bodyMapAnnotations)
        }
        .sheet(isPresented: $showShare) {
            ActivityShareView(activityItems: shareItems)
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
            Label {
                Text("Location: \(incident.location ?? "—")")
                    .font(.subheadline.weight(.medium))
            } icon: {
                Image(systemName: "mappin.circle.fill")
                    .foregroundStyle(Color.ncPrimary.opacity(0.9))
            }
            IncidentStatusBadge(status: status)
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

    /// - Description: Builds a temporary PDF on disk and opens the share sheet.
    private func exportPDF() {
        let childName = "\(incident.child?.firstName ?? "") \(incident.child?.lastName ?? "")"
        guard let data = IncidentPDFExporter.pdfData(for: incident, childName: childName) else {
            viewModel.errorMessage = "Unable to build PDF."
            return
        }
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("Incident-\(incident.id?.uuidString ?? "export").pdf")
        do {
            try data.write(to: url)
            shareItems = [url]
            showShare = true
        } catch {
            viewModel.errorMessage = "Unable to write PDF file."
        }
    }
}
