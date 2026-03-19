//
//  DailyDiaryListView.swift
//  NurseryConnect
//
//  Feature: Daily Diary
//  Role: Keyworker
//  Created: 4 April 2026
//  Description: Lists today’s diary timeline for a child with a floating add action.
//
// -----------------------------------------------------------------
// Date       Name        What has done
// -----------------------------------------------------------------
// 040426     Tommy1914   Created the file with coral header, timeline, and FAB sheet.
// -----------------------------------------------------------------

import CoreData
import SwiftUI

/// - Description: Child-scoped diary screen with timeline and add entry affordance.
struct DailyDiaryListView: View {
    let summary: KeyworkerChildSummary

    @Environment(\.managedObjectContext) private var context
    @StateObject private var viewModel: DailyDiaryViewModel
    @State private var showAdd = false

    /// - Description: Creates a diary list bound to the supplied child summary and Core Data context.
    /// - Parameters:
    ///   - summary: Lightweight child metadata from the dashboard.
    ///   - managedObjectContext: Main-queue context shared with the app.
    init(summary: KeyworkerChildSummary, managedObjectContext: NSManagedObjectContext) {
        self.summary = summary
        _viewModel = StateObject(wrappedValue: DailyDiaryViewModel(childID: summary.id, context: managedObjectContext))
    }

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    header
                    if viewModel.entries.isEmpty {
                        EmptyStateView(
                            symbolName: "calendar.badge.clock",
                            title: "No entries yet today",
                            message: "Start logging \(summary.firstName)’s day."
                        )
                        .padding(.top, 24)
                    } else {
                        DiaryTimelineView(entries: viewModel.entries, viewModel: viewModel)
                            .animation(.spring(response: 0.45, dampingFraction: 0.86), value: viewModel.entries.count)
                    }
                }
                .padding()
            }
            .background(Color.ncBackground.ignoresSafeArea())

            Button {
                showAdd = true
            } label: {
                Image(systemName: "plus")
                    .font(.title2.weight(.semibold))
                    .foregroundStyle(Color.white)
                    .frame(width: 56, height: 56)
                    .background(Color.ncPrimary)
                    .clipShape(RoundedRectangle(cornerRadius: AppConstants.fabCornerRadius, style: .continuous))
                    .shadow(color: Color.black.opacity(0.15), radius: 8, x: 0, y: 4)
            }
            .padding()
            .accessibilityIdentifier(AppConstants.AccessibilityID.addDiaryFAB)
            .accessibilityLabel("Add diary entry")
            .accessibilityHint("Opens the form to log a new diary observation.")
        }
        .navigationTitle("\(summary.firstName) \(summary.lastName)")
        .sheet(isPresented: $showAdd) {
            AddDiaryEntryView(childID: summary.id, viewModel: viewModel)
                .environment(\.managedObjectContext, context)
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
        }
        .task {
            await viewModel.loadEntries()
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

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("\(summary.firstName) \(summary.lastName)")
                        .font(AppTheme.headlineRounded())
                    Text("\(Date.earlyYearsAgeDescription(dateOfBirth: summary.dateOfBirth)) • \(summary.roomName)")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                Spacer()
            }
            if !summary.allergies.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                // GDPR: Surface allergies on care screens where food and health judgements are made.
                StatusBadge(text: "Allergies: \(summary.allergies)", color: .ncDanger)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.ncDiaryNappy.opacity(0.35))
        .clipShape(RoundedRectangle(cornerRadius: AppConstants.cardCornerRadius, style: .continuous))
    }
}

#Preview {
    let ctx = PersistenceController.preview.container.viewContext
    return NavigationStack {
        DailyDiaryListView(
            summary: KeyworkerChildSummary(
                id: UUID(),
                firstName: "Emma",
                lastName: "Wilson",
                roomName: "Sunshine Room",
                allergies: "Peanuts",
                dateOfBirth: Date(),
                dot: .complete
            ),
            managedObjectContext: ctx
        )
        .environment(\.managedObjectContext, ctx)
    }
}
