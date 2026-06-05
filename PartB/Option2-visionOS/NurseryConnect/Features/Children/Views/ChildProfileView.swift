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
// 100426     Tommy1914   Hero header + studio info rows (read-only).
// 100426     Tommy1914   Bottom scroll inset when shown under keyworker floating tab bar.
// 140426     Tommy1914   Photo consent row: read-only green tick / red cross from stored data.
// 290526     Tommy1914   Shared `ProfileInfoRow` + studio backdrop; panel mode uses shell header.
// -----------------------------------------------------------------

import Combine
import CoreData
import SwiftUI

/// - Description: Shows extended child information for practitioners during care decisions.
struct ChildProfileView: View {
    let childId: UUID
    /// When true, omits navigation chrome (e.g. iPad trailing profile column with its own header).
    var embedsInPanel: Bool = false

    @Environment(\.usesFloatingTabBarShell) private var usesFloatingTabBarShell
    @StateObject private var viewModel: ChildViewModel

    init(childId: UUID, context: NSManagedObjectContext, embedsInPanel: Bool = false) {
        self.childId = childId
        self.embedsInPanel = embedsInPanel
        _viewModel = StateObject(wrappedValue: ChildViewModel(context: context))
    }

    var body: some View {
        ScrollView {
            if let child = viewModel.child {
                VStack(alignment: .leading, spacing: embedsInPanel ? 12 : 18) {
                    profileHero(for: child)
                    ProfileInfoRow(
                        title: "Preferred name",
                        text: child.preferredName ?? "",
                        symbol: "quote.bubble"
                    )
                    ProfileInfoRow(
                        title: "Room",
                        text: child.roomName ?? "",
                        symbol: "door.left.hand.open"
                    )
                    ProfileInfoRow(
                        title: "Age",
                        text: Date.earlyYearsAgeDescription(dateOfBirth: child.dateOfBirth ?? Date()),
                        symbol: "birthday.cake.fill"
                    )
                    ProfileInfoRow(
                        title: "Allergies",
                        text: child.allergies ?? "",
                        symbol: "exclamationmark.triangle.fill"
                    )
                    ProfileInfoRow(
                        title: "Dietary requirements",
                        text: child.dietaryRequirements ?? "",
                        symbol: "fork.knife"
                    )
                    ProfileInfoRow(
                        title: "Cultural and nationality context",
                        text: child.nationality ?? "",
                        symbol: "globe.europe.africa.fill"
                    )
                    ProfileInfoRow(
                        title: "Medical notes",
                        text: child.medicalNotes ?? "",
                        symbol: "cross.case.fill"
                    )
                    ProfileInfoRow(
                        title: "Key person",
                        text: child.keyworkerName ?? "",
                        symbol: "person.fill"
                    )
                    ProfileInfoRow(
                        title: "Authorised collectors",
                        text: child.authorisedCollectors ?? "",
                        symbol: "person.2.fill"
                    )
                    ProfileInfoRow(
                        title: "Family details",
                        text: child.familyDetails ?? "",
                        symbol: "person.3.sequence.fill",
                        prefersSentenceBullets: true
                    )
                    ProfileInfoRow(
                        title: "Consent records notes",
                        text: child.consentRecordsNotes ?? "",
                        symbol: "checklist",
                        prefersSentenceBullets: true
                    )
                    complianceNoteRow(
                        title: "Compliance note",
                        text: ComplianceContent.childProfileConsentNote
                    )
                    ProfileInfoRow(
                        title: "EYFS development notes",
                        text: child.eyfsDevelopmentNotes ?? "",
                        symbol: "book.pages.fill",
                        prefersSentenceBullets: true
                    )
                    photoConsentRow(for: child)
                }
                .padding(.horizontal, embedsInPanel ? 12 : 16)
                .padding(.vertical, embedsInPanel ? 8 : 16)
                .padding(.bottom, usesFloatingTabBarShell ? AppConstants.floatingTabBarClearance + 8 : 0)
            } else {
                ProgressView()
                    .frame(maxWidth: .infinity, minHeight: 200)
            }
        }
        .scrollIndicators(.hidden)
        .scrollContentBackground(.hidden)
        .ncStudioScreenBackdropUnlessChildWorkspace()
        .navigationTitle(embedsInPanel ? "" : "Profile")
        .toolbarBackground(Color.ncBackground, for: .navigationBar)
        .toolbarBackground(embedsInPanel ? .automatic : .visible, for: .navigationBar)
        .task(id: childId) {
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
                Text(child.fullDisplayName)
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

    private func photoConsentRow(for child: Child) -> some View {
        let isOn = child.photoConsent
        return HStack(alignment: .center, spacing: 12) {
            Text("Photo consent on file")
                .font(.body)
                .foregroundStyle(.primary)
                .frame(maxWidth: .infinity, alignment: .leading)
            Image(systemName: isOn ? "checkmark.circle.fill" : "xmark.circle.fill")
                .font(.title2)
                .foregroundStyle(isOn ? Color.green : Color.red)
                .accessibilityHidden(true)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .ncStudioElevatedSurface(cornerRadius: 16)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(
            "Photo consent on file. \(isOn ? "Consent is on file." : "No consent on file.")"
        )
    }

    private func complianceNoteRow(title: String, text: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Label(title, systemImage: "shield.checkered")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Color.ncPrimary)
            Text(text)
                .font(.footnote)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.ncPrimary.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(Color.ncPrimary.opacity(0.18), lineWidth: 1)
                .allowsHitTesting(false)
        }
        .accessibilityElement(children: .combine)
    }
}
