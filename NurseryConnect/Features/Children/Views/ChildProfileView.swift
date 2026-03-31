//
//  ChildProfileView.swift
//  NurseryConnect
//
//  Feature: Children
//  Role: Keyworker
//  Created: 9 April 2026
//  Description: Detailed safeguarding-oriented profile for a single child.
//
// -----------------------------------------------------------------
// Date       Name        What has done
// -----------------------------------------------------------------
// 090426     Tommy1914   Created the file with medical and dietary sections.
// 120426     Tommy1914   Hero header + studio info rows (read-only).
// 130426     Tommy1914   Bottom scroll inset when shown under keyworker floating tab bar.
// -----------------------------------------------------------------

import Combine
import CoreData
import SwiftUI

/// - Description: Shows extended child information for practitioners during care decisions.
struct ChildProfileView: View {
    let childId: UUID

    @Environment(\.usesFloatingTabBarShell) private var usesFloatingTabBarShell
    @StateObject private var viewModel: ChildViewModel

    init(childId: UUID, context: NSManagedObjectContext) {
        self.childId = childId
        _viewModel = StateObject(wrappedValue: ChildViewModel(context: context))
    }

    var body: some View {
        ScrollView {
            if let child = viewModel.child {
                VStack(alignment: .leading, spacing: 18) {
                    profileHero(for: child)
                    profileInfoRow(
                        title: "Room",
                        text: child.roomName ?? "",
                        symbol: "door.left.hand.open"
                    )
                    profileInfoRow(
                        title: "Allergies",
                        text: child.allergies ?? "",
                        symbol: "exclamationmark.triangle.fill"
                    )
                    profileInfoRow(
                        title: "Dietary requirements",
                        text: child.dietaryRequirements ?? "",
                        symbol: "fork.knife"
                    )
                    profileInfoRow(
                        title: "Medical notes",
                        text: child.medicalNotes ?? "",
                        symbol: "cross.case.fill"
                    )
                    profileInfoRow(
                        title: "Key person",
                        text: child.keyworkerName ?? "",
                        symbol: "person.fill"
                    )
                    Toggle("Photo consent on file", isOn: .constant(child.photoConsent))
                        .disabled(true)
                        .tint(Color.ncPrimary)
                        .padding(16)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .ncStudioElevatedSurface(cornerRadius: 16)
                }
                .padding()
                .padding(.bottom, usesFloatingTabBarShell ? AppConstants.floatingTabBarClearance + 8 : 0)
            } else {
                ProgressView()
                    .frame(maxWidth: .infinity, minHeight: 200)
            }
        }
        .scrollIndicators(.hidden)
        .scrollContentBackground(.hidden)
        .background(Color.ncBackground)
        .navigationTitle("Profile")
        .toolbarBackground(Color.ncBackground, for: .navigationBar)
        .task {
            await viewModel.loadChild(id: childId)
        }
        .alert("Something went wrong", isPresented: Binding(
            get: { viewModel.errorMessage != nil },
            set: { if !$0 { viewModel.errorMessage = nil } }
        )) {
            Button("OK", role: .cancel) { viewModel.errorMessage = nil }
        } message: {
            Text(viewModel.errorMessage ?? "")
        }
    }

    private func profileHero(for child: Child) -> some View {
        HStack(alignment: .center, spacing: 16) {
            if let id = child.id {
                ChildAvatarView(
                    firstName: child.firstName ?? "",
                    lastName: child.lastName ?? "",
                    childId: id,
                    showsAccentRing: true,
                    dimension: 56
                )
            }
            VStack(alignment: .leading, spacing: 6) {
                Text("\(child.firstName ?? "") \(child.lastName ?? "")")
                    .font(AppTheme.greetingRounded())
                Label {
                    Text(Date.earlyYearsAgeDescription(dateOfBirth: child.dateOfBirth ?? Date()))
                } icon: {
                    Image(systemName: "calendar")
                        .foregroundStyle(Color.ncPrimary)
                }
                .font(.subheadline.weight(.medium))
                .foregroundStyle(.secondary)
            }
            Spacer(minLength: 0)
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .ncStudioElevatedSurface(cornerRadius: 20)
    }

    private func profileInfoRow(title: String, text: String, symbol: String) -> some View {
        HStack(alignment: .top, spacing: 14) {
            Image(systemName: symbol)
                .font(.title3)
                .foregroundStyle(
                    LinearGradient(
                        colors: [Color.ncPrimary, Color.cyan.opacity(0.8)],
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
                Text(text.isEmpty ? "—" : text)
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
                        colors: [Color.white.opacity(0.55), Color.ncPrimary.opacity(0.14), Color.cyan.opacity(0.08)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
                .allowsHitTesting(false)
        }
        .accessibilityElement(children: .combine)
    }
}
