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
// -----------------------------------------------------------------

import CoreData
import SwiftUI

/// - Description: Read-mostly incident screen with leadership and parent follow-up affordances.
struct IncidentDetailView: View {
    @ObservedObject var incident: Incident
    @ObservedObject var viewModel: IncidentViewModel

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
            VStack(alignment: .leading, spacing: 20) {
                statusTracker
                IncidentSeverityIndicator(severity: IncidentSeverity.fromPersistence(incident.severity ?? ""))
                metaSection
                textSection(title: "Description", text: incident.incidentDescription ?? "")
                textSection(title: "Immediate action", text: incident.immediateActionTaken ?? "")
                textSection(title: "Witnesses", text: incident.witnesses ?? "")
                BodyMapView(isInteractive: false, annotations: $annotations, side: $side)
                PrimaryButton(title: "Export as PDF") {
                    exportPDF()
                }
            }
            .padding()
        }
        .background(Color.ncBackground.ignoresSafeArea())
        .navigationTitle("Incident")
        .toolbar {
            if status == .draft {
                ToolbarItem(placement: .primaryAction) {
                    Button("Edit") {
                        showEdit = true
                    }
                }
            }
        }
        .onAppear {
            annotations = BodyMapCodec.decode(incident.bodyMapAnnotations)
        }
        .sheet(isPresented: $showShare) {
            ActivityShareView(activityItems: shareItems)
        }
        .sheet(isPresented: $showEdit) {
            NewIncidentFormView(viewModel: viewModel, existingIncident: incident)
                .environment(\.managedObjectContext, incident.managedObjectContext ?? PersistenceController.shared.container.viewContext)
        }
    }

    private var statusTracker: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Progress")
                .font(AppTheme.titleRounded())
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(IncidentStatus.allCases, id: \.self) { step in
                        VStack(spacing: 6) {
                            Circle()
                                .fill(step.stepIndex <= status.stepIndex ? Color.ncPrimary : Color.secondary.opacity(0.3))
                                .frame(width: 16, height: 16)
                            Text(step.title)
                                .font(.caption2)
                                .multilineTextAlignment(.center)
                                .frame(width: 90)
                        }
                    }
                }
            }
        }
    }

    private var metaSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            if let timestamp = incident.timestamp {
                Text("Recorded \(timestamp.formatted(date: .abbreviated, time: .shortened))")
                    .font(.headline)
            }
            Text("Location: \(incident.location ?? "")")
                .font(.subheadline)
            IncidentStatusBadge(status: status)
        }
    }

    private func textSection(title: String, text: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.headline)
            Text(text)
                .font(.body)
        }
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
