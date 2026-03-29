//
//  IncidentRowView.swift
//  NurseryConnect
//
//  Feature: Incident Reporting
//  Role: Keyworker
//  Created: 7 April 2026
//  Description: Row layout for incident lists with category icon and status badge.
//
// -----------------------------------------------------------------
// Date       Name        What has done
// -----------------------------------------------------------------
// 070426     Tommy1914   Created the file with compact metadata and accessibility IDs.
// -----------------------------------------------------------------

import Combine
import CoreData
import SwiftUI

/// - Description: One incident row with leading iconography and status capsule.
struct IncidentRowView: View {
    @ObservedObject var incident: Incident

    private var category: IncidentCategory {
        IncidentCategory.fromPersistence(incident.category ?? "")
    }

    private var status: IncidentStatus {
        IncidentStatus.fromPersistence(incident.status ?? "")
    }

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: category.symbolName)
                .font(.title3)
                .foregroundStyle(Color.ncPrimary)
                .frame(width: 32, height: 32)
            VStack(alignment: .leading, spacing: 6) {
                Text(childName)
                    .font(.headline)
                Text(category.title)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                IncidentStatusBadge(status: status)
            }
            Spacer()
            if let timestamp = incident.timestamp {
                Text(timestamp.formattedTime())
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 6)
        .accessibilityElement(children: .combine)
        .accessibilityIdentifier("\(AppConstants.AccessibilityID.incidentRowPrefix)\(incident.id?.uuidString ?? "unknown")")
    }

    private var childName: String {
        let first = incident.child?.firstName ?? ""
        let last = incident.child?.lastName ?? ""
        let combined = "\(first) \(last)".trimmingCharacters(in: .whitespaces)
        return combined.isEmpty ? "Child" : combined
    }
}
