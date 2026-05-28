//
//  EndOfDaySummarySheet.swift
//  NurseryConnect
//
//  Feature: Messages
//  Role: Keyworker
//  Created: 29 May 2026
//  Description: Editable end-of-day summary composer sent to parents via secure messaging.
//

import CoreData
import SwiftUI

struct EndOfDaySummarySheet: View {
    let childID: UUID
    let childDisplayName: String

    @Environment(\.managedObjectContext) private var context
    @Environment(\.dismiss) private var dismiss

    @StateObject private var viewModel: MessagingViewModel
    @State private var summaryText = ""
    @State private var isLoading = true

    init(childID: UUID, childDisplayName: String, managedObjectContext: NSManagedObjectContext) {
        self.childID = childID
        self.childDisplayName = childDisplayName
        _viewModel = StateObject(wrappedValue: MessagingViewModel(context: managedObjectContext))
    }

    var body: some View {
        NavigationStack {
            Group {
                if isLoading {
                    ProgressView("Preparing summary…")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Review and edit before sending to \(childDisplayName)'s family.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        TextEditor(text: $summaryText)
                            .frame(minHeight: 280)
                            .padding(8)
                            .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 12))
                            .onChange(of: summaryText) { _, newValue in
                                if newValue.count > AppConstants.messageBodyMaxLength * 4 {
                                    summaryText = String(newValue.prefix(AppConstants.messageBodyMaxLength * 4))
                                }
                            }
                        Text(AppConstants.messagesRetentionFooter)
                            .font(.caption2)
                            .foregroundStyle(.tertiary)
                        Spacer(minLength: 0)
                    }
                    .padding()
                }
            }
            .navigationTitle("End of Day Summary")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Send") { sendSummary() }
                        .disabled(summaryText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isLoading)
                        .accessibilityIdentifier(AppConstants.AccessibilityID.sendEndOfDaySummaryButton)
                }
            }
            .task { await loadDraft() }
            .alert("Something went wrong", isPresented: errorPresented) {
                Button("OK", role: .cancel) { viewModel.errorMessage = nil }
            } message: {
                Text(viewModel.errorMessage ?? "")
            }
        }
    }

    private var errorPresented: Binding<Bool> {
        Binding(
            get: { viewModel.errorMessage != nil },
            set: { if !$0 { viewModel.errorMessage = nil } }
        )
    }

    private func loadDraft() async {
        isLoading = true
        defer { isLoading = false }
        do {
            let draft = try EndOfDaySummaryBuilder.build(childID: childID, in: context)
            summaryText = draft.text
        } catch {
            viewModel.errorMessage = "Could not build the summary. Please try again."
        }
    }

    private func sendSummary() {
        do {
            try viewModel.sendEndOfDaySummary(childID: childID, body: summaryText)
            dismiss()
        } catch {
            viewModel.errorMessage = error.localizedDescription
        }
    }
}
