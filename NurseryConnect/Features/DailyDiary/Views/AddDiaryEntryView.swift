//
//  AddDiaryEntryView.swift
//  NurseryConnect
//
//  Feature: Daily Diary
//  Role: Keyworker
//  Created: 5 April 2026
//  Description: Multi-section form for composing any supported diary entry type.
//
// -----------------------------------------------------------------
// Date       Name        What has done
// -----------------------------------------------------------------
// 050426     Tommy1914   Created the file with type chips, validation, and save flow.
// 100426     Tommy1914   Card chrome, symbol chips, atmosphere background (iOS-native polish).
// 100426     Tommy1914   Decorative overlays use allowsHitTesting(false) so fields remain tappable.
// 140426     Tommy1914   Details and notes panels use `ncCardStyle` (glass plate on iOS 26).
// -----------------------------------------------------------------

import Combine
import CoreData
import SwiftUI

/// - Description: Sheet form that creates a `DiaryEntry` for the selected child.
struct AddDiaryEntryView: View {
    enum EntryMode {
        case create
        case correction(existingEntry: DiaryEntry)
    }

    enum CorrectionReasonOption: String, CaseIterable, Identifiable {
        case typo = "Typographical error"
        case missingDetail = "Missing detail added"
        case wrongChildContext = "Wrong child context corrected"
        case timeAdjustment = "Event time adjusted"
        case complianceClarification = "Compliance clarification"
        case other = "Other"

        var id: String { rawValue }
    }

    let childID: UUID
    @ObservedObject var viewModel: DailyDiaryViewModel
    let childAllergies: String
    /// - Description: When set, pre-fills type, meal slot, and default log time from a planned session row.
    var plannedSessionContext: PlannedSessionLogContext?
    /// - Description: When false, save is blocked (e.g. before check-in or after check-out). Re-evaluated on each save attempt.
    private let isDiaryLoggingPermitted: () -> Bool
    private let mode: EntryMode

    @Environment(\.dismiss) private var dismiss

    @State private var selectedType: DiaryEntryType = .activity
    @State private var logTimestamp: Date = Date()
    @State private var notes: String = ""
    @State private var activityKind: DiaryActivityKind = .indoorPlay
    @State private var eyfsArea: EyfsArea = .communication
    @State private var durationMinutes: Int = 15
    @State private var sleepStart: Date = Date()
    @State private var sleepEnd: Date = Date().addingTimeInterval(3600)
    @State private var sleepPosition: SleepPosition = .back
    @State private var sleepDisturbances: Bool = false
    @State private var mealSlot: MealSlot = .lunch
    @State private var mealIsFluidOnly: Bool = false
    @State private var mealDescription: String = ""
    @State private var mealConsumption: MealConsumptionLevel = .most
    @State private var fluidIntake: Int = 100
    @State private var fluidKind: FluidKind = .water
    @State private var nappyKind: NappyObservationKind = .wet
    @State private var nappyConcern: Bool = false
    @State private var nappyCream: Bool = false
    @State private var moodRating: Int16 = 3
    @State private var milestoneEyfs: EyfsArea = .communication
    @State private var milestoneText: String = ""
    @State private var milestoneNextSteps: String = ""
    @State private var milestoneEvidence: String = ""
    @State private var showValidationAlert = false
    @State private var validationMessage = ""
    @State private var didApplyPlannedPrefill = false
    @State private var didApplyCorrectionPrefill = false
    @State private var selectedCorrectionReason: CorrectionReasonOption = .typo
    @State private var correctionReasonOtherText: String = ""

    private var isCorrectionMode: Bool {
        if case .correction = mode { return true }
        return false
    }

