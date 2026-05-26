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
// 100426     Tommy1914   Step rail, grouped review card, footer bar; explicit steps (no TabView paging).
// 100426     Tommy1914   Inline navigation title when presented full-screen over root chrome.
// 140426     Tommy1914   Step rail, review, RIDDOR, success overlay use shared glass card modifiers on iOS 26.
// 140426     Tommy1914   Child picker: full list on focus, filter while typing; list rows without radio circles.
// 140426     Tommy1914   Review step unified card styling for RIDDOR and floating submit button.
// -----------------------------------------------------------------

import Combine
import CoreData
import SwiftUI

/// - Description: Full-screen form that creates or updates draft incidents before submission.
struct NewIncidentFormView: View {
    @ObservedObject var viewModel: IncidentViewModel
    var existingIncident: Incident?
    var embedsInOverlay: Bool = false
    var onDismiss: (() -> Void)?

    @Environment(\.managedObjectContext) private var context
    @Environment(\.dismiss) private var dismiss

    @State private var step: Int = 0
    @State private var selectedChildID: UUID?
    @State private var childSearchText: String = ""
    @FocusState private var isChildSearchFocused: Bool
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
    @State private var validationAlertMessage = "Please complete the required fields before continuing."
    @State private var showSuccess = false

    var body: some View {
        Group {
            if embedsInOverlay {
                overlayFormStack
            } else {
                NavigationStack {
                    standardFormStack
                        .navigationTitle(existingIncident == nil ? "New incident" : "Edit draft")
                        .navigationBarTitleDisplayMode(.inline)
                        .toolbarBackground(.hidden, for: .navigationBar)
                        .toolbar {
                            ToolbarItem(placement: .cancellationAction) {
                                if step == 0 {
                                    Button(role: .cancel) { closeForm() } label: {
                                        Image(systemName: "xmark")
                                    }
                                } else {
                                    Button {
                                        withAnimation(.spring(response: 0.38, dampingFraction: 0.86)) {
                                            step = max(step - 1, 0)
                                        }
                                    } label: {
                                        Label("Back", systemImage: "chevron.backward")
                                    }
                                }
                            }
                            ToolbarItem(placement: .confirmationAction) {
                                if step < 3 {
                                    Button {
                                        advanceStepIfValid()
                                    } label: {
                                        Text("Next")
                                    }
                                    .fontWeight(.semibold)
                                }
                            }
                        }
                }
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
            Text(validationAlertMessage)
        }
        .safeAreaInset(edge: .bottom) {
            if step == 3 && !embedsInOverlay {
                HStack {
                    PrimaryButton(title: "Submit to room leader") {
                        Task { await submit() }
                    }
                    .accessibilityIdentifier(AppConstants.AccessibilityID.submitIncident)
                    .shadow(color: Color.black.opacity(0.14), radius: 14, x: 0, y: 6)
                }
                .padding(.horizontal, 16)
                .padding(.top, 6)
                .padding(.bottom, 8)
                .background(Color.clear)
            }
        }
        .task {
            await viewModel.refresh()
            if let existingIncident {
                hydrate(from: existingIncident)
            }
        }
        .onChange(of: category) { _, newValue in
            severity = newValue.defaultSeverity
            riddorRequired = viewModel.suggestsRiddor(for: newValue)
        }
        .onChange(of: selectedChildID) { _, _ in
            if let selectedChildName {
                childSearchText = selectedChildName
            }
        }
        .onChange(of: isChildSearchFocused) { _, focused in
            if focused {
                if let name = selectedChildName {
                    let trimmed = childSearchText.trimmingCharacters(in: .whitespacesAndNewlines)
                    if trimmed.caseInsensitiveCompare(name) == .orderedSame {
                        childSearchText = ""
                    }
                }
            } else if let name = selectedChildName {
                childSearchText = name
            }
        }
    }

    private var overlayFormStack: some View {
        ZStack(alignment: .bottom) {
            VStack(spacing: 0) {
                overlayGrabber
                overlayHeaderBar
                formStepsContent
            }
            .padding(.horizontal, 20)

            overlayBottomFade
                .allowsHitTesting(false)

            overlayFloatingActions
                .padding(.horizontal, 24)
                .padding(.bottom, 22)
        }
        .ncStudioScreenBackdrop()
    }

    private var overlayBottomFade: some View {
        LinearGradient(
            colors: [
                Color.ncBackground.opacity(0),
                Color.ncGlowBlue.opacity(0.08),
                Color.ncBackground.opacity(0.88),
                Color.ncBackground
            ],
            startPoint: .top,
            endPoint: .bottom
        )
        .frame(maxWidth: .infinity)
        .frame(height: 132)
    }

    private var standardFormStack: some View {
        formStepsContent
            .padding(.horizontal, 16)
            .ncStudioScreenBackdropUnlessChildWorkspace()
    }

    private var formStepsContent: some View {
        VStack(spacing: 0) {
            if embedsInOverlay {
                overlayStepIndicator
                    .padding(.top, 4)
                    .padding(.bottom, 16)
            } else {
                stepRail
                    .padding(.top, 8)
                    .padding(.bottom, 12)
            }

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
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            if embedsInOverlay {
                Color.ncBackground.frame(height: 76)
            }
        }
    }

    private var overlayGrabber: some View {
        Capsule()
            .fill(Color.secondary.opacity(0.28))
            .frame(width: 36, height: 5)
            .padding(.top, 10)
            .padding(.bottom, 4)
            .accessibilityHidden(true)
    }

    private var overlayHeaderBar: some View {
        ZStack(alignment: .center) {
            Text(existingIncident == nil ? "New Incident" : "Edit Draft")
                .font(.headline)

            HStack {
                Spacer()
                Button(role: .cancel) { closeForm() } label: {
                    Image(systemName: "xmark")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.secondary)
                        .frame(width: 32, height: 32)
                        .background(Color.ncCardSurface.opacity(0.92), in: Circle())
                        .overlay {
                            Circle()
                                .strokeBorder(Color.ncGlassHighlight(lightOpacity: 0.35), lineWidth: 0.5)
                        }
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Close")
            }
        }
        .padding(.bottom, 10)
    }

    private var overlayStepIndicator: some View {
        VStack(alignment: .leading, spacing: 8) {
            ProgressView(value: Double(step + 1), total: 4)
                .tint(Color.ncPrimary)
            Text("Step \(step + 1) of 4 · \(Self.formSteps[step].title)")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Step \(step + 1) of 4, \(Self.formSteps[step].title)")
    }

    private var overlayFloatingActions: some View {
        HStack(spacing: 14) {
            if step > 0 {
                overlaySecondaryFloatingButton(title: "Back", systemImage: "chevron.left") {
                    withAnimation(.spring(response: 0.38, dampingFraction: 0.86)) {
                        step = max(step - 1, 0)
                    }
                }
                .transition(.move(edge: .leading).combined(with: .opacity))
            }

            Spacer(minLength: 0)

            if step < 3 {
                overlayPrimaryFloatingButton(title: "Next") {
                    advanceStepIfValid()
                }
                .transition(.move(edge: .trailing).combined(with: .opacity))
            } else {
                overlayPrimaryFloatingButton(title: "Submit") {
                    Task { await submit() }
                }
                .accessibilityIdentifier(AppConstants.AccessibilityID.submitIncident)
                .accessibilityLabel("Submit to room leader")
                .transition(.move(edge: .trailing).combined(with: .opacity))
            }
        }
        .animation(.spring(response: 0.34, dampingFraction: 0.86), value: step)
    }

    private func overlaySecondaryFloatingButton(
        title: String,
        systemImage: String,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: systemImage)
                    .font(.subheadline.weight(.semibold))
                Text(title)
                    .font(.body.weight(.medium))
            }
            .foregroundStyle(Color.ncPrimary)
            .padding(.horizontal, 18)
            .padding(.vertical, 12)
            .background {
                Capsule()
                    .fill(Color.ncCardSurface)
                    .shadow(color: Color.black.opacity(0.08), radius: 10, x: 0, y: 5)
            }
            .overlay {
                Capsule()
                    .strokeBorder(
                        LinearGradient(
                            colors: [
                                Color.ncGlassHighlight(lightOpacity: 0.55),
                                Color.ncGlowBlue.opacity(0.28)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
            }
        }
        .buttonStyle(.plain)
    }

    private func overlayPrimaryFloatingButton(
        title: String,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            Text(title)
                .font(.body.weight(.semibold))
                .foregroundStyle(.white)
                .padding(.horizontal, 24)
                .padding(.vertical, 12)
                .background {
                    Capsule()
                        .fill(
                            LinearGradient(
                                colors: [Color.ncPrimary, Color.ncGlowBlue.opacity(0.88)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .shadow(color: Color.ncGlowBlue.opacity(0.35), radius: 12, x: 0, y: 6)
                }
        }
        .buttonStyle(.plain)
    }

    private func closeForm() {
        if embedsInOverlay {
            onDismiss?()
        } else {
            dismiss()
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
                .foregroundStyle(Color.ncPrimary)
        }
        .padding(14)
        .ncStudioElevatedSurface(cornerRadius: 18)
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
                Text("Fields marked * are required.")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                SectionHeader(title: "Child & category", subtitle: "Choose who this incident relates to.")
                VStack(alignment: .leading, spacing: 10) {
                    HStack(spacing: 8) {
                        Image(systemName: "person.crop.circle.badge.checkmark")
                            .foregroundStyle(Color.ncPrimary)
                        requiredFieldTitle("Child")
                    }
                    if hasAssignableChildren {
                        TextField("Search My Children", text: $childSearchText)
                            .textFieldStyle(.roundedBorder)
                            .textInputAutocapitalization(.words)
                            .focused($isChildSearchFocused)
                            .submitLabel(.search)

                        if shouldShowChildDropdown {
                            if filteredAssignableChildren.isEmpty {
                                Text("No on-site children match your search.")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                    .padding(.vertical, 8)
                            } else {
                                ScrollView {
                                    LazyVStack(alignment: .leading, spacing: 0) {
                                        ForEach(filteredAssignableChildren, id: \.objectID) { child in
                                            childSelectionRow(for: child)
                                        }
                                    }
                                }
                                .frame(maxHeight: 320)
                            }
                        }
                        if selectedChildID == nil {
                            Text("Select a child to continue.")
                                .font(.caption)
                                .foregroundStyle(Color.ncDanger)
                        } else if let name = selectedChildName {
                            Text("Selected: \(name)")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    } else {
                        Label("No child to select. All assigned children are absent.", systemImage: "person.crop.circle.badge.xmark")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(Color.ncDanger)
                            .padding(.vertical, 8)
                    }
                }
                .padding(16)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(Color.ncPrimary.opacity(0.09))
                )
                .overlay {
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(Color.ncPrimary.opacity(0.22), lineWidth: 1)
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
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.ncDanger.opacity(0.08))
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(Color.ncDanger.opacity(0.28), lineWidth: 1)
                }
            }
        }
    }

    private var stepDetails: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                SectionHeader(title: "Details", subtitle: "Describe what happened and the response.")
                VStack(alignment: .leading, spacing: 6) {
                    Text("Location")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.primary)
                    TextField("Location", text: $locationText)
                        .textFieldStyle(.roundedBorder)
                }
                VStack(alignment: .leading, spacing: 6) {
                    requiredFieldTitle("Description")
                    TextEditor(text: $descriptionText)
                        .frame(minHeight: 120)
                        .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.secondary.opacity(0.3)).allowsHitTesting(false))
                    Text("\(descriptionText.count) / \(AppConstants.incidentDescriptionMaxLength)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                VStack(alignment: .leading, spacing: 6) {
                    requiredFieldTitle("Immediate action taken")
                    TextEditor(text: $actionText)
                        .frame(minHeight: 100)
                        .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.secondary.opacity(0.3)).allowsHitTesting(false))
                }
                VStack(alignment: .leading, spacing: 6) {
                    Text("Witnesses")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.primary)
                    TextField("Witnesses", text: $witnessesText)
                        .textFieldStyle(.roundedBorder)
                }
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
                complianceHighlightTile(text: ComplianceContent.incidentReviewComplianceNote)
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
                    IncidentReviewDivider()
                    riddorReviewCard
                }
                .padding(.vertical, 4)
                .ncCardStyle(radius: 16)
            }
            .padding(.bottom, embedsInOverlay ? 24 : 110)
        }
    }

    private func complianceHighlightTile(text: String) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "exclamationmark.shield.fill")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Color.ncPrimary)
                .accessibilityHidden(true)
            Text(text)
                .font(.footnote.weight(.medium))
                .foregroundStyle(.primary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.ncPrimary.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(Color.ncPrimary.opacity(0.24), lineWidth: 1)
                .allowsHitTesting(false)
        }
        .accessibilityElement(children: .combine)
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
                Text(isSeriousCategory
                     ? "Serious incidents must be reported via the statutory RIDDOR and Ofsted workflow."
                     : "Only serious incidents trigger statutory RIDDOR and Ofsted reporting.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 8)
            Toggle("RIDDOR required", isOn: $riddorRequired)
                .labelsHidden()
                .tint(Color.ncPrimary)
                .disabled(isSeriousCategory)
                .accessibilityHint(isSeriousCategory
                    ? "Required for serious incidents"
                    : "Turn on if statutory RIDDOR reporting applies")
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .accessibilityElement(children: .combine)
    }

    private var isSeriousCategory: Bool {
        category == .seriousIncident
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

    @ViewBuilder
    private func requiredFieldTitle(_ title: String) -> some View {
        HStack(spacing: 2) {
            Text(title)
                .font(.subheadline.weight(.semibold))
            Text("*")
                .font(.subheadline.weight(.bold))
                .foregroundStyle(Color.ncDanger)
        }
    }

    private func advanceStepIfValid() {
        switch step {
        case 0:
            guard hasAssignableChildren else {
                validationAlertMessage = "No child is available to select because all assigned children are absent."
                showValidationAlert = true
                return
            }
            guard selectedChildID != nil else {
                validationAlertMessage = "Please select a child before continuing."
                showValidationAlert = true
                return
            }
        case 1:
            guard descriptionText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false,
                  actionText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false else {
                validationAlertMessage = "Please complete Description and Immediate action taken before continuing."
                showValidationAlert = true
                return
            }
        default:
            break
        }

        withAnimation(.spring(response: 0.38, dampingFraction: 0.86)) {
            step = min(step + 1, 3)
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
        .ncCardStyle(radius: 20)
    }

    private var childNameLabel: String {
        guard let id = selectedChildID,
              let child = viewModel.assignableChildren.first(where: { $0.id == id }) else {
            return "Child not selected"
        }
        return child.fullDisplayName
    }

    private var filteredAssignableChildren: [Child] {
        let query = childSearchText.trimmingCharacters(in: .whitespacesAndNewlines)
        let children = viewModel.assignableChildren
        guard query.isEmpty == false else { return children }
        return children.filter { child in
            let roomName = child.roomName ?? ""
            let preferred = child.preferredName ?? ""
            return child.fullDisplayName.localizedCaseInsensitiveContains(query)
                || preferred.localizedCaseInsensitiveContains(query)
                || roomName.localizedCaseInsensitiveContains(query)
        }
    }

    private var selectedChildName: String? {
        guard let id = selectedChildID,
              let child = viewModel.assignableChildren.first(where: { $0.id == id }) else {
            return nil
        }
        let fullName = child.fullDisplayName
        return fullName == "Child" ? "Unnamed child" : fullName
    }

    private var shouldShowChildDropdown: Bool {
        isChildSearchFocused
    }

    private var hasAssignableChildren: Bool {
        !viewModel.assignableChildren.isEmpty
    }

    private func childSelectionRow(for child: Child) -> some View {
        let id = child.id
        let isSelected = id != nil && id == selectedChildID
        let displayName = child.fullDisplayName == "Child" ? "Unnamed child" : child.fullDisplayName

        return Button {
            selectedChildID = id
            isChildSearchFocused = false
        } label: {
            HStack(alignment: .center, spacing: 12) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(displayName)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.primary)
                        .multilineTextAlignment(.leading)
                    if let roomName = child.roomName, roomName.isEmpty == false {
                        Text(roomName)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                Spacer(minLength: 8)
                if isSelected {
                    Image(systemName: "checkmark")
                        .font(.body.weight(.semibold))
                        .foregroundStyle(Color.ncPrimary)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(isSelected ? Color.ncPrimary.opacity(0.1) : Color.clear)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
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
        riddorRequired = viewModel.suggestsRiddor(for: category) ? true : incident.riddorRequired
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
            closeForm()
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
                    .fill(Color.ncPrimary)
                    .frame(width: 30, height: 30)
                    .shadow(color: Color.black.opacity(0.08), radius: 3, x: 0, y: 1)
                Image(systemName: "checkmark")
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(.white)
            } else if isCurrent {
                Circle()
                    .fill(Color.ncCardSurface)
                    .frame(width: 30, height: 30)
                    .overlay {
                        Circle()
                            .stroke(Color.ncPrimary, lineWidth: 2)
                    }
                    .shadow(color: Color.black.opacity(0.05), radius: 3, x: 0, y: 0)
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
                filled ? Color.ncPrimary.opacity(0.65) : Color.secondary.opacity(0.22)
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
