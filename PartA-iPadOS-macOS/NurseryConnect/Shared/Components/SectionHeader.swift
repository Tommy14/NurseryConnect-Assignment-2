//
//  SectionHeader.swift
//  NurseryConnect
//
//  Feature: Shared UI
//  Role: Keyworker
//  Created: 30 March 2026
//  Description: Section title with optional subtitle for grouped forms and lists.
//
// -----------------------------------------------------------------
// Date       Name        What has done
// -----------------------------------------------------------------
// 300326     Tommy1914   Created the file with rounded title styling.
// -----------------------------------------------------------------

import SwiftUI

/// - Description: Displays a section heading consistent with the nursery design language.
struct SectionHeader: View {
    let title: String
    var subtitle: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(AppTheme.titleRounded())
                .foregroundStyle(Color.primary)
            if let subtitle {
                Text(subtitle)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
    }
}

#Preview {
    SectionHeader(title: "Details", subtitle: "Required for this entry type")
        .padding()
}