    init(
        childID: UUID,
        viewModel: DailyDiaryViewModel,
        childAllergies: String = "",
        mode: EntryMode = .create,
        plannedSessionContext: PlannedSessionLogContext? = nil,
        isDiaryLoggingPermitted: @escaping () -> Bool = { true }
    ) {
        self.childID = childID
        self.viewModel = viewModel
        self.childAllergies = childAllergies
        self.mode = mode
        self.plannedSessionContext = plannedSessionContext
        self.isDiaryLoggingPermitted = isDiaryLoggingPermitted
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    Text("Fields marked * are required.")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                    if let ctx = plannedSessionContext {
                        Text(ctx.sessionSubtitle)
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(Color.ncPrimary)
                            .padding(.horizontal, 4)
                    }
                    diaryTypeChipStrip
                    detailsCard
                    notesCard
                }
                .padding()
            }
            .scrollIndicators(.hidden)
            .background { diaryFormAtmosphereBackground }
            .navigationTitle(isCorrectionMode ? "Correct entry" : "New entry")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(role: .cancel) { dismiss() } label: {
                        Image(systemName: "xmark")
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(isCorrectionMode ? "Apply correction" : "Save") { Task { await save() } }
                        .fontWeight(.semibold)
                        .tint(Color.ncPrimary)
                        .accessibilityIdentifier(AppConstants.AccessibilityID.saveDiaryEntry)
                }
            }
            .toolbarBackground(Color.ncBackground, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
        }
        .background(Color.ncBackground.ignoresSafeArea())
        .tint(Color.ncPrimary)
        .onAppear {
            applyPlannedSessionPrefillIfNeeded()
            applyCorrectionPrefillIfNeeded()
        }
        .alert("Required fields missing", isPresented: $showValidationAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(validationMessage)
        }
    }

    /// - Description: Sets suggested type, meal slot, and log time when opened from a planned session.
    private func applyPlannedSessionPrefillIfNeeded() {
        guard !didApplyPlannedPrefill, let ctx = plannedSessionContext else { return }
        didApplyPlannedPrefill = true
        let t = ctx.defaultLogTimestamp()
        logTimestamp = t
        selectedType = ctx.suggestedEntryType
        if let slot = ctx.suggestedMealSlot {
            mealSlot = slot
        }
        if selectedType == .sleep {
            sleepStart = t
            sleepEnd = t.addingTimeInterval(30 * 60)
        }
    }

    private func applyCorrectionPrefillIfNeeded() {
        guard !didApplyCorrectionPrefill else { return }
        didApplyCorrectionPrefill = true
        guard case .correction(let entry) = mode else { return }

        selectedType = DiaryEntryType.fromPersistence(entry.entryType ?? "")
        logTimestamp = entry.timestamp ?? Date()
        notes = entry.notes ?? ""
        activityKind = DiaryActivityKind(rawValue: entry.activityType ?? "") ?? .indoorPlay
        eyfsArea = EyfsArea(rawValue: entry.eyfsArea ?? "") ?? .communication
        durationMinutes = max(5, Int(entry.duration))
        sleepStart = entry.timestamp ?? Date()
        sleepEnd = (entry.timestamp ?? Date()).addingTimeInterval(TimeInterval(max(1, entry.duration)) * 60)
        sleepPosition = SleepPosition(rawValue: entry.sleepPosition ?? "") ?? .back
        if let slot = MealSlot(rawValue: entry.activityType ?? "") {
            mealSlot = slot
            mealIsFluidOnly = false
        } else {
            mealIsFluidOnly = (entry.activityType == "Fluid Intake")
        }
        mealDescription = entry.mealDescription ?? ""
        mealConsumption = MealConsumptionLevel.fromPersistence(entry.mealConsumed)
        fluidIntake = max(0, Int(entry.fluidIntake))
        fluidKind = FluidKind(rawValue: entry.fluidType ?? "") ?? .water
        nappyKind = NappyObservationKind(rawValue: entry.nappyType ?? "") ?? .wet
        moodRating = entry.moodRating == 0 ? 3 : entry.moodRating
        milestoneEyfs = EyfsArea(rawValue: entry.eyfsArea ?? "") ?? .communication
        milestoneText = selectedType == .milestone ? (entry.activityType ?? "") : ""
    }

    private var diaryFormAtmosphereBackground: some View {
        Color.ncBackground.ignoresSafeArea()
    }

    private var diaryTypeChipStrip: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(DiaryEntryType.allCases, id: \.self) { type in
                    let selected = selectedType == type
                    Button {
                        withAnimation(.spring(response: 0.38, dampingFraction: 0.82)) {
                            selectedType = type
                        }
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: Self.symbolName(for: type))
                                .font(.subheadline.weight(.semibold))
                                .symbolRenderingMode(.hierarchical)
                            Text(chipTitle(for: type))
                                .font(.subheadline.weight(.semibold))
                        }
                        .foregroundStyle(selected ? Color.white : Color.primary)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 10)
                        .background {
                            if selected {
                                Capsule(style: .continuous)
                                    .fill(Color.ncPrimary)
                                    .shadow(color: Color.black.opacity(0.08), radius: 4, x: 0, y: 2)
                            } else {
                                Capsule(style: .continuous)
                                    .fill(Color.ncCardSurface)
                                    .shadow(color: Color.black.opacity(0.04), radius: 6, x: 0, y: 3)
                            }
                        }
                        .overlay {
                            if !selected {
                                Capsule(style: .continuous)
                                    .stroke(Color.secondary.opacity(0.2), lineWidth: 1)
                            }
                        }
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(chipTitle(for: type))
                }
            }
        }
    }

    private var detailsCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            SectionHeader(title: "Details", subtitle: "Required fields are highlighted if missing.")
            VStack(alignment: .leading, spacing: 14) {
                if selectedType != .sleep {
                    DatePicker("Event time", selection: $logTimestamp, displayedComponents: [.date, .hourAndMinute])
                    Text("Submission time is recorded automatically when you save.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                typeSpecificFields
            }
            .tint(Color.ncPrimary)
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .ncCardStyle(radius: 20)
    }

    private var notesCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            textEditorCard(
                label: notesLabelText,
                icon: "note.text",
                text: $notes,
                placeholder: "Add observations, context, or follow-up…"
            )
            if isCorrectionMode {
                VStack(alignment: .leading, spacing: 10) {
                    Label("Reason for correction *", systemImage: "pencil.and.list.clipboard")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Color.primary)
                    Picker("Reason for correction", selection: $selectedCorrectionReason) {
                        ForEach(CorrectionReasonOption.allCases) { reason in
                            Text(reason.rawValue).tag(reason)
                        }
                    }
                    .pickerStyle(.menu)
                    if selectedCorrectionReason == .other {
                        textEditorCard(
                            label: "Other reason details *",
                            icon: "text.bubble",
                            text: $correctionReasonOtherText,
                            placeholder: "Enter the correction reason."
                        )
                    }
                }
                .accessibilityIdentifier("diary_correction_reason")
            }
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .ncCardStyle(radius: 20)
    }

    private func textEditorCard(
        label: String,
        icon: String,
        text: Binding<String>,
        placeholder: String
    ) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Label(label, systemImage: icon)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Color.primary)
            TextEditor(text: text)
                .scrollContentBackground(.hidden)
                .frame(minHeight: 110)
                .padding(12)
                .background(Color.ncCardSurface)
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(
                            LinearGradient(
                                colors: [Color.secondary.opacity(0.18), Color.ncPrimary.opacity(0.14)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                        .allowsHitTesting(false)
                }
                .overlay(alignment: .topLeading) {
                    if text.wrappedValue.isEmpty {
                        Text(placeholder)
                            .font(.body)
                            .foregroundStyle(.tertiary)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 20)
                            .allowsHitTesting(false)
                    }
                }
        }
    }

    private var notesLabelText: String {
        selectedType == .wellbeing ? "Notes" : "Notes *"
    }

    private var validationCallout: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.title2)
                .symbolRenderingMode(.palette)
                .foregroundStyle(Color.ncDanger, Color.ncDanger.opacity(0.35))
            VStack(alignment: .leading, spacing: 6) {
                Text("Almost there")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Color.primary)
                Text("Please complete:")
                    .font(.caption.weight(.medium))
                    .foregroundStyle(.secondary)
                ForEach(validation.missingFields, id: \.self) { field in
                    Text(field)
                        .font(.footnote.weight(.medium))
                        .foregroundStyle(Color.ncDanger)
                }
            }
            Spacer(minLength: 0)
        }
        .padding(16)
        .background {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color.ncDanger.opacity(0.08))
        }
        .overlay {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(
                    LinearGradient(
                        colors: [Color.ncDanger.opacity(0.45), Color.ncDanger.opacity(0.15)],
                        startPoint: .leading,
                        endPoint: .trailing
                    ),
                    lineWidth: 1
                )
                .allowsHitTesting(false)
        }
    }

    private var validation: DiaryDraftValidation {
        viewModel.validate(
            type: selectedType,
            notes: notesForType(),
            activityType: activityKind.rawValue,
            eyfsArea: eyfsArea.rawValue,
            mealDescription: mealDescription,
            milestoneDescription: milestoneText,
            isMealFluidOnly: mealIsFluidOnly
        )
    }

    @ViewBuilder
    private var typeSpecificFields: some View {
        switch selectedType {
        case .activity:
            Text("Activity type *")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
            Picker("Activity type *", selection: $activityKind) {
                ForEach(DiaryActivityKind.allCases) { kind in
                    Text(kind.rawValue).tag(kind)
                }
            }
            .pickerStyle(.menu)
            Text("EYFS area *")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
            Picker("EYFS area *", selection: $eyfsArea) {
                ForEach(EyfsArea.allCases) { area in
                    Text(area.rawValue).tag(area)
                }
            }
            .pickerStyle(.menu)
            Stepper("Duration: \(durationMinutes) minutes", value: $durationMinutes, in: 5...180, step: 5)
        case .sleep:
            DatePicker("Start", selection: $sleepStart, displayedComponents: [.hourAndMinute])
            DatePicker("End", selection: $sleepEnd, displayedComponents: [.hourAndMinute])
            Text("Sleep position")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
            Picker("Sleep position", selection: $sleepPosition) {
                ForEach(SleepPosition.allCases) { pos in
                    Text(pos.rawValue).tag(pos)
                }
            }
            .pickerStyle(.menu)
            Toggle("Disturbances noted", isOn: $sleepDisturbances)
        case .meal:
            Toggle("Only Fluid intake", isOn: $mealIsFluidOnly)
            if !allergiesTrimmed.isEmpty {
                mealAllergyWarning
            }
            if !mealIsFluidOnly {
                Text("Meal Time")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                Picker("Meal Time", selection: $mealSlot) {
                    ForEach(MealSlot.allCases) { slot in
                        Text(slot.rawValue).tag(slot)
                    }
                }
                .pickerStyle(.menu)
                TextField("Food description *", text: $mealDescription)
                    .padding(12)
                    .background(Color.ncCardSurface)
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    .overlay {
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .stroke(Color.secondary.opacity(0.18), lineWidth: 1)
                    }
                mealConsumptionPicker
            }
            Stepper("Fluid intake: \(fluidIntake) ml", value: $fluidIntake, in: 0...1000, step: 25)
            Text("Fluid type")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
            Picker("Fluid type", selection: $fluidKind) {
                ForEach(FluidKind.allCases) { fluid in
                    Text(fluid.rawValue).tag(fluid)
                }
            }
            .pickerStyle(.menu)
        case .nappy:
            Text("Nappy type")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.primary)
            Picker("Nappy type", selection: $nappyKind) {
                ForEach(NappyObservationKind.allCases) { kind in
                    Text(kind.rawValue).tag(kind)
                }
            }
            .pickerStyle(.menu)
            Toggle("Concern flagged", isOn: $nappyConcern)
            Toggle("Cream applied", isOn: $nappyCream)
        case .wellbeing:
            moodPicker
        case .milestone:
            Text("EYFS area")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
            Picker("EYFS area", selection: $milestoneEyfs) {
                ForEach(EyfsArea.allCases) { area in
                    Text(area.rawValue).tag(area)
                }
            }
            .pickerStyle(.menu)
            TextField("Milestone description *", text: $milestoneText, axis: .vertical)
                .lineLimit(3...8)
                .padding(12)
                .background(Color.ncCardSurface)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(Color.secondary.opacity(0.18), lineWidth: 1)
                }
            TextField("Next steps", text: $milestoneNextSteps, axis: .vertical)
                .lineLimit(2...6)
                .padding(12)
                .background(Color.ncCardSurface)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(Color.secondary.opacity(0.18), lineWidth: 1)
                }
            TextField("Evidence note", text: $milestoneEvidence, axis: .vertical)
                .lineLimit(2...6)
                .padding(12)
                .background(Color.ncCardSurface)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(Color.secondary.opacity(0.18), lineWidth: 1)
                }
        }
    }

    private var mealConsumptionPicker: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Amount eaten")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(MealConsumptionLevel.allCases) { level in
                        let on = mealConsumption == level
                        Button {
                            withAnimation(.spring(response: 0.32, dampingFraction: 0.78)) {
                                mealConsumption = level
                            }
                        } label: {
                            Text(level.title)
                                .font(.caption.weight(.semibold))
                                .padding(.horizontal, 12)
                                .padding(.vertical, 9)
                                .background {
                                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                                        .fill(consumptionColor(for: level).opacity(on ? 0.42 : 0.14))
                                }
                                .overlay {
                                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                                        .stroke(
                                            on ? consumptionColor(for: level).opacity(0.85) : Color.clear,
                                            lineWidth: on ? 1.5 : 0
                                        )
                                }
                                .shadow(color: on ? consumptionColor(for: level).opacity(0.25) : .clear, radius: 6, x: 0, y: 3)
                                .foregroundStyle(Color.primary)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }

    private var allergiesTrimmed: String {
        childAllergies.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var mealAllergyWarning: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "exclamationmark.shield.fill")
                .font(.body.weight(.semibold))
                .foregroundStyle(Color.ncDanger)
                .accessibilityHidden(true)
            Text("Allergies on file — \(allergiesTrimmed)")
                .font(.subheadline.weight(.medium))
                .foregroundStyle(.primary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.ncDanger.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    private var moodPicker: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Mood")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
            HStack(spacing: 0) {
                ForEach(1...5, id: \.self) { value in
                    let on = moodRating == Int16(value)
                    Button {
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.72)) {
                            moodRating = Int16(value)
                        }
                    } label: {
                        Image(systemName: moodSymbol(for: value))
                            .font(.title3)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .foregroundStyle(on ? Color.ncPrimary : Color.secondary)
                            .background {
                                if on {
                                    Circle()
                                        .fill(Color.ncPrimary.opacity(0.12))
                                        .frame(width: 44, height: 44)
                                }
                            }
                            .scaleEffect(on ? 1.12 : 1.0)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(moodAccessibilityLabel(for: value))
                }
            }
            .padding(6)
            .background {
                Capsule(style: .continuous)
                    .fill(Color.ncCardSurface)
                    .shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 4)
            }
            .overlay {
                Capsule(style: .continuous)
                    .stroke(Color.secondary.opacity(0.12), lineWidth: 1)
            }
        }
    }

    private func chipTitle(for type: DiaryEntryType) -> String {
        switch type {
        case .activity: return "Activity"
        case .sleep: return "Sleep"
        case .meal: return "Meal"
        case .nappy: return "Nappy"
        case .wellbeing: return "Wellbeing"
        case .milestone: return "Milestone"
        }
    }

    private static func symbolName(for type: DiaryEntryType) -> String {
        switch type {
        case .activity: return "figure.run"
        case .sleep: return "moon.zzz.fill"
        case .meal: return "fork.knife"
        case .nappy: return "drop.fill"
        case .wellbeing: return "heart.text.square.fill"
        case .milestone: return "star.fill"
        }
    }

    /// - Description: 1 = lowest wellbeing (most distressed), 5 = highest wellbeing — left-to-right in the picker.
    private func moodSymbol(for value: Int) -> String {
        switch value {
        case 1: return "exclamationmark.triangle.fill"
        case 2: return "cloud.rain"
        case 3: return "face.dashed"
        case 4: return "face.smiling"
        case 5: return "face.smiling.fill"
        default: return "face.dashed"
        }
    }

    private func moodAccessibilityLabel(for value: Int) -> String {
        switch value {
        case 1: return "Mood 1 of 5, lowest wellbeing"
        case 5: return "Mood 5 of 5, highest wellbeing"
        default: return "Mood \(value) of 5"
        }
    }

    private func consumptionColor(for level: MealConsumptionLevel) -> Color {
        switch level {
        case .all: return .green
        case .most: return Color.green.opacity(0.8)
        case .half: return .yellow
        case .little: return Color.ncAccentWarm
        case .none: return .orange
        case .refused: return .red
        }
    }

    private func notesForType() -> String {
        switch selectedType {
        case .sleep:
            var parts: [String] = [notes]
            if sleepDisturbances {
                parts.append("Disturbances noted during sleep.")
            }
            return parts.joined(separator: "\n")
        case .nappy:
            var parts: [String] = [notes]
            if nappyConcern { parts.append("Concern flagged.") }
            if nappyCream { parts.append("Barrier cream applied.") }
            return parts.joined(separator: "\n")
        case .milestone:
            return """
            Milestone: \(milestoneText)
            Next steps: \(milestoneNextSteps)
            Evidence: \(milestoneEvidence)

            \(notes)
            """
        default:
            return notes
        }
    }

    /// - Description: Builds and persists a diary entry for the current form state.
    private func save() async {
        guard validation.isValid else {
            validationMessage = "Please complete: \(validation.missingFields.joined(separator: ", "))"
            showValidationAlert = true
            return
        }
        if isCorrectionMode, selectedCorrectionReason == .other, correctionReasonOtherText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            validationMessage = "Please add a reason for this correction."
            showValidationAlert = true
            return
        }
        let draft = buildDraftValues()
        switch mode {
        case .create:
            let ok = await viewModel.createEntry(from: draft)
            guard ok else { return }
            NCHaptics.impactLight()
        case .correction(let existingEntry):
            let ok = await viewModel.correctEntry(existingEntry, with: draft, reason: resolvedCorrectionReason())
            guard ok else { return }
            NCHaptics.impactLight()
        }
        withAnimation(.spring(response: 0.45, dampingFraction: 0.85)) {
            dismiss()
        }
    }

    private func buildDraftValues() -> DiaryEntryDraftValues {
        let duration: Int32 = selectedType == .sleep
            ? Int32(max(1, Int(sleepEnd.timeIntervalSince(sleepStart) / 60)))
            : Int32(durationMinutes)
        let mealActivityType = mealIsFluidOnly ? "Fluid Intake" : mealSlot.rawValue
        let mealConsumed = mealIsFluidOnly ? nil : mealConsumption.persistenceValue

        let resolvedActivityType: String = {
            switch selectedType {
            case .activity: return activityKind.rawValue
            case .meal: return mealActivityType
            case .milestone: return milestoneText
            default: return ""
            }
        }()
        let resolvedEyfsArea: String = {
            switch selectedType {
            case .activity: return eyfsArea.rawValue
            case .milestone: return milestoneEyfs.rawValue
            default: return ""
            }
        }()
        let resolvedNotes: String = {
            if selectedType == .wellbeing, notes.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                return "Mood level \(moodRating)/5 recorded."
            }
            return notesForType()
        }()

        return DiaryEntryDraftValues(
            timestamp: selectedType == .sleep ? sleepStart : logTimestamp,
            entryType: selectedType,
            notes: resolvedNotes,
            activityType: resolvedActivityType,
            eyfsArea: resolvedEyfsArea,
            duration: duration,
            mealDescription: selectedType == .meal && !mealIsFluidOnly ? mealDescription : "",
            mealConsumed: selectedType == .meal ? mealConsumed : nil,
            fluidIntake: selectedType == .meal ? Int32(fluidIntake) : 0,
            fluidType: selectedType == .meal ? fluidKind.rawValue : "",
            nappyType: selectedType == .nappy ? nappyKind.rawValue : "",
            moodRating: selectedType == .wellbeing ? moodRating : 0,
            sleepPosition: selectedType == .sleep ? sleepPosition.rawValue : ""
        )
    }

    private func resolvedCorrectionReason() -> String {
        if selectedCorrectionReason == .other {
            return correctionReasonOtherText.trimmingCharacters(in: .whitespacesAndNewlines)
        }
        return selectedCorrectionReason.rawValue
    }

}

#Preview {
    let ctx = PersistenceController.preview.container.viewContext
    let vm = DailyDiaryViewModel(childID: UUID(), context: ctx)
    return AddDiaryEntryView(childID: UUID(), viewModel: vm, plannedSessionContext: nil)
        .environment(\.managedObjectContext, ctx)
}
