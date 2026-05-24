//
//  DashboardQuickCheckInSheet.swift
//  NurseryConnect
//
//  Feature: Dashboard
//  Role: Keyworker
//  Created: 29 May 2026
//  Description: Sheet shown when a child card is tapped before check-in.
//

import CoreData
import SwiftUI

/// - Description: Sheet shown when a child card is tapped before check-in: captures drop-off name only; arrival time is `Date()` at save.
struct DashboardQuickCheckInSheet: View {
    let summary: KeyworkerChildSummary
    let context: NSManagedObjectContext
    let onSuccess: () -> Void
    let onCancel: () -> Void

    @StateObject private var attendanceViewModel: AttendanceViewModel
    private let manualDropOffOption = "Not listed (enter name)"
    @State private var selectedDropOff = ""
    @State private var manualDropOffName = ""

    init(summary: KeyworkerChildSummary, context: NSManagedObjectContext, onSuccess: @escaping () -> Void, onCancel: @escaping () -> Void) {
        self.summary = summary
        self.context = context
        self.onSuccess = onSuccess
        self.onCancel = onCancel
        _attendanceViewModel = StateObject(wrappedValue: AttendanceViewModel(childID: summary.id, context: context))
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    if attendanceViewModel.authorisedCollectorLines.isEmpty {
                        TextField("Full name", text: $manualDropOffName)
                            .textInputAutocapitalization(.words)
                    } else {
                        Picker("Dropped off by", selection: $selectedDropOff) {
                            ForEach(Array(attendanceViewModel.authorisedCollectorLines.enumerated()), id: \.offset) { _, line in
                                Text(line)
                                    .tag(line)
                            }
                            Text(manualDropOffOption)
                                .tag(manualDropOffOption)
                        }
                        if selectedDropOff == manualDropOffOption {
                            TextField("Full name", text: $manualDropOffName)
                                .textInputAutocapitalization(.words)
                        }
                    }
                } header: {
                    Text("Who dropped \(summary.fullName) off?")
                } footer: {
                    if attendanceViewModel.authorisedCollectorLines.isEmpty {
                        Text("No authorised collectors are listed yet. Enter the drop-off name. Arrival time is saved automatically as the current time.")
                    } else {
                        Text("Select an authorised collector from the list, or choose “Not listed” and enter a name. Arrival time is saved automatically as the current time.")
                    }
                }
            }
            .navigationTitle("Check in")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel", action: onCancel)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        Task {
                            await attendanceViewModel.checkIn(at: Date(), droppedOffBy: dropOffNameForSave)
                            if attendanceViewModel.errorMessage == nil {
                                onSuccess()
                            }
                        }
                    }
                    .fontWeight(.semibold)
                    .accessibilityIdentifier(AppConstants.AccessibilityID.dashboardQuickCheckInSave)
                }
            }
        }
        .presentationDragIndicator(.visible)
        .task {
            await attendanceViewModel.load()
            if let first = attendanceViewModel.authorisedCollectorLines.first {
                selectedDropOff = first
            } else {
                selectedDropOff = manualDropOffOption
            }
        }
        .alert("Check-in", isPresented: Binding(
            get: { attendanceViewModel.errorMessage != nil },
            set: { if !$0 { attendanceViewModel.errorMessage = nil } }
        )) {
            Button("OK", role: .cancel) { attendanceViewModel.errorMessage = nil }
        } message: {
            Text(attendanceViewModel.errorMessage ?? "")
        }
    }

    private var dropOffNameForSave: String {
        if attendanceViewModel.authorisedCollectorLines.isEmpty || selectedDropOff == manualDropOffOption {
            return manualDropOffName
        }
        return selectedDropOff
    }
}
