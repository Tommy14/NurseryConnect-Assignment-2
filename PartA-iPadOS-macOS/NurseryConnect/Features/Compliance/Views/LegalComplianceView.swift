//
//  LegalComplianceView.swift
//  NurseryConnect
//
//  Feature: Compliance
//  Role: Keyworker
//  Created: 22 April 2026
//  Description: Dedicated legal and compliance overview for UK (England) workflows.
//

import SwiftUI

struct LegalComplianceView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                complianceSection(
                    title: "Frameworks followed",
                    symbol: "building.columns.fill",
                    items: ComplianceContent.frameworks
                )
                complianceSection(
                    title: "How this app applies them",
                    symbol: "checklist.checked",
                    items: ComplianceContent.appApplicationRules
                )
                complianceSection(
                    title: "Where enforcement appears",
                    symbol: "map.fill",
                    items: ComplianceContent.enforcementLocations
                )
                complianceSection(
                    title: "Data protection commitments",
                    symbol: "lock.shield.fill",
                    items: ComplianceContent.dataProtectionCommitments
                )

                Text(ComplianceContent.legalScreenDisclaimer)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.top, 2)
                    .accessibilityIdentifier(AppConstants.AccessibilityID.complianceDisclaimerText)
            }
            .padding()
        }
        .scrollIndicators(.hidden)
        .scrollContentBackground(.hidden)
        .scrollContentBackground(.hidden)
        .ncStudioScreenBackdrop()
        .navigationTitle(ComplianceContent.legalScreenTitle)
        .navigationBarTitleDisplayMode(.inline)
        .accessibilityIdentifier(AppConstants.AccessibilityID.legalComplianceScreen)
    }

    private func complianceSection(title: String, symbol: String, items: [String]) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Label {
                Text(title.uppercased())
                    .font(.caption.weight(.bold))
                    .tracking(0.7)
                    .foregroundStyle(.secondary)
            } icon: {
                Image(systemName: symbol)
                    .foregroundStyle(Color.ncPrimary)
            }

            VStack(alignment: .leading, spacing: 8) {
                ForEach(Array(items.enumerated()), id: \.offset) { _, item in
                    HStack(alignment: .top, spacing: 8) {
                        Text("•")
                            .font(.body.weight(.semibold))
                            .foregroundStyle(.primary)
                        Text(item)
                            .font(.body)
                            .foregroundStyle(.primary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .ncStudioElevatedSurface(cornerRadius: 16)
    }
}

#Preview {
    NavigationStack {
        LegalComplianceView()
    }
}
