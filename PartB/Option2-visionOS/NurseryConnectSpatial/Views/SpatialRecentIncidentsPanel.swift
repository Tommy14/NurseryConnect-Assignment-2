//
//  SpatialRecentIncidentsPanel.swift
//  NurseryConnect Spatial
//
//  Feature: Spatial
//  Created: 4 June 2026
//  Description: Today’s incident rail for keyworker and Setting Manager spatial dashboards.
//

import CoreData
import SwiftUI

/// - Description: Inline list of today’s incidents with a shortcut to the full incidents sheet.
struct SpatialRecentIncidentsPanel: View {
    @Environment(\.managedObjectContext) private var context

    let nurseryWide: Bool
    let onSeeAll: () -> Void

    @State private var incidents: [Incident] = []
    @State private var loadError: String?

    private var openCount: Int {
        incidents.filter {
            IncidentStatus.fromPersistence($0.status ?? "") != .acknowledged
        }.count
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label("Today’s incidents", systemImage: "exclamationmark.shield.fill")
                    .font(.headline)
                Spacer()
                if openCount > 0 {
                    Text("\(openCount) open")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(Color.ncDanger, in: Capsule())
                }
                Button("See all", action: onSeeAll)
                    .font(.caption.weight(.semibold))
            }

            if let loadError {
                Text(loadError)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            } else if incidents.isEmpty {
                VStack(spacing: 0) {
                    Spacer(minLength: 0)
                    ContentUnavailableView {
                        Label("No incidents today", systemImage: "checkmark.shield")
                    } description: {
                        Text(emptyDescription)
                    }
                    .multilineTextAlignment(.center)
                    Spacer(minLength: 0)
                }
                .frame(maxWidth: .infinity, minHeight: 140)
            } else {
                VStack(spacing: 8) {
                    ForEach(incidents, id: \.objectID) { incident in
                        SpatialIncidentListRow(incident: incident)
                            .padding(12)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                    }
                }
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity, minHeight: 220, alignment: .top)
        .glassBackgroundEffect(in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        .task(id: nurseryWide) {
            await loadIncidents()
        }
        .onReceive(NotificationCenter.default.publisher(for: .NSManagedObjectContextObjectsDidChange, object: context)) { _ in
            Task { await loadIncidents() }
        }
    }

    private var emptyDescription: String {
        nurseryWide
            ? "No incidents logged today across the nursery."
            : "No incidents logged today for your assigned children."
    }

    @MainActor
    private func loadIncidents() async {
        context.processPendingChanges()
        do {
            let request: NSFetchRequest<Incident> = Incident.fetchRequest()
            let start = Date().startOfDay
            let end = Date().endOfDay
            var predicates: [NSPredicate] = [
                NSPredicate(format: "timestamp >= %@ AND timestamp < %@", start as NSDate, end as NSDate)
            ]
            if !nurseryWide {
                predicates.append(NSPredicate(format: "child.keyworkerName == %@", AppConstants.keyworkerDisplayName))
            }
            request.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: predicates)
            request.sortDescriptors = [NSSortDescriptor(keyPath: \Incident.timestamp, ascending: false)]
            request.fetchLimit = 4
            request.relationshipKeyPathsForPrefetching = ["child"]
            incidents = try context.fetch(request)
            loadError = nil
        } catch {
            incidents = []
            loadError = "Could not load incidents."
        }
    }
}

/// - Description: Shared compact row for spatial incident lists and sheets.
struct SpatialIncidentListRow: View {
    @ObservedObject var incident: Incident

    private var categoryTitle: String {
        SpatialIncidentDisplay.categoryTitle(for: incident.category ?? "")
    }

    private var categorySymbol: String {
        SpatialIncidentDisplay.categorySymbol(for: incident.category ?? "")
    }

    private var statusTitle: String {
        let status = IncidentStatus.fromPersistence(incident.status ?? "")
        switch status {
        case .submitted, .managerReviewed:
            return "Awaiting review"
        default:
            return status.title
        }
    }

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: categorySymbol)
                .font(.title3)
                .foregroundStyle(Color.ncPrimary)
                .frame(width: 40, height: 40)
                .background(Color.ncPrimary.opacity(0.12), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
            VStack(alignment: .leading, spacing: 4) {
                Text(categoryTitle)
                    .font(.subheadline.weight(.semibold))
                Text(incident.child?.fullDisplayName ?? "Child")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer(minLength: 8)
            VStack(alignment: .trailing, spacing: 4) {
                Text(statusTitle)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Color.ncAccentWarm)
                if let timestamp = incident.timestamp {
                    Text(timestamp, style: .time)
                        .font(.caption.monospacedDigit())
                        .foregroundStyle(.tertiary)
                }
            }
        }
    }
}

/// - Description: Category labels and symbols for spatial incident UI.
enum SpatialIncidentDisplay {
    static func categoryTitle(for persistence: String) -> String {
        switch persistence {
        case "accidentMinor": return "Accident (Minor)"
        case "accidentFirstAid": return "Accident (First Aid)"
        case "safeguardingConcern": return "Safeguarding Concern"
        case "nearMiss": return "Near Miss"
        case "allergicReaction": return "Allergic Reaction"
        case "medicalIncident": return "Medical Incident"
        case "seriousIncident": return "Serious Incident"
        default: return "Incident"
        }
    }

    static func categorySymbol(for persistence: String) -> String {
        switch persistence {
        case "accidentMinor": return "bandage.fill"
        case "accidentFirstAid": return "cross.case.fill"
        case "safeguardingConcern": return "hand.raised.fill"
        case "nearMiss": return "exclamationmark.triangle.fill"
        case "allergicReaction": return "allergens.fill"
        case "medicalIncident": return "heart.text.square.fill"
        case "seriousIncident": return "exclamationmark.octagon.fill"
        default: return "doc.text.fill"
        }
    }
}
