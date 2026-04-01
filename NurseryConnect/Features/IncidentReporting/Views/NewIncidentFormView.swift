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
// 120426     Tommy1914   Step rail, grouped review card, footer bar; explicit steps (no TabView paging).
// 130426     Tommy1914   Inline navigation title when presented full-screen over root chrome.
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
            VStack(spacing: 0) {
                stepRail
                    .padding(.top, 8)
                    .padding(.bottom, 12)

                Group {
                    switch step {
                    case 0: stepChildAndCategory
                    case 1: stepDetails
                    case 2: stepBodyMap
                    case 3: stepReview
                    default: EmptyView()
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .animation(.spring(response: 0.38, dampingFraction: 0.86), value: step)

                incidentFormNavigationFooter
            }
            .padding(.horizontal, 16)
            .background(Color.ncBackground.ignoresSafeArea())
            .navigationTitle(existingIncident == nil ? "New incident" : "Edit draft")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close", role: .cancel) { dismiss() }
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

    private var stepRail: some View {
        VStack(spacing: 10) {
            HStack(spacing: 0) {
                ForEach(0..<4, id: \.self) { index in
                    IncidentFormStepBubble(
                        index: index,
                        currentStep: step,
                        symbol: Self.formSteps[index].symbol
                    )
                    if index < 3 {
                        IncidentFormStepConnector(filled: step > index)
                    }
                }
            }
            Text(Self.formSteps[step].title)
                .font(.caption.weight(.semibold))
                .foregroundStyle(
                    LinearGradient(
                        colors: [Color.ncPrimary, Color.cyan.opacity(0.85)],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
        }
        .padding(14)
        .background {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color.ncCardSurface)
                .shadow(color: Color.black.opacity(0.06), radius: 10, x: 0, y: 4)
                .overlay {
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(
                            LinearGradient(
                                colors: [
                                    Color.ncPrimary.opacity(0.28),
                                    Color.cyan.opacity(0.15),
                                    Color.ncPrimary.opacity(0.1)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Step \(step + 1) of 4, \(Self.formSteps[step].title)")
    }

    private static let formSteps: [(title: String, symbol: String)] = [
        ("Child & category", "person.crop.circle.fill"),
        ("Details", "text.alignleft.fill"),
        ("Body map", "figure.stand"),
        ("Review", "checkmark.seal.fill")
    ]

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
                        .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.secondary.opacity(0.3)).allowsHitTesting(false))
                    Text("\(descriptionText.count) / \(AppConstants.incidentDescriptionMaxLength)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                VStack(alignment: .leading) {
                    Text("Immediate action taken")
                        .font(.subheadline.weight(.semibold))
                    TextEditor(text: $actionText)
                        .frame(minHeight: 100)
                        .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.secondary.opacity(0.3)).allowsHitTesting(false))
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
                VStack(spacing: 0) {
                    IncidentReviewInfoRow(
                        icon: "person.fill",
                        title: "Child",
                        value: childNameLabel
                    )
                    IncidentReviewDivider()
                    IncidentReviewInfoRow(
                        icon: "folder.fill",
                        title: "Category",
                        value: category.title
                    )
                    IncidentReviewDivider()
                    IncidentReviewInfoRow(
                        icon: "exclamationmark.triangle.fill",
                        title: "Severity",
                        value: severity.title
                    )
                    IncidentReviewDivider()
                    IncidentReviewInfoRow(
                        icon: "mappin.and.ellipse",
                        title: "Location",
                        value: displayValue(locationText)
                    )
                    IncidentReviewDivider()
                    IncidentReviewInfoRow(
                        icon: "text.alignleft",
                        title: "Description",
                        value: displayValue(descriptionText)
                    )
                    IncidentReviewDivider()
                    IncidentReviewInfoRow(
                        icon: "cross.case.fill",
                        title: "Immediate action",
                        value: displayValue(actionText)
                    )
                    IncidentReviewDivider()
                    IncidentReviewInfoRow(
                        icon: "person.wave.2.fill",
                        title: "Witnesses",
                        value: displayValue(witnessesText)
                    )
                    IncidentReviewDivider()
                    IncidentReviewInfoRow(
                        icon: "figure.stand",
                        title: "Body map",
                        value: bodyMapReviewSummary
                    )
                }
                .padding(.vertical, 4)
                .background(Color.ncCardSurface)
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 3)
                .overlay {
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(Color.secondary.opacity(0.12), lineWidth: 1)
                        .allowsHitTesting(false)
                }

                riddorReviewCard

                PrimaryButton(title: "Submit to room leader") {
                    Task { await submit() }
                }
                .accessibilityIdentifier(AppConstants.AccessibilityID.submitIncident)
            }
            .padding(.bottom, 8)
        }
    }

    private var riddorReviewCard: some View {
        HStack(alignment: .center, spacing: 12) {
            Image(systemName: "shield.lefthalf.filled")
                .font(.title3)
                .foregroundStyle(
                    LinearGradient(
                        colors: [Color.ncAccentWarm, Color.orange.opacity(0.85)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 4) {
                Text("RIDDOR required")
                    .font(.subheadline.weight(.semibold))
                Text("Toggle if this must be reported to the regulator (HSE).")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 8)
            Toggle("RIDDOR required", isOn: $riddorRequired)
                .labelsHidden()
                .tint(Color.ncPrimary)
        }
        .padding(16)
        .background(Color.ncCardSurface)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 3)
        .overlay {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Color.secondary.opacity(0.12), lineWidth: 1)
                .allowsHitTesting(false)
        }
        .accessibilityElement(children: .combine)
    }

    private var bodyMapReviewSummary: String {
        let n = annotations.count
        if n == 0 { return "No markers placed" }
        return "\(n) marker\(n == 1 ? "" : "s")"
    }

    private func displayValue(_ raw: String) -> String {
        let t = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        return t.isEmpty ? "—" : t
    }

    private var incidentFormNavigationFooter: some View {
        VStack(spacing: 0) {
            Divider()
                .opacity(0.35)
            HStack(spacing: 12) {
                Button {
                    withAnimation(.spring(response: 0.38, dampingFraction: 0.86)) {
                        step = max(step - 1, 0)
                    }
                } label: {
                    Label("Back", systemImage: "chevron.backward")
                }
                .buttonStyle(.bordered)
                .disabled(step == 0)

                Spacer(minLength: 0)

                if step < 3 {
                    Button {
                        withAnimation(.spring(response: 0.38, dampingFraction: 0.86)) {
                            step = min(step + 1, 3)
                        }
                    } label: {
                        Label("Next", systemImage: "chevron.forward")
                            .labelStyle(.titleAndIcon)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(Color.ncPrimary)
                }
            }
            .padding(.vertical, 12)
            .padding(.horizontal, 16)
        }
        .padding(.horizontal, -16)
        .padding(.bottom, 4)
        .background {
            Rectangle()
                .fill(.ultraThinMaterial)
                .ignoresSafeArea(edges: .bottom)
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

// MARK: - Step rail components

private struct IncidentFormStepBubble: View {
    let index: Int
    let currentStep: Int
    let symbol: String

    private var isDone: Bool { index < currentStep }
    private var isCurrent: Bool { index == currentStep }

    var body: some View {
        ZStack {
            if isDone {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color.ncPrimary, Color.cyan.opacity(0.75)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 30, height: 30)
                    .shadow(color: Color.ncPrimary.opacity(0.25), radius: 4, x: 0, y: 2)
                Image(systemName: "checkmark")
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(.white)
            } else if isCurrent {
                Circle()
                    .fill(Color.ncCardSurface)
                    .frame(width: 30, height: 30)
                    .overlay {
                        Circle()
                            .stroke(
                                LinearGradient(
                                    colors: [Color.ncPrimary, Color.cyan.opacity(0.85)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 2
                            )
                    }
                    .shadow(color: Color.ncPrimary.opacity(0.35), radius: 6, x: 0, y: 0)
                Image(systemName: symbol)
                    .font(.caption)
                    .foregroundStyle(Color.ncPrimary)
                    .symbolRenderingMode(.hierarchical)
            } else {
                Circle()
                    .strokeBorder(Color.secondary.opacity(0.35), lineWidth: 1.5)
                    .background(Circle().fill(Color.ncCardSurface.opacity(0.65)))
                    .frame(width: 30, height: 30)
                Image(systemName: symbol)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .symbolRenderingMode(.hierarchical)
            }
        }
        .frame(width: 34, height: 34)
        .accessibilityHidden(true)
    }
}

private struct IncidentFormStepConnector: View {
    let filled: Bool

    var body: some View {
        RoundedRectangle(cornerRadius: 2, style: .continuous)
            .fill(
                filled
                    ? LinearGradient(
                        colors: [Color.ncPrimary.opacity(0.95), Color.cyan.opacity(0.55)],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                    : LinearGradient(
                        colors: [Color.secondary.opacity(0.22), Color.secondary.opacity(0.22)],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
            )
            .frame(height: 4)
            .frame(maxWidth: .infinity)
            .padding(.horizontal, 2)
            .accessibilityHidden(true)
    }
}

// MARK: - Review summary rows

private struct IncidentReviewInfoRow: View {
    let icon: String
    let title: String
    let value: String

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.body)
                .foregroundStyle(Color.ncPrimary)
                .frame(width: 26, alignment: .center)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                Text(value)
                    .font(.body)
                    .foregroundStyle(.primary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 0)
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 14)
        .accessibilityElement(children: .combine)
    }
}

private struct IncidentReviewDivider: View {
    var body: some View {
        Rectangle()
            .fill(Color.secondary.opacity(0.12))
            .frame(height: 1)
            .padding(.leading, 52)
    }
}
