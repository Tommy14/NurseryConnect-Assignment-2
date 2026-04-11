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
// 100426     Tommy1914   FAB + scroll inset when embedded in keyworker floating tab bar.
// 100426     Tommy1914   Inline nav title + dossier header (no duplicate name); studio backdrop.
// 180426     Tommy1914   Daily journal makeover: grouped header card, ContentUnavailableView, circular FAB, nav chrome.
// 180426     Tommy1914   Transparent nav bar so top gradient merges with page (no solid strip).
// -----------------------------------------------------------------

import Combine
import CoreData
import SwiftUI

/// - Description: Child-scoped diary screen with timeline and add entry affordance.
struct DailyDiaryListView: View {
    let summary: KeyworkerChildSummary

    @Environment(\.managedObjectContext) private var context
    @Environment(\.usesFloatingTabBarShell) private var usesFloatingTabBarShell
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
                VStack(alignment: .leading, spacing: 20) {
                    sessionDossierHeader
                    if viewModel.entries.isEmpty {
                        ContentUnavailableView {
                            Label("No entries yet today", systemImage: "calendar.badge.clock")
                        } description: {
                            Text("Start logging \(summary.firstName)’s day.")
                        }
                        .padding(.top, 8)
                    } else {
                        VStack(alignment: .leading, spacing: 10) {
                            HStack(spacing: 8) {
                                Image(systemName: "list.bullet.rectangle.fill")
                                    .font(.caption.weight(.semibold))
                                    .foregroundStyle(Color.ncPrimary)
                                Text("Today’s observations")
                                    .font(.caption.weight(.bold))
                                    .tracking(0.6)
                                    .foregroundStyle(.secondary)
                                Spacer(minLength: 0)
                            }
                            DiaryTimelineView(entries: viewModel.entries, viewModel: viewModel)
                                .animation(.spring(response: 0.45, dampingFraction: 0.86), value: viewModel.entries.count)
                        }
                    }
                }
                .padding()
                .padding(.bottom, usesFloatingTabBarShell ? AppConstants.floatingTabBarClearance + 8 : 0)
            }
            .scrollIndicators(.hidden)
            .scrollContentBackground(.hidden)

            Button {
                showAdd = true
            } label: {
                Image(systemName: "plus")
                    .font(.title2.weight(.semibold))
                    .foregroundStyle(Color.white)
                    .frame(width: 56, height: 56)
                    .background(
                        LinearGradient(
                            colors: [Color.ncPrimary, Color.ncGlowBlue],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .clipShape(Circle())
                    .shadow(color: Color.black.opacity(0.2), radius: 8, x: 0, y: 4)
                    .shadow(color: Color.ncPrimary.opacity(0.35), radius: 10, x: 0, y: 6)
            }
            .padding(.horizontal, 16)
            .padding(.top, 16)
            .padding(.bottom, 16 + (usesFloatingTabBarShell ? AppConstants.floatingTabBarClearance : 0))
            .accessibilityIdentifier(AppConstants.AccessibilityID.addDiaryFAB)
            .accessibilityLabel("Add diary entry")
            .accessibilityHint("Opens the form to log a new diary observation.")
        }
        .ncStudioScreenBackdrop()
        .navigationTitle("Daily journal")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.hidden, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                NavigationLink {
                    ChildProfileView(childId: summary.id, context: context)
                } label: {
                    Image(systemName: "person.crop.circle")
                        .font(.body.weight(.medium))
                }
                .accessibilityLabel("Child profile")
            }
        }
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

    /// Single place for the child’s full name; nav uses screen title instead to avoid repetition.
    private var sessionDossierHeader: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 8) {
                Circle()
                    .fill(Color.green.opacity(0.9))
                    .frame(width: 7, height: 7)
                Text("Live session")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                Spacer(minLength: 0)
                Text(Date.now.formatted(.dateTime.day().month(.abbreviated)))
                    .font(.caption.weight(.medium))
                    .foregroundStyle(.tertiary)
                    .monospacedDigit()
            }

            HStack(alignment: .center, spacing: 14) {
                ChildAvatarView(
                    firstName: summary.firstName,
                    lastName: summary.lastName,
                    childId: summary.id,
                    showsAccentRing: true,
                    dimension: 56
                )
                VStack(alignment: .leading, spacing: 4) {
                    Text("\(summary.firstName) \(summary.lastName)")
                        .font(.title3.weight(.bold))
                        .foregroundStyle(.primary)
                    Label {
                        Text(Date.earlyYearsAgeDescription(dateOfBirth: summary.dateOfBirth))
                    } icon: {
                        Image(systemName: "calendar")
                    }
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                }
                Spacer(minLength: 0)
            }

            if !summary.allergies.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                HStack(alignment: .top, spacing: 10) {
                    Image(systemName: "exclamationmark.shield.fill")
                        .font(.body.weight(.semibold))
                        .foregroundStyle(Color.ncDanger)
                        .accessibilityHidden(true)
                    Text("Allergies on file — \(summary.allergies)")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(.primary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.ncDanger.opacity(0.08))
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color.ncCardSurface)
                .shadow(color: Color.black.opacity(0.06), radius: 10, x: 0, y: 4)
        }
        .overlay {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Color.primary.opacity(0.06), lineWidth: 1)
        }
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
                genderTag: .female,
                dot: .complete
            ),
            managedObjectContext: ctx
        )
        .environment(\.managedObjectContext, ctx)
    }
}
