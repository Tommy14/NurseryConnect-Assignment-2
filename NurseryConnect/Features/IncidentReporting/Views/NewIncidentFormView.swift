//
//  NewIncidentFormView.swift
//  NurseryConnect
//
//  Feature: Incident Reporting
//  Role: Keyworker
//  Created: 8 April 2026
//  Description: Multi-step incident capture with body map and statutory timestamp handling.
//
// -----------------------------------------------------------------
// Date       Name        What has done
// -----------------------------------------------------------------
// 080426     Tommy1914   Created the file with stepped flow, validation, and submission animation.
// -----------------------------------------------------------------

import Combine
import CoreData
import SwiftUI

/// - Description: Full-screen form that creates or updates draft incidents before submission.
struct NewIncidentFormView: View {
    @ObservedObject var viewModel: IncidentViewModel
    var existingIncident: Incident?

    @Environment(\.managedObjectContext) private var context
    @Environment(\.dismiss) private var dismiss

    @State private var step: Int = 0
    @State private var selectedChildID: UUID?
    @State private var category: IncidentCategory = .accidentMinor
    @State private var severity: IncidentSeverity = .minor
    @State private var locationText: String = ""
    @State private var descriptionText: String = ""
    @State private var actionText: String = ""
    @State private var witnessesText: String = ""
    @State private var annotations: [BodyMapAnnotation] = []
    @State private var bodySide: BodyMapSide = .front
    @State private var riddorRequired: Bool = false
    @State private var showValidationAlert = false
    @State private var showSuccess = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                stepIndicator
                TabView(selection: $step) {
                    stepChildAndCategory.tag(0)
                    stepDetails.tag(1)
                    stepBodyMap.tag(2)
                    stepReview.tag(3)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .animation(.spring(), value: step)

                navigationButtons
            }
            .padding()
            .background(Color.ncBackground.ignoresSafeArea())
            .navigationTitle(existingIncident == nil ? "New incident" : "Edit draft")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
            }
            .overlay(alignment: .center) {
                if showSuccess {
                    successOverlay
                }
            }
            .alert("Missing information", isPresented: $showValidationAlert) {
                Button("OK", role: .cancel) {}
            } message: {
                Text("Please complete description and immediate action before submitting.")
            }
            .task {
                await viewModel.refresh()
                if let existingIncident {
                    hydrate(from: existingIncident)
                } else if selectedChildID == nil {
                    selectedChildID = viewModel.assignableChildren.first?.id
                }
            }
            .onChange(of: category) { _, newValue in
                severity = newValue.defaultSeverity
                riddorRequired = viewModel.suggestsRiddor(for: newValue)
            }
        }
    }

    private var stepIndicator: some View {
        HStack {
            ForEach(0..<4, id: \.self) { index in
                Circle()
                    .fill(index <= step ? Color.ncPrimary : Color.secondary.opacity(0.3))
                    .frame(width: 10, height: 10)
            }
        }
        .accessibilityHidden(true)
    }

    private var stepChildAndCategory: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                SectionHeader(title: "Child & category", subtitle: "Choose who this incident relates to.")
                Picker("Child", selection: $selectedChildID) {
                    Text("Select a child").tag(Optional<UUID>.none)
                    ForEach(
                        viewModel.assignableChildren.compactMap { child -> (UUID, String)? in
                            guard let id = child.id else { return nil }
                            let name = "\(child.firstName ?? "") \(child.lastName ?? "")"
                            return (id, name)
                        },
                        id: \.0
                    ) { item in
                        Text(item.1).tag(Optional(item.0))
                    }
                }
                IncidentCategoryPicker(selection: $category)
                IncidentSeverityIndicator(severity: severity)
                VStack(alignment: .leading, spacing: 6) {
                    HStack(spacing: 8) {
                        Image(systemName: "lock.fill")
                            .foregroundStyle(.secondary)
                        Text("Timestamp")
                            .font(.headline)
                    }
                    Text(Date().formatted(date: .abbreviated, time: .shortened))
                        .font(.title3.monospacedDigit())
                    Text("Timestamp is set automatically to comply with EYFS regulations.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
                .padding()
                .background(Color.ncCardSurface)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            }
        }
    }

    private var stepDetails: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                SectionHeader(title: "Details", subtitle: "Describe what happened and the response.")
                TextField("Location", text: $locationText)
                    .textFieldStyle(.roundedBorder)
                VStack(alignment: .leading) {
                    Text("Description")
                        .font(.subheadline.weight(.semibold))
                    TextEditor(text: $descriptionText)
                        .frame(minHeight: 120)
                        .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.secondary.opacity(0.3)))
                    Text("\(descriptionText.count) / \(AppConstants.incidentDescriptionMaxLength)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                VStack(alignment: .leading) {
                    Text("Immediate action taken")
                        .font(.subheadline.weight(.semibold))
                    TextEditor(text: $actionText)
                        .frame(minHeight: 100)
                        .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.secondary.opacity(0.3)))
                }
                TextField("Witnesses", text: $witnessesText)
                    .textFieldStyle(.roundedBorder)
            }
        }
    }

    private var stepBodyMap: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                SectionHeader(title: "Body map", subtitle: "Tap the outline to place injury markers.")
                BodyMapView(isInteractive: true, annotations: $annotations, side: $bodySide)
            }
        }
    }

    private var stepReview: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                SectionHeader(title: "Review & submit", subtitle: "Confirm details before notifying leadership.")
                Group {
                    Text(childNameLabel).font(.headline)
                    Text(category.title).font(.subheadline)
                    Text("Severity: \(severity.title)").font(.footnote)
                    Text("Location: \(locationText)").font(.footnote)
                    Text("Description: \(descriptionText)").font(.footnote)
                    Text("Action: \(actionText)").font(.footnote)
                }
                Toggle("RIDDOR required", isOn: $riddorRequired)
                    .tint(Color.ncPrimary)
                PrimaryButton(title: "Submit to room leader") {
                    Task { await submit() }
                }
                .accessibilityIdentifier(AppConstants.AccessibilityID.submitIncident)
            }
        }
    }

    private var navigationButtons: some View {
        HStack {
            Button("Back") {
                withAnimation(.spring()) {
                    step = max(step - 1, 0)
                }
            }
            .disabled(step == 0)
            Spacer()
            if step < 3 {
                Button("Next") {
                    withAnimation(.spring()) {
                        step = min(step + 1, 3)
                    }
                }
                .buttonStyle(.borderedProminent)
            }
        }
    }

    private var successOverlay: some View {
        VStack(spacing: 12) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 64))
                .foregroundStyle(Color.ncSecondary)
                .scaleEffect(showSuccess ? 1.0 : 0.5)
                .animation(.spring(response: 0.45, dampingFraction: 0.65), value: showSuccess)
            Text("Submitted")
                .font(AppTheme.headlineRounded())
        }
        .padding(32)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
    }

    private var childNameLabel: String {
        guard let id = selectedChildID,
              let child = viewModel.assignableChildren.first(where: { $0.id == id }) else {
            return "Child not selected"
        }
        return "\(child.firstName ?? "") \(child.lastName ?? "")".trimmingCharacters(in: .whitespaces)
    }

    /// - Description: Prefills state from a draft incident for editing.
    /// - Parameters:
    ///   - incident: Draft record loaded from Core Data.
    private func hydrate(from incident: Incident) {
        selectedChildID = incident.child?.id
        category = IncidentCategory.fromPersistence(incident.category ?? "")
        severity = IncidentSeverity.fromPersistence(incident.severity ?? "")
        locationText = incident.location ?? ""
        descriptionText = incident.incidentDescription ?? ""
        actionText = incident.immediateActionTaken ?? ""
        witnessesText = incident.witnesses ?? ""
        annotations = BodyMapCodec.decode(incident.bodyMapAnnotations)
        riddorRequired = incident.riddorRequired
    }

    /// - Description: Validates and either updates a draft or creates a submitted incident.
    private func submit() async {
        guard descriptionText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false,
              actionText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false else {
            showValidationAlert = true
            return
        }
        guard let childID = selectedChildID,
              let child = viewModel.assignableChildren.first(where: { $0.id == childID }) else {
            viewModel.errorMessage = "Please select a child."
            return
        }

        let incident = existingIncident ?? Incident(context: context)
        if incident.id == nil {
            incident.id = UUID()
        }
        // EYFS: Timestamp is set from device clock and locked to prevent backdating — statutory requirement
        incident.timestamp = Date()
        incident.category = category.persistenceValue
        incident.severity = severity.persistenceValue
        incident.location = locationText
        incident.incidentDescription = descriptionText
        incident.immediateActionTaken = actionText
        incident.witnesses = witnessesText
        incident.bodyMapAnnotations = BodyMapCodec.encode(annotations)
        incident.riddorRequired = riddorRequired
        incident.isParentNotified = false
        incident.managerCountersigned = false
        incident.child = child
        incident.status = IncidentStatus.submitted.persistenceValue

        NCHaptics.success()
        withAnimation(.spring(response: 0.45, dampingFraction: 0.75)) {
            showSuccess = true
        }
        await viewModel.submit(incident: incident)
        try? await Task.sleep(nanoseconds: 900_000_000)
        await MainActor.run {
            dismiss()
        }
    }
}
