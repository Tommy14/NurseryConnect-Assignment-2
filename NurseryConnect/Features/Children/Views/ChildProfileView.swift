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
                        title: "Preferred name",
                        text: child.preferredName ?? "",
                        symbol: "quote.bubble"
                    )
                    profileInfoRow(
                        title: "Room",
                        text: child.roomName ?? "",
                        symbol: "door.left.hand.open"
                    )
                    profileInfoRow(
                        title: "Age",
                        text: Date.earlyYearsAgeDescription(dateOfBirth: child.dateOfBirth ?? Date()),
                        symbol: "birthday.cake.fill"
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
                        title: "Cultural and nationality context",
                        text: child.nationality ?? "",
                        symbol: "globe.europe.africa.fill"
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
                    profileInfoRow(
                        title: "Authorised collectors",
                        text: child.authorisedCollectors ?? "",
                        symbol: "person.2.fill"
                    )
                    profileInfoRow(
                        title: "Family details",
                        text: child.familyDetails ?? "",
                        symbol: "person.3.sequence.fill",
                        prefersSentenceBullets: true
                    )
                    profileInfoRow(
                        title: "Consent records notes",
                        text: child.consentRecordsNotes ?? "",
                        symbol: "checklist",
                        prefersSentenceBullets: true
                    )
                    profileInfoRow(
                        title: "EYFS development notes",
                        text: child.eyfsDevelopmentNotes ?? "",
                        symbol: "book.pages.fill",
                        prefersSentenceBullets: true
                    )
                    photoConsentRow(for: child)
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
        .toolbarBackground(.visible, for: .navigationBar)
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

    private func profileInfoRow(
        title: String,
        text: String,
        symbol: String,
        prefersSentenceBullets: Bool = false
    ) -> some View {
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
                detailTextView(text, prefersSentenceBullets: prefersSentenceBullets)
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

    private func detailTextView(_ text: String, prefersSentenceBullets: Bool) -> some View {
        let lines = text
            .components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
        let items = resolvedDetailItems(lines: lines, prefersSentenceBullets: prefersSentenceBullets)

        return Group {
            if items.isEmpty {
                Text("—")
                    .font(.body)
                    .foregroundStyle(.primary)
                    .fixedSize(horizontal: false, vertical: true)
            } else if items.count == 1 {
                Text(items[0])
                    .font(.body)
                    .foregroundStyle(.primary)
                    .fixedSize(horizontal: false, vertical: true)
            } else {
                VStack(alignment: .leading, spacing: 4) {
                    ForEach(Array(items.enumerated()), id: \.offset) { _, line in
                        HStack(alignment: .top, spacing: 6) {
                            Text("•")
                                .font(.body.weight(.semibold))
                                .foregroundStyle(.primary)
                            Text(line)
                                .font(.body)
                                .foregroundStyle(.primary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                }
            }
        }
    }

    private func resolvedDetailItems(lines: [String], prefersSentenceBullets: Bool) -> [String] {
        if lines.count > 1 { return lines }
        if prefersSentenceBullets { return sentenceItems(from: lines.first ?? "") }
        return lines
    }

    private func sentenceItems(from text: String) -> [String] {
        let normalised = text.replacingOccurrences(of: "\n", with: " ")
        let rawItems = normalised.components(separatedBy: ". ")
        return rawItems
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
            .map { item in
                if item.hasSuffix(".") { return item }
                return "\(item)."
            }
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
}
