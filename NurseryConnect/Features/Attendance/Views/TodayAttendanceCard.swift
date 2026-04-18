//
//  TodayAttendanceCard.swift
//  NurseryConnect
//
//  Feature: Attendance
//  Role: Keyworker
//  Created: 16 April 2026
//  Description: Today’s attendance status, check-in and check-out actions.
//

import CoreData
import SwiftUI

/// - Description: Header card for check-in / check-out on the daily diary screen.
struct TodayAttendanceCard: View {
    let firstName: String
    @ObservedObject var viewModel: AttendanceViewModel

    @State private var activeSheet: Sheet?

    private enum Sheet: Identifiable {
        case checkIn
        case checkOut

        var id: String {
            switch self {
            case .checkIn: return "checkIn"
            case .checkOut: return "checkOut"
            }
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 8) {
                Image(systemName: "figure.walk.arrival")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Color.ncPrimary)
                Text("Today’s attendance")
                    .font(.caption.weight(.bold))
                    .tracking(0.6)
                    .foregroundStyle(.secondary)
                Spacer(minLength: 0)
            }

            statusBlock

            actionButtons
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .ncStudioElevatedSurface(cornerRadius: 16)
        .sheet(item: $activeSheet) { sheet in
            switch sheet {
            case .checkIn:
                CheckInAttendanceSheet(firstName: firstName, viewModel: viewModel) { activeSheet = nil }
            case .checkOut:
                CheckOutAttendanceSheet(firstName: firstName, viewModel: viewModel) { activeSheet = nil }
            }
        }
    }

    private var statusBlock: some View {
        VStack(alignment: .leading, spacing: 8) {
            switch viewModel.phase {
            case .expected:
                Label("Expected — not checked in yet", systemImage: "clock.badge.questionmark")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.secondary)
            case .absent:
                Label("Absent today", systemImage: "moon.zzz.fill")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Color.ncDanger)
                Text("Not expected on site. Clear this when the family attends.")
                    .font(.caption.weight(.medium))
                    .foregroundStyle(.tertiary)
            case .onPremises:
                Label("On premises", systemImage: "checkmark.circle.fill")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Color.ncSecondary)
                if let t = viewModel.checkInAt {
                    detailLine(title: "Arrived", value: t.formatted(date: .abbreviated, time: .shortened))
                }
                if viewModel.droppedOffBy.isEmpty == false {
                    detailLine(title: "Dropped off by", value: viewModel.droppedOffBy)
                }
            case .departed:
                Label("Departed", systemImage: "figure.walk.departure")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.secondary)
                if let t = viewModel.checkInAt {
                    detailLine(title: "Arrived", value: t.formatted(date: .abbreviated, time: .shortened))
                }
                if viewModel.droppedOffBy.isEmpty == false {
                    detailLine(title: "Dropped off by", value: viewModel.droppedOffBy)
                }
                if let t = viewModel.checkOutAt {
                    detailLine(title: "Left", value: t.formatted(date: .abbreviated, time: .shortened))
                }
                if let c = viewModel.collectedBy, c.isEmpty == false {
                    detailLine(title: "Collected by", value: c)
                }
            }
        }
    }

    private func detailLine(title: String, value: String) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 8) {
            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.tertiary)
            Text(value)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(.primary)
        }
    }

    private var actionButtons: some View {
        Group {
            switch viewModel.phase {
            case .expected:
                VStack(spacing: 10) {
                    Button {
                        activeSheet = .checkIn
                    } label: {
                        Label("Check in", systemImage: "arrow.down.circle.fill")
                            .font(.subheadline.weight(.semibold))
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(Color.ncPrimary)
                    Button {
                        Task { await viewModel.markAbsentToday() }
                    } label: {
                        Label("Absent today", systemImage: "moon.zzz.fill")
                            .font(.subheadline.weight(.semibold))
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                    .tint(Color.ncDanger)
                }
            case .absent:
                Button {
                    Task { await viewModel.clearMarkedAbsent() }
                } label: {
                    Label("Mark as attending", systemImage: "figure.walk.arrival")
                        .font(.subheadline.weight(.semibold))
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .tint(Color.ncPrimary)
            case .onPremises:
                Button {
                    activeSheet = .checkOut
                } label: {
                    Label("Check out", systemImage: "arrow.up.circle.fill")
                        .font(.subheadline.weight(.semibold))
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .tint(Color.ncPrimary)
                .disabled(viewModel.authorisedCollectorLines.isEmpty)
            case .departed:
                Text("Attendance is complete for today.")
                    .font(.caption.weight(.medium))
                    .foregroundStyle(.tertiary)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .accessibilityElement(children: .contain)
    }
}

// MARK: - Sheets

private struct CheckInAttendanceSheet: View {
    let firstName: String
    @ObservedObject var viewModel: AttendanceViewModel
    var onDismiss: () -> Void

    @State private var droppedOffBy = ""
    @State private var arrivalTime = Date()

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Full name", text: $droppedOffBy, axis: .vertical)
                        .textInputAutocapitalization(.words)
                } header: {
                    Text("Who dropped \(firstName) off?")
                }

                Section {
                    DatePicker("Arrival time", selection: $arrivalTime, displayedComponents: [.date, .hourAndMinute])
                }
            }
            .navigationTitle("Check in")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { onDismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        Task {
                            await viewModel.checkIn(at: arrivalTime, droppedOffBy: droppedOffBy)
                            if viewModel.errorMessage == nil {
                                onDismiss()
                            }
                        }
                    }
                    .fontWeight(.semibold)
                }
            }
        }
        .presentationDragIndicator(.visible)
    }
}

