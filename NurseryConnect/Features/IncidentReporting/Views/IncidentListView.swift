//
//  IncidentListView.swift
//  NurseryConnect
//
//  Feature: Incident Reporting
//  Role: Keyworker
//  Created: 8 April 2026
//  Description: Filterable incident inbox with safeguarding banner and creation entry point.
//
// -----------------------------------------------------------------
// Date       Name        What has done
// -----------------------------------------------------------------
// 080426     Tommy1914   Created the file with segmented control, list rows, and FAB.
// -----------------------------------------------------------------

import Combine
import CoreData
import SwiftUI

/// - Description: Lists incidents for the keyworker with quick filters and navigation to detail.
struct IncidentListView: View {
    @Environment(\.managedObjectContext) private var context
    @StateObject private var viewModel: IncidentViewModel
    @State private var showComposer = false
    @State private var timerToken = Timer.publish(every: 60, on: .main, in: .common).autoconnect()

    init(managedObjectContext: NSManagedObjectContext) {
        _viewModel = StateObject(wrappedValue: IncidentViewModel(context: managedObjectContext))
    }

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            List {
                if !viewModel.parentNotificationBanners.isEmpty {
                    Section {
                        ForEach(viewModel.parentNotificationBanners) { banner in
                            Text("⚠️ Action required: Parent not yet notified of \(banner.childFirstName)’s incident.")
                                .font(.footnote.weight(.semibold))
                                .foregroundStyle(Color.white)
                                .padding()
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(Color.ncDanger)
                                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                        }
                    }
                    .listRowBackground(Color.clear)
                }

                Section {
                    Picker("Filter", selection: $viewModel.filter) {
                        ForEach(IncidentListFilter.allCases) { filter in
                            Text(filter.title).tag(filter)
                        }
                    }
                    .pickerStyle(.segmented)
                }
                .listRowBackground(Color.clear)

                if viewModel.incidents.isEmpty {
                    Section {
                        EmptyStateView(
                            symbolName: "shield.lefthalf.filled",
                            title: "No incidents",
                            message: "You have no incidents for this filter."
                        )
                    }
                    .listRowBackground(Color.clear)
                } else {
                    Section {
                        ForEach(viewModel.incidents, id: \.objectID) { incident in
                            NavigationLink {
                                IncidentDetailView(incident: incident, viewModel: viewModel)
                            } label: {
                                IncidentRowView(incident: incident)
                            }
                        }
                    }
                }
            }
            .listStyle(.insetGrouped)

            Button {
                showComposer = true
            } label: {
                Image(systemName: "plus")
                    .font(.title2.weight(.semibold))
                    .foregroundStyle(Color.white)
                    .frame(width: 56, height: 56)
                    .background(Color.ncPrimary)
                    .clipShape(RoundedRectangle(cornerRadius: AppConstants.fabCornerRadius, style: .continuous))
                    .shadow(color: Color.black.opacity(0.15), radius: 8, x: 0, y: 4)
            }
            .padding()
            .accessibilityIdentifier(AppConstants.AccessibilityID.addIncidentFAB)
            .accessibilityLabel("New incident")
        }
        .navigationTitle("Incidents")
        .sheet(isPresented: $showComposer) {
            NewIncidentFormView(viewModel: viewModel)
                .environment(\.managedObjectContext, context)
        }
        .task {
            await viewModel.refresh()
        }
        .onChange(of: viewModel.filter) { _, _ in
            Task { await viewModel.refresh() }
        }
        .onReceive(timerToken) { _ in
            Task { await viewModel.refresh() }
        }
        .alert("Something went wrong", isPresented: Binding(
            get: { viewModel.errorMessage != nil },
            set: { if !$0 { viewModel.errorMessage = nil } }
        )) {
            Button("OK", role: .cancel) { viewModel.errorMessage = nil }
        } message: {
            Text(viewModel.errorMessage ?? "")
        }
    }

}

#Preview {
    let ctx = PersistenceController.preview.container.viewContext
    return NavigationStack {
        IncidentListView(managedObjectContext: ctx)
    }
    .environment(\.managedObjectContext, ctx)
}
