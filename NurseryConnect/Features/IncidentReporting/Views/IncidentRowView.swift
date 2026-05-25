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
// 100426     Tommy1914   Gradient icon well; trailing chevron for tappability (scroll layout has no list disclosure).
// 100426     Tommy1914   Deeper icon well, rounded headline, monospaced time for readout feel.
// 100426     Tommy1914   Category-driven icon palette for stronger visual separation in incident inbox rows.
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

    private var syncState: SyncState {
        SyncState.fromPersistence(incident.syncState)
    }

    private var accentColor: Color {
        switch category {
        case .accidentMinor: return Color.ncAccentWarm
        case .accidentFirstAid: return Color.ncPrimary
        case .safeguardingConcern: return Color.ncDanger
        case .nearMiss: return Color.orange
        case .allergicReaction: return Color.purple
        case .medicalIncident: return Color.teal
        case .seriousIncident: return Color.ncDanger
        }
    }

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [accentColor.opacity(0.34), accentColor.opacity(0.14)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 44, height: 44)
                    .shadow(color: accentColor.opacity(0.2), radius: 6, x: 0, y: 3)
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .strokeBorder(Color.ncGlassHighlight(lightOpacity: 0.35), lineWidth: 0.7)
                    .frame(width: 44, height: 44)
                Image(systemName: category.symbolName)
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(accentColor)
                    .symbolRenderingMode(.hierarchical)
            }
            VStack(alignment: .leading, spacing: 6) {
                Text(childName)
                    .font(.system(.headline, design: .default).weight(.semibold))
                Text(category.title)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.secondary)
                SyncStateBadgeView(state: syncState)
            }
            Spacer(minLength: 8)
            VStack(alignment: .trailing, spacing: 8) {
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
                IncidentStatusBadge(status: status)
            }
        }
        .padding(.vertical, 6)
        .accessibilityElement(children: .combine)
        .accessibilityIdentifier("\(AppConstants.AccessibilityID.incidentRowPrefix)\(incident.id?.uuidString ?? "unknown")")
    }

    private var childName: String {
        guard let child = incident.child else { return "Child" }
        return child.fullDisplayName
    }
}
