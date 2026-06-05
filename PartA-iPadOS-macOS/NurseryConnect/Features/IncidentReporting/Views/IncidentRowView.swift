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

    private var accentColor: Color {
        switch category {
        case .accidentMinor: return Color(red: 0.64, green: 0.45, blue: 0.23)
        case .accidentFirstAid: return Color.ncPrimary
        case .safeguardingConcern: return Color.ncDanger
        case .nearMiss: return Color(red: 0.53, green: 0.49, blue: 0.26)
        case .allergicReaction: return Color.purple
        case .medicalIncident: return Color.teal
        case .seriousIncident: return Color.ncDanger
        }
    }

    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(accentColor.opacity(0.16))
                    .frame(width: 46, height: 46)
                Image(systemName: category.symbolName)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(accentColor)
                    .symbolRenderingMode(.hierarchical)
            }
            VStack(alignment: .leading, spacing: 4) {
                Text(category.title)
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                Text(subtitleText)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
            Spacer(minLength: 8)
            VStack(alignment: .trailing, spacing: 8) {
                IncidentStatusBadge(status: status)
                Text(timestampText)
                    .font(.caption.weight(.medium).monospacedDigit())
                    .foregroundStyle(.secondary)
            }
            Image(systemName: "chevron.right")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.tertiary)
                .accessibilityHidden(true)
                .padding(.leading, 2)
                .padding(.top, 2)
        }
        .padding(.vertical, 2)
        .accessibilityElement(children: .combine)
        .accessibilityIdentifier("\(AppConstants.AccessibilityID.incidentRowPrefix)\(incident.id?.uuidString ?? "unknown")")
    }

    private var subtitleText: String {
        let roomName = incident.child?.roomName?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let location = incident.location?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""

        let locationOrRoom = location.isEmpty ? roomName : "\(roomName)\(roomName.isEmpty ? "" : " — ")\(location)"
        if locationOrRoom.isEmpty {
            return childName
        }
        return "\(childName) · \(locationOrRoom)"
    }

    private var timestampText: String {
        if let timestamp = incident.timestamp {
            return timestamp.formattedTime()
        }
        return "--:--"
    }

    private var childName: String {
        guard let child = incident.child else { return "Child" }
        return child.fullDisplayName
    }
}
