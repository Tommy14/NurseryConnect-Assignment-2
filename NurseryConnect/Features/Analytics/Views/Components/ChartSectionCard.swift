//
//  ChartSectionCard.swift
//  NurseryConnect
//
//  Feature: Analytics
//  Role: Keyworker
//  Created: 29 May 2026
//  Description: Reusable title, chart, and caption wrapper for analytics panels.
//

import SwiftUI

/// - Description: Wraps a chart with title and explanatory caption on an elevated surface.
struct ChartSectionCard<ChartContent: View>: View {
    let title: String
    let caption: String
    @ViewBuilder var chart: () -> ChartContent

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(AppTheme.titleRounded())
                .foregroundStyle(.primary)

            chart()

            Text(caption)
                .font(.caption)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .ncStudioElevatedSurface(cornerRadius: 16)
    }
}
