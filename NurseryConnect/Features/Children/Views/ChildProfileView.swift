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
// -----------------------------------------------------------------

import CoreData
import SwiftUI

/// - Description: Shows extended child information for practitioners during care decisions.
struct ChildProfileView: View {
    let childId: UUID

    @StateObject private var viewModel: ChildViewModel

    init(childId: UUID, context: NSManagedObjectContext) {
        self.childId = childId
        _viewModel = StateObject(wrappedValue: ChildViewModel(context: context))
    }

    var body: some View {
        ScrollView {
            if let child = viewModel.child {
                VStack(alignment: .leading, spacing: 16) {
                    HStack(spacing: 16) {
                        if let id = child.id {
                            ChildAvatarView(firstName: child.firstName ?? "", lastName: child.lastName ?? "", childId: id)
                        }
                        VStack(alignment: .leading) {
                            Text("\(child.firstName ?? "") \(child.lastName ?? "")")
                                .font(AppTheme.headlineRounded())
                            Text(Date.earlyYearsAgeDescription(dateOfBirth: child.dateOfBirth ?? Date()))
                                .foregroundStyle(.secondary)
                        }
                    }
                    profileSection(title: "Room", text: child.roomName ?? "")
                    profileSection(title: "Allergies", text: child.allergies ?? "")
                    profileSection(title: "Dietary requirements", text: child.dietaryRequirements ?? "")
                    profileSection(title: "Medical notes", text: child.medicalNotes ?? "")
                    profileSection(title: "Key person", text: child.keyworkerName ?? "")
                    Toggle("Photo consent on file", isOn: .constant(child.photoConsent))
                        .disabled(true)
                }
                .padding()
            } else {
                ProgressView()
                    .frame(maxWidth: .infinity, minHeight: 200)
            }
        }
        .background(Color.ncBackground.ignoresSafeArea())
        .navigationTitle("Profile")
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

    private func profileSection(title: String, text: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.headline)
            Text(text.isEmpty ? "—" : text)
                .font(.body)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color.ncCardSurface)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
}
