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
            VStack(alignment: .leading, spacing: 16) {
                profileHeaderBar
                hero
                profileInfoCard(
                    title: "Role",
                    text: "Keyworker",
                    symbol: "person.fill"
                )
                profileInfoCard(
                    title: "Setting",
                    text: AppConstants.nurseryDisplayName,
                    symbol: "building.2.fill"
                )
                NavigationLink {
                    LegalComplianceView()
                } label: {
                    profileInfoCard(
                        title: "Legal & Compliance",
                        text: "EYFS, Ofsted, RIDDOR, and UK GDPR visibility",
                        symbol: "doc.text.magnifyingglass"
                    )
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier(AppConstants.AccessibilityID.legalComplianceEntry)
            }
            .padding(.horizontal, 16)
            .padding(.top, 10)
            .padding(.bottom, usesFloatingTabBarShell ? AppConstants.floatingTabBarClearance + 8 : 24)
        }
        .scrollIndicators(.hidden)
        .scrollContentBackground(.hidden)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(profileSheetBackground.ignoresSafeArea())
        .toolbar(.hidden, for: .navigationBar)
    }

    private var hero: some View {
        HStack(alignment: .center, spacing: 16) {
            Text(initials(from: AppConstants.keyworkerDisplayName))
                .font(.title.weight(.bold))
                .foregroundStyle(Color.ncPrimary.opacity(0.9))
                .frame(width: 56, height: 56)
                .background(
                    Circle()
                        .fill(Color.ncPrimary.opacity(0.16))
                )
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
                .foregroundStyle(.secondary)
            }
            Spacer(minLength: 0)
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white.opacity(0.9), in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(Color.ncPrimary.opacity(0.25), lineWidth: 1.2)
        }
    }

    private var profileHeaderBar: some View {
        ZStack {
            Text("My profile")
                .font(.title3.weight(.semibold))
                .foregroundStyle(.primary)

            HStack {
                Spacer()
                Button { dismiss() } label: {
                    Image(systemName: "xmark")
                        .font(.headline.weight(.semibold))
                        .foregroundStyle(Color.primary.opacity(0.78))
                        .frame(width: 44, height: 44)
                        .background(
                            Circle()
                                .fill(Color.white.opacity(0.55))
                        )
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Close")
            }
        }
    }

    private func profileInfoCard(title: String, text: String, symbol: String) -> some View {
        HStack(alignment: .center, spacing: 12) {
            Image(systemName: symbol)
                .font(.title3.weight(.semibold))
                .foregroundStyle(Color.ncPrimary.opacity(0.86))
                .frame(width: 30)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 6) {
                Text(title)
                    .font(.caption.weight(.bold))
                    .textCase(.uppercase)
                    .tracking(1.1)
                    .foregroundStyle(.secondary)
                Text(text)
                    .font(.title3.weight(.medium))
                    .foregroundStyle(.primary)
                    .lineLimit(2)
            }
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white.opacity(0.94), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(Color.ncPrimary.opacity(0.23), lineWidth: 1.1)
        }
    }

    private var profileSheetBackground: some View {
        LinearGradient(
            colors: [
                Color(red: 0.82, green: 0.9, blue: 0.97),
                Color(red: 0.79, green: 0.87, blue: 0.94)
            ],
            startPoint: .top,
            endPoint: .bottom
        )
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
        .presentationDetents([.fraction(0.82)])
        .presentationCornerRadius(34)
    }
}

#Preview {
    KeyworkerProfileSheet(assignedRoomName: "Sunshine Room")
        .environment(\.usesFloatingTabBarShell, true)
}
