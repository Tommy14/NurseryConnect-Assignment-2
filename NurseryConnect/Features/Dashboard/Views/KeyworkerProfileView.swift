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
                keyworkerInfoRow(
                    title: "Role",
                    text: "Keyworker",
                    symbol: "person.fill"
                )
                keyworkerInfoRow(
                    title: "Setting",
                    text: AppConstants.nurseryDisplayName,
                    symbol: "building.2.fill"
                )
            }
            .padding()
            .padding(.bottom, usesFloatingTabBarShell ? AppConstants.floatingTabBarClearance + 8 : 0)
        }
        .scrollIndicators(.hidden)
        .scrollContentBackground(.hidden)
        .background(Color.ncBackground)
        .navigationTitle("My profile")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Done") {
                    dismiss()
                }
            }
        }
        .toolbarBackground(Color.ncBackground, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
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
                    .font(.title3.weight(.bold))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color.ncPrimary, Color.ncGlowBlue],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
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

    private func keyworkerInfoRow(title: String, text: String, symbol: String) -> some View {
        HStack(alignment: .top, spacing: 14) {
            Image(systemName: symbol)
                .font(.title3)
                .foregroundStyle(
                    LinearGradient(
                        colors: [Color.ncPrimary, Color.ncGlowBlue],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 32, alignment: .center)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 6) {
                Text(title.uppercased())
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.secondary)
                    .tracking(0.6)
                Text(text)
                    .font(.body)
                    .foregroundStyle(.primary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 0)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.ncCardSurface)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 5)
        .overlay {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(
                    LinearGradient(
                        colors: [
                            Color.ncGlassHighlight(lightOpacity: 0.6),
                            Color.ncPrimary.opacity(0.14),
                            Color.ncGlowBlue.opacity(0.1)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
                .allowsHitTesting(false)
        }
        .accessibilityElement(children: .combine)
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

#Preview {
    NavigationStack {
        KeyworkerProfileView(assignedRoomName: "Sunshine Room")
    }
    .environment(\.usesFloatingTabBarShell, true)
}
