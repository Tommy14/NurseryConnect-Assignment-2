//
//  IncidentCategoryPicker.swift
//  NurseryConnect
//
//  Feature: Incident Reporting
//  Role: Keyworker
//  Created: 6 April 2026
//  Description: Grid of tappable category tiles with SF Symbol artwork.
//
// -----------------------------------------------------------------
// Date       Name        What has done
// -----------------------------------------------------------------
// 060426     Tommy1914   Created the file with two-column adaptive grid selection.
// -----------------------------------------------------------------

import SwiftUI

/// - Description: Lets practitioners pick an incident category with large touch targets.
struct IncidentCategoryPicker: View {
    @Binding var selection: IncidentCategory

    private let columns = [GridItem(.adaptive(minimum: 150), spacing: 12)]

    var body: some View {
        LazyVGrid(columns: columns, spacing: 12) {
            ForEach(IncidentCategory.allCases, id: \.self) { category in
                Button {
                    selection = category
                } label: {
                    VStack(spacing: 8) {
                        Image(systemName: category.symbolName)
                            .font(.title2)
                            .foregroundStyle(selection == category ? Color.white : Color.ncPrimary)
                        Text(category.title)
                            .font(.footnote.weight(.semibold))
                            .multilineTextAlignment(.center)
                            .foregroundStyle(selection == category ? Color.white : Color.primary)
                    }
                    .padding()
                    .frame(maxWidth: .infinity, minHeight: 96)
                    .background(selection == category ? Color.ncPrimary : Color.ncCardSurface)
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .stroke(Color.ncPrimary.opacity(selection == category ? 0.0 : 0.15), lineWidth: 1)
                    )
                }
                .buttonStyle(.plain)
                .accessibilityLabel(category.title)
                .accessibilityHint("Selects this incident category.")
            }
        }
    }
}

#Preview {
    IncidentCategoryPicker(selection: .constant(.accidentMinor))
        .padding()
        .background(Color.ncBackground)
}
