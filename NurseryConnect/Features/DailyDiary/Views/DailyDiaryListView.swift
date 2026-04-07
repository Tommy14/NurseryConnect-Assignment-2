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
// 130426     Tommy1914   FAB + scroll inset when embedded in keyworker floating tab bar.
// 130426     Tommy1914   Inline nav title + dossier header (no duplicate name); studio backdrop.
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
                VStack(alignment: .leading, spacing: 16) {
                    sessionDossierHeader
                    if viewModel.entries.isEmpty {
                        EmptyStateView(
                            symbolName: "calendar.badge.clock",
                            title: "No entries yet today",
                            message: "Start logging \(summary.firstName)’s day."
                        )
                        .padding(.top, 24)
                    } else {
                        VStack(alignment: .leading, spacing: 10) {
                            HStack(spacing: 8) {
                                Image(systemName: "list.bullet.rectangle.fill")
                                    .font(.caption.weight(.semibold))
                                    .foregroundStyle(
                                        LinearGradient(
                                            colors: [Color.ncPrimary, Color.cyan.opacity(0.85)],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
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
                            colors: [Color.ncPrimary, Color.cyan.opacity(0.75)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .clipShape(RoundedRectangle(cornerRadius: AppConstants.fabCornerRadius, style: .continuous))
                    .shadow(color: Color.ncPrimary.opacity(0.35), radius: 12, x: 0, y: 6)
                    .overlay {
                        RoundedRectangle(cornerRadius: AppConstants.fabCornerRadius, style: .continuous)
                            .strokeBorder(Color.white.opacity(0.35), lineWidth: 1)
                    }
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
        .toolbarBackground(.hidden, for: .navigationBar)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                NavigationLink {
                    ChildProfileView(childId: summary.id, context: context)
                } label: {
                    Label("Profile", systemImage: "person.crop.circle")
                }
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
        HStack(alignment: .top, spacing: 0) {
            Capsule(style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [Color.ncPrimary.opacity(0.95), Color.cyan.opacity(0.55)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(width: 5)
                .padding(.vertical, 14)
                .padding(.leading, 2)

            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 8) {
                    Image(systemName: "dot.radiowaves.left.and.right")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(Color.ncPrimary)
                    Text("LIVE SESSION")
                        .font(.caption.weight(.bold))
                        .tracking(1.1)
                        .foregroundStyle(.secondary)
                    Spacer(minLength: 0)
                    Text(Date.now.formatted(.dateTime.day().month(.abbreviated)))
                        .font(.caption.weight(.semibold))
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
                    VStack(alignment: .leading, spacing: 6) {
                        Text("\(summary.firstName) \(summary.lastName)")
                            .font(AppTheme.greetingRounded())
                            .foregroundStyle(.primary)
                        HStack(spacing: 6) {
                            Label {
                                Text(Date.earlyYearsAgeDescription(dateOfBirth: summary.dateOfBirth))
                            } icon: {
                                Image(systemName: "calendar")
                                    .font(.caption.weight(.semibold))
                            }
                            Text("·")
                                .foregroundStyle(.quaternary)
                            Label {
                                Text(summary.roomName)
                            } icon: {
                                Image(systemName: "door.left.hand.open")
                                    .font(.caption.weight(.semibold))
                            }
                        }
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(.secondary)
                    }
                    Spacer(minLength: 0)
                }

                if !summary.allergies.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    // GDPR: Surface allergies on care screens where food and health judgements are made.
                    HStack(spacing: 8) {
                        Image(systemName: "exclamationmark.shield.fill")
                            .font(.caption.weight(.bold))
                        Text("Allergies on file — \(summary.allergies)")
                            .font(.caption.weight(.semibold))
                    }
                    .foregroundStyle(Color.ncDanger)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 9)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(Color.ncDanger.opacity(0.11))
                    )
                    .overlay {
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .stroke(Color.ncDanger.opacity(0.32), lineWidth: 1)
                    }
                }
            }
            .padding(.leading, 12)
            .padding(.trailing, 16)
            .padding(.vertical, 16)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .ncStudioElevatedSurface(cornerRadius: 22)
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
