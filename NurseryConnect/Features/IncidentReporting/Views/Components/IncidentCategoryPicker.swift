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

    private func accentColor(for category: IncidentCategory) -> Color {
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
        LazyVGrid(columns: columns, spacing: 12) {
            ForEach(IncidentCategory.allCases, id: \.self) { category in
                let isSelected = selection == category
                let accent = accentColor(for: category)
                Button {
                    selection = category
                } label: {
                    VStack(spacing: 9) {
                        Image(systemName: category.symbolName)
                            .font(.title2)
                            .foregroundStyle(isSelected ? Color.white : accent)
                        Text(category.title)
                            .font(.footnote.weight(.semibold))
                            .multilineTextAlignment(.center)
                            .foregroundStyle(isSelected ? Color.white : Color.primary)
                            .lineLimit(2)
                    }
                    .padding()
                    .frame(maxWidth: .infinity, minHeight: 96)
                    .background(
                        Group {
                            if isSelected {
                                RoundedRectangle(cornerRadius: 14, style: .continuous)
                                    .fill(
                                        LinearGradient(
                                            colors: [accent, accent.opacity(0.78)],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                            } else {
                                RoundedRectangle(cornerRadius: 14, style: .continuous)
                                    .fill(Color.ncCardSurface)
                            }
                        }
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .stroke(isSelected ? accent.opacity(0.95) : accent.opacity(0.28), lineWidth: isSelected ? 1.4 : 1)
                    )
                    .overlay(alignment: .topTrailing) {
                        if isSelected {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.caption.weight(.bold))
                                .foregroundStyle(.white)
                                .padding(8)
                        }
                    }
                    .shadow(color: isSelected ? accent.opacity(0.26) : Color.clear, radius: 8, x: 0, y: 4)
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
