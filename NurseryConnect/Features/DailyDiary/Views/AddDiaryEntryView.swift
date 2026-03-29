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
// -----------------------------------------------------------------

import Combine
import CoreData
import SwiftUI

/// - Description: Sheet form that creates a `DiaryEntry` for the selected child.
struct AddDiaryEntryView: View {
    let childID: UUID
    @ObservedObject var viewModel: DailyDiaryViewModel

    @Environment(\.managedObjectContext) private var context
    @Environment(\.dismiss) private var dismiss

    @State private var selectedType: DiaryEntryType = .activity
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

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    typeChips
                    SectionHeader(title: "Details", subtitle: "Required fields are highlighted if missing.")
                    typeSpecificFields
                    notesField
                    if showValidation && !validation.isValid {
                        validationBanner
                    }
                }
                .padding()
            }
            .background(Color.ncBackground.ignoresSafeArea())
            .navigationTitle("New entry")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { Task { await save() } }
                        .accessibilityIdentifier(AppConstants.AccessibilityID.saveDiaryEntry)
                }
            }
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

    private var typeChips: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(DiaryEntryType.allCases, id: \.self) { type in
                    Button {
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                            selectedType = type
                        }
                    } label: {
                        Text(chipTitle(for: type))
                            .font(.subheadline.weight(.semibold))
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(selectedType == type ? Color.ncPrimary.opacity(0.2) : Color.ncCardSurface)
                            .foregroundStyle(selectedType == type ? Color.ncPrimary : Color.primary)
                            .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)
                    .ncMinimumTouchTarget()
                }
            }
        }
    }

    @ViewBuilder
    private var typeSpecificFields: some View {
        switch selectedType {
        case .activity:
            Picker("Activity type", selection: $activityKind) {
                ForEach(DiaryActivityKind.allCases) { kind in
                    Text(kind.rawValue).tag(kind)
                }
            }
            Picker("EYFS area", selection: $eyfsArea) {
                ForEach(EyfsArea.allCases) { area in
                    Text(area.rawValue).tag(area)
                }
            }
            Stepper("Duration: \(durationMinutes) minutes", value: $durationMinutes, in: 5...180, step: 5)
        case .sleep:
            DatePicker("Start", selection: $sleepStart, displayedComponents: [.hourAndMinute])
            DatePicker("End", selection: $sleepEnd, displayedComponents: [.hourAndMinute])
            Picker("Sleep position", selection: $sleepPosition) {
                ForEach(SleepPosition.allCases) { pos in
                    Text(pos.rawValue).tag(pos)
                }
            }
            Toggle("Disturbances noted", isOn: $sleepDisturbances)
        case .meal:
            Picker("Meal", selection: $mealSlot) {
                ForEach(MealSlot.allCases) { slot in
                    Text(slot.rawValue).tag(slot)
                }
            }
            TextField("Food description", text: $mealDescription)
                .textFieldStyle(.roundedBorder)
            mealConsumptionPicker
            Stepper("Fluid intake: \(fluidIntake) ml", value: $fluidIntake, in: 0...1000, step: 25)
            Picker("Fluid type", selection: $fluidKind) {
                ForEach(FluidKind.allCases) { fluid in
                    Text(fluid.rawValue).tag(fluid)
                }
            }
        case .nappy:
            Picker("Nappy type", selection: $nappyKind) {
                ForEach(NappyObservationKind.allCases) { kind in
                    Text(kind.rawValue).tag(kind)
                }
            }
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
            TextField("Milestone description", text: $milestoneText, axis: .vertical)
                .textFieldStyle(.roundedBorder)
            TextField("Next steps", text: $milestoneNextSteps, axis: .vertical)
                .textFieldStyle(.roundedBorder)
            TextField("Evidence note", text: $milestoneEvidence, axis: .vertical)
                .textFieldStyle(.roundedBorder)
        }
    }

    private var mealConsumptionPicker: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Amount eaten")
                .font(.subheadline.weight(.semibold))
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(MealConsumptionLevel.allCases) { level in
                        Button {
                            mealConsumption = level
                        } label: {
                            Text(level.title)
                                .font(.footnote.weight(.semibold))
                                .padding(.horizontal, 10)
                                .padding(.vertical, 8)
                                .background(consumptionColor(for: level).opacity(mealConsumption == level ? 0.35 : 0.12))
                                .foregroundStyle(Color.primary)
                                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }

    private var moodPicker: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Mood")
                .font(.subheadline.weight(.semibold))
            HStack(spacing: 12) {
                ForEach(1...5, id: \.self) { value in
                    Button {
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
                            moodRating = Int16(value)
                        }
                    } label: {
                        Image(systemName: moodSymbol(for: value))
                            .font(.title2)
                            .foregroundStyle(moodRating == value ? Color.ncPrimary : Color.secondary)
                            .scaleEffect(moodRating == value ? 1.15 : 1.0)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Mood level \(value) out of five")
                }
            }
        }
    }

    private var notesField: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Notes")
                .font(.subheadline.weight(.semibold))
            TextEditor(text: $notes)
                .frame(minHeight: 120)
                .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.secondary.opacity(0.3)))
        }
    }

    private var validationBanner: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Please complete:")
                .font(.footnote.weight(.bold))
                .foregroundStyle(Color.ncDanger)
            ForEach(validation.missingFields, id: \.self) { field in
                Text("• \(field)")
                    .foregroundStyle(Color.ncDanger)
                    .font(.footnote)
            }
        }
        .padding()
        .background(Color.ncDanger.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
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

    private func moodSymbol(for value: Int) -> String {
        switch value {
        case 1: return "face.smiling.fill"
        case 2: return "face.smiling"
        case 3: return "face.dashed"
        case 4: return "cloud.rain"
        case 5: return "exclamationmark.triangle.fill"
        default: return "face.smiling"
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
        guard let child = fetchChild() else {
            viewModel.errorMessage = "Missing child record."
            return
        }
        let entry = DiaryEntry(context: context)
        entry.id = UUID()
        entry.timestamp = Date()
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
    return AddDiaryEntryView(childID: UUID(), viewModel: vm)
        .environment(\.managedObjectContext, ctx)
}
