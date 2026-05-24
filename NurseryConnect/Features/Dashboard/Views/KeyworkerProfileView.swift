//
//  KeyworkerProfileView.swift
//  NurseryConnect
//
//  Feature: Dashboard
//  Role: Keyworker
//  Created: 16 April 2026
//  Description: Read-only practitioner profile for the demo keyworker account.
//

import SwiftUI

/// - Description: Shows identity and assignment context for the signed-in keyworker (no separate staff entity in the MVP).
struct KeyworkerProfileView: View {
    let assignedRoomName: String

    @Environment(\.dismiss) private var dismiss
    @Environment(\.usesFloatingTabBarShell) private var usesFloatingTabBarShell

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                hero
                ProfileInfoRow(
                    title: "Role",
                    text: "Keyworker",
                    symbol: "person.fill"
                )
                ProfileInfoRow(
                    title: "Setting",
                    text: AppConstants.nurseryDisplayName,
                    symbol: "building.2.fill"
                )
                NavigationLink {
                    LegalComplianceView()
                } label: {
                    ProfileInfoRow(
                        title: ComplianceContent.legalScreenTitle,
                        text: "EYFS, Ofsted, RIDDOR, and UK GDPR visibility",
                        symbol: "doc.text.magnifyingglass"
                    )
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier(AppConstants.AccessibilityID.legalComplianceEntry)
            }
            .padding()
            .padding(.bottom, usesFloatingTabBarShell ? AppConstants.floatingTabBarClearance + 8 : 24)
        }
        .scrollIndicators(.hidden)
        .scrollContentBackground(.hidden)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .ncStudioFullBackdrop()
        .navigationTitle("My profile")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Done") {
                    dismiss()
                }
            }
        }
        .toolbarBackground(.hidden, for: .navigationBar)
    }

    private var hero: some View {
        HStack(alignment: .center, spacing: 16) {
            Text(initials(from: AppConstants.keyworkerDisplayName))
                .font(.title.weight(.bold))
                .foregroundStyle(
                    LinearGradient(
                        colors: [Color.ncPrimary, Color.ncGlowBlue],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 56, height: 56)
                .background(
                    Circle()
                        .fill(Color.ncPrimary.opacity(0.12))
                )
                .overlay {
                    Circle()
                        .stroke(
                            LinearGradient(
                                colors: [Color.ncGlassHighlight(lightOpacity: 0.65), Color.ncPrimary.opacity(0.25)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                }
            VStack(alignment: .leading, spacing: 6) {
                Text(AppConstants.keyworkerDisplayName)
                    .font(AppTheme.greetingRounded())
                    .lineLimit(1)
                    .minimumScaleFactor(0.85)
                Text(assignedRoomName)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.secondary)
                Label {
                    Text("Practitioner account")
                } icon: {
                    Image(systemName: "checkmark.seal.fill")
                        .foregroundStyle(Color.ncPrimary)
                }
                .font(.caption.weight(.medium))
                .foregroundStyle(.tertiary)
            }
            Spacer(minLength: 0)
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .ncStudioElevatedSurface(cornerRadius: 20)
    }

    private func initials(from fullName: String) -> String {
        let parts = fullName.split(separator: " ").map(String.init).filter { !$0.isEmpty }
        guard let first = parts.first else {
            return String(fullName.prefix(2)).uppercased()
        }
        if parts.count >= 2, let last = parts.last {
            let a = String(first.prefix(1))
            let b = String(last.prefix(1))
            return (a + b).uppercased()
        }
        return String(first.prefix(2)).uppercased()
    }
}

/// - Description: Sheet wrapper so the system chrome uses the same full-height studio gradient.
struct KeyworkerProfileSheet: View {
    let assignedRoomName: String

    var body: some View {
        NavigationStack {
            KeyworkerProfileView(assignedRoomName: assignedRoomName)
        }
        .presentationBackground {
            NCStudioFullBackdropView()
        }
        .presentationDragIndicator(.visible)
    }
}

#Preview {
    KeyworkerProfileSheet(assignedRoomName: "Sunshine Room")
        .environment(\.usesFloatingTabBarShell, true)
}
