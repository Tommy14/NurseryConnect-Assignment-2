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
// 120426     Tommy1914   Gradient icon well; trailing chevron for tappability (scroll layout has no list disclosure).
// 130426     Tommy1914   Deeper icon well, rounded headline, monospaced time for readout feel.
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
            ZStack {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [Color.ncPrimary.opacity(0.32), Color.cyan.opacity(0.16)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 44, height: 44)
                    .shadow(color: Color.ncPrimary.opacity(0.22), radius: 6, x: 0, y: 3)
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .strokeBorder(Color.white.opacity(0.35), lineWidth: 0.5)
                    .frame(width: 44, height: 44)
                Image(systemName: category.symbolName)
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(Color.ncPrimary)
                    .symbolRenderingMode(.hierarchical)
            }
            VStack(alignment: .leading, spacing: 6) {
                Text(childName)
                    .font(.system(.headline, design: .rounded).weight(.semibold))
                Text(category.title)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.secondary)
                IncidentStatusBadge(status: status)
            }
            Spacer(minLength: 8)
            HStack(alignment: .center, spacing: 6) {
                if let timestamp = incident.timestamp {
                    Text(timestamp.formattedTime())
                        .font(.caption.weight(.semibold).monospacedDigit())
                        .foregroundStyle(.secondary)
                }
                Image(systemName: "chevron.right")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(.tertiary)
                    .accessibilityHidden(true)
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
