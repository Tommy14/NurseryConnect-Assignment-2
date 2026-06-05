//
//  SpatialIncidentsSheet.swift
//  NurseryConnect Spatial
//
//  Feature: Spatial
//  Role: Keyworker
//  Created: 2 June 2026
//  Description: Lightweight incident list for visionOS without the full iPad incident UI target.
//

import CoreData
import SwiftUI

/// - Description: Read-only today/week incident browser for the spatial workspace.
struct SpatialIncidentsSheet: View {
    @Environment(\.managedObjectContext) private var context
    @Environment(\.dismiss) private var dismiss

    private let nurseryWide: Bool

    @State private var incidents: [Incident] = []
    @State private var filter: SpatialIncidentFilter = .today
    @State private var loadError: String?

    init(nurseryWide: Bool = false) {
        self.nurseryWide = nurseryWide
    }

    var body: some View {
        NavigationStack {
            Group {
                if let loadError {
                    ContentUnavailableView("Could not load incidents", systemImage: "exclamationmark.triangle", description: Text(loadError))
                } else if filteredIncidents.isEmpty {
                    ContentUnavailableView("No incidents", systemImage: "checkmark.shield", description: Text(emptyDescriptionText))
                } else {
                    List(filteredIncidents, id: \.objectID) { incident in
                        SpatialIncidentListRow(incident: incident)
                    }
                    .listStyle(.plain)
                }
            }
            .navigationTitle("Incidents")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
            }
            .safeAreaInset(edge: .top, spacing: 0) {
                Picker("Filter", selection: $filter) {
                    ForEach(SpatialIncidentFilter.allCases) { option in
                        Text(option.title).tag(option)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)
                .padding(.bottom, 8)
            }
            .task(id: filter) {
                await loadIncidents()
            }
        }
    }

    private var filteredIncidents: [Incident] {
        incidents.filter { incident in
            guard let timestamp = incident.timestamp else { return false }
            return filter.includes(timestamp)
        }
    }

    private var emptyDescriptionText: String {
        let scope = nurseryWide ? "across the nursery" : "for your assigned children"
        switch filter {
        case .today:
            return "No incidents logged today \(scope)."
        case .week:
            return "No incidents this week \(scope)."
        case .all:
            return "No incidents on record \(scope)."
        }
    }

    @MainActor
    private func loadIncidents() async {
        do {
            let request: NSFetchRequest<Incident> = Incident.fetchRequest()
            if !nurseryWide {
                request.predicate = NSPredicate(format: "child.keyworkerName == %@", AppConstants.keyworkerDisplayName)
            }
            request.sortDescriptors = [NSSortDescriptor(keyPath: \Incident.timestamp, ascending: false)]
            request.relationshipKeyPathsForPrefetching = ["child"]
            incidents = try context.fetch(request)
            loadError = nil
        } catch {
            incidents = []
            loadError = "Please try again."
        }
    }
}

private enum SpatialIncidentFilter: String, CaseIterable, Identifiable {
    case today
    case week
    case all

    var id: String { rawValue }

    var title: String {
        switch self {
        case .today: return "Today"
        case .week: return "Week"
        case .all: return "All"
        }
    }

    func includes(_ date: Date) -> Bool {
        switch self {
        case .today:
            return date.isSameDay(as: Date())
        case .week:
            let calendar = Calendar.current
            guard let interval = calendar.dateInterval(of: .weekOfYear, for: Date()) else { return true }
            return date >= interval.start && date < interval.end
        case .all:
            return true
        }
    }
}