private struct CheckOutAttendanceSheet: View {
    let firstName: String
    @ObservedObject var viewModel: AttendanceViewModel
    var onDismiss: () -> Void

    @State private var selectedCollector = ""
    @State private var outTime = Date()
    @State private var unauthorisedNotes = ""
    @State private var showUnauthorisedConfirm = false

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.authorisedCollectorLines.isEmpty {
                    Form {
                        Section {
                            ContentUnavailableView(
                                "No authorised collectors",
                                systemImage: "person.crop.circle.badge.xmark",
                                description: Text("Add authorised collectors on the child’s profile to complete a normal check-out, or report an unauthorised collection attempt below.")
                            )
                            .listRowInsets(EdgeInsets())
                            .padding(.vertical, 8)
                        }
                        unauthorisedCollectionSection
                    }
                } else {
                    Form {
                        Section {
                            Picker("Collected by", selection: $selectedCollector) {
                                ForEach(Array(viewModel.authorisedCollectorLines.enumerated()), id: \.offset) { _, line in
                                    Text(line)
                                        .tag(line)
                                }
                            }
                        } footer: {
                            Text("Only people listed as authorised collectors can collect \(firstName).")
                        }

                        Section {
                            DatePicker("Collection time", selection: $outTime, displayedComponents: [.date, .hourAndMinute])
                        }

                        unauthorisedCollectionSection
                    }
                }
            }
            .navigationTitle("Check out")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { onDismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        Task {
                            await viewModel.checkOut(at: outTime, collectedBy: selectedCollector)
                            if viewModel.errorMessage == nil {
                                onDismiss()
                            }
                        }
                    }
                    .fontWeight(.semibold)
                    .disabled(viewModel.authorisedCollectorLines.isEmpty)
                }
            }
        }
        .presentationDragIndicator(.visible)
        .alert("Submit safeguarding report?", isPresented: $showUnauthorisedConfirm) {
            Button("Cancel", role: .cancel) {}
            Button("Submit report") {
                Task {
                    let ok = await viewModel.reportUnauthorisedCollectionAttempt(additionalNotes: unauthorisedNotes)
                    if ok {
                        NCHaptics.success()
                        onDismiss()
                    }
                }
            }
        } message: {
            Text("This notifies leadership that someone not on the authorised list came to collect \(firstName). The check-out form will close; do not complete check-out until collection is verified.")
        }
        .onAppear {
            if selectedCollector.isEmpty, let first = viewModel.authorisedCollectorLines.first {
                selectedCollector = first
            }
        }
    }

    private var unauthorisedCollectionSection: some View {
        Section {
            TextField("Optional details (name given, what happened…)", text: $unauthorisedNotes, axis: .vertical)
                .lineLimit(3 ... 6)
            Button {
                showUnauthorisedConfirm = true
            } label: {
                Label("Someone not authorised came to collect", systemImage: "hand.raised.fill")
                    .font(.subheadline.weight(.semibold))
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .tint(Color.ncAccentWarm)
            .accessibilityIdentifier(AppConstants.AccessibilityID.reportUnauthorisedCollection)
        } header: {
            Text("Safeguarding")
        } footer: {
            Text("Use this if an unlisted person requests pick-up. It does not check \(firstName) out.")
        }
    }
}

#Preview {
    let ctx = PersistenceController.preview.container.viewContext
    let vm = AttendanceViewModel(childID: UUID(), context: ctx)
    return TodayAttendanceCard(firstName: "Emma", viewModel: vm)
        .environment(\.managedObjectContext, ctx)
        .padding()
        .background(Color.ncBackground)
}
