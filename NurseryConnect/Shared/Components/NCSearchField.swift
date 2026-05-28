//
//  NCSearchField.swift
//  NurseryConnect
//
//  Feature: Shared UI
//  Role: Keyworker
//  Created: 29 May 2026
//  Description: Consistent search field styling for child roster filters.
//

import SwiftUI

/// - Description: Rounded search field used on the dashboard and iPad children sidebar.
struct NCSearchField: View {
    var placeholder: String
    @Binding var text: String

    init(_ placeholder: String = "Search My Children", text: Binding<String>) {
        self.placeholder = placeholder
        _text = text
    }

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(.secondary)
                .accessibilityHidden(true)
            TextField(placeholder, text: $text)
                .textInputAutocapitalization(.words)
                .autocorrectionDisabled()
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: AppConstants.searchFieldCornerRadius, style: .continuous)
                .fill(Color.ncCardSurface)
        )
        .overlay {
            RoundedRectangle(cornerRadius: AppConstants.searchFieldCornerRadius, style: .continuous)
                .stroke(Color.ncAdaptiveHairlineStroke, lineWidth: 1)
        }
    }
}
