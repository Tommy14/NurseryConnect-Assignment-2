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
    let childID: UUID
    @ObservedObject var viewModel: DailyDiaryViewModel
    /// - Description: When set, pre-fills type, meal slot, and default log time from a planned session row.
    var plannedSessionContext: PlannedSessionLogContext?
    /// - Description: When false, save is blocked (e.g. before check-in or after check-out). Re-evaluated on each save attempt.
    private let isDiaryLoggingPermitted: () -> Bool

    @Environment(\.managedObjectContext) private var context
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
    @State private var showValidation: Bool = false
    @State private var didApplyPlannedPrefill = false

    init(
        childID: UUID,
        viewModel: DailyDiaryViewModel,
        plannedSessionContext: PlannedSessionLogContext? = nil,
        isDiaryLoggingPermitted: @escaping () -> Bool = { true }
    ) {
        self.childID = childID
        self.viewModel = viewModel
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
                    if showValidation && !validation.isValid {
                        validationCallout
                    }
                }
                .padding()
            }
            .scrollIndicators(.hidden)
            .background { diaryFormAtmosphereBackground }
            .navigationTitle("New entry")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(role: .cancel) { dismiss() } label: {
                        Image(systemName: "xmark")
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { Task { await save() } }
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
        VStack(alignment: .leading, spacing: 10) {
            Label(notesLabelText, systemImage: "note.text")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Color.primary)
            TextEditor(text: $notes)
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
                    if notes.isEmpty {
                        Text("Add observations, context, or follow-up…")
                            .font(.body)
                            .foregroundStyle(.tertiary)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 20)
                            .allowsHitTesting(false)
                    }
                }
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .ncCardStyle(radius: 20)
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
            milestoneDescription: milestoneText
        )
    }

    @ViewBuilder
    private var typeSpecificFields: some View {
        switch selectedType {
        case .activity:
            Picker("Activity type *", selection: $activityKind) {
                ForEach(DiaryActivityKind.allCases) { kind in
                    Text(kind.rawValue).tag(kind)
                }
            }
            .pickerStyle(.menu)
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
            Picker("Sleep position", selection: $sleepPosition) {
                ForEach(SleepPosition.allCases) { pos in
                    Text(pos.rawValue).tag(pos)
                }
            }
            .pickerStyle(.menu)
            Toggle("Disturbances noted", isOn: $sleepDisturbances)
        case .meal:
            Picker("Meal", selection: $mealSlot) {
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
            Stepper("Fluid intake: \(fluidIntake) ml", value: $fluidIntake, in: 0...1000, step: 25)
            Picker("Fluid type", selection: $fluidKind) {
                ForEach(FluidKind.allCases) { fluid in
                    Text(fluid.rawValue).tag(fluid)
                }
            }
            .pickerStyle(.menu)
        case .nappy:
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
        showValidation = true
        guard validation.isValid else { return }
        guard isDiaryLoggingPermitted() else {
            viewModel.errorMessage = """
            Logging isn’t available. The child must be checked in on site, and the current time must be within nursery diary hours (from session start until two hours after closing).
            """
            return
        }
        guard let child = fetchChild() else {
            viewModel.errorMessage = "Missing child record."
            return
        }
        let entry = DiaryEntry(context: context)
        let eventTime = selectedType == .sleep ? sleepStart : logTimestamp
        entry.id = UUID()
        entry.timestamp = eventTime
        entry.submittedAt = Date()
        entry.entryType = selectedType.persistenceValue
        entry.notes = notesForType()
        entry.child = child
        entry.isSubmittedToManager = false
        switch selectedType {
        case .activity:
            entry.activityType = activityKind.rawValue
            entry.eyfsArea = eyfsArea.rawValue
            entry.duration = Int32(durationMinutes)
        case .sleep:
            entry.timestamp = sleepStart
            let minutes = max(1, Int(sleepEnd.timeIntervalSince(sleepStart) / 60))
            entry.duration = Int32(minutes)
            entry.sleepPosition = sleepPosition.rawValue
        case .meal:
            entry.activityType = mealSlot.rawValue
            entry.mealDescription = mealDescription
            entry.mealConsumed = mealConsumption.persistenceValue
            entry.fluidIntake = Int32(fluidIntake)
            entry.fluidType = fluidKind.rawValue
        case .nappy:
            entry.nappyType = nappyKind.rawValue
        case .wellbeing:
            entry.moodRating = moodRating
            if notes.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                entry.notes = "Mood level \(moodRating)/5 recorded."
            }
        case .milestone:
            entry.activityType = milestoneText
            entry.eyfsArea = milestoneEyfs.rawValue
        }
        NCHaptics.impactLight()
        await viewModel.saveNewEntry(entry)
        withAnimation(.spring(response: 0.45, dampingFraction: 0.85)) {
            dismiss()
        }
    }

    /// - Description: Fetches the `Child` entity backing this form.
    /// - Returns: Matching child or `nil` when not found.
    private func fetchChild() -> Child? {
        let request: NSFetchRequest<Child> = Child.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", childID as CVarArg)
        request.fetchLimit = 1
        return try? context.fetch(request).first
    }
}

#Preview {
    let ctx = PersistenceController.preview.container.viewContext
    let vm = DailyDiaryViewModel(childID: UUID(), context: ctx)
    return AddDiaryEntryView(childID: UUID(), viewModel: vm, plannedSessionContext: nil)
        .environment(\.managedObjectContext, ctx)
}
