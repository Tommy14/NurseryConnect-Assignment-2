//
//  SpatialTodaySnapshotView.swift
//  NurseryConnect Spatial
//
//  Feature: Spatial
//  Role: Keyworker
//  Created: 2 June 2026
//  Description: At-a-glance attendance, diary, and incident metrics for the spatial dashboard.
//

import SwiftUI

/// - Description: One metric tile in the spatial “today” snapshot rail.
struct SpatialSnapshotStat: Identifiable {
    let id: String
    let title: String
    let value: String
    let systemImage: String
    let tint: Color
}

/// - Description: Horizontal row of glass stat cards for today’s nursery overview.
struct SpatialTodaySnapshotView: View {
    let stats: [SpatialSnapshotStat]

    var body: some View {
        HStack(spacing: 12) {
            ForEach(stats) { stat in
                VStack(alignment: .leading, spacing: 10) {
                    Image(systemName: stat.systemImage)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(stat.tint)
                        .frame(width: 32, height: 32)
                        .background(stat.tint.opacity(0.15), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
                    Text(stat.value)
                        .font(.title2.weight(.bold).monospacedDigit())
                    Text(stat.title)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(14)
                .glassBackgroundEffect(in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            }
        }
        .accessibilityElement(children: .contain)
    }
}
