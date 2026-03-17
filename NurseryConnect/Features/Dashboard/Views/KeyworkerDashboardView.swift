//
//  KeyworkerDashboardView.swift
//  NurseryConnect
//
//  Feature: Dashboard
//  Role: Keyworker
//  Created: 2 April 2026
//  Description: Top-level tab container with the keyworker greeting and child grid navigation.
//
// -----------------------------------------------------------------
// Date       Name        What has done
// -----------------------------------------------------------------
// 020426     Tommy1914   Created the file with tabs, navigation stack, and greeting header.
// -----------------------------------------------------------------

import CoreData
import SwiftUI

/// - Description: Root dashboard that launches directly after app start (no authentication UI).
struct KeyworkerDashboardView: View {
    @Environment(\.managedObjectContext) private var context
    @StateObject private var viewModel: KeyworkerDashboardViewModel
    @State private var selectedTab = 0
    @State private var childPath = NavigationPath()

    init(context: NSManagedObjectContext) {
        _viewModel = StateObject(wrappedValue: KeyworkerDashboardViewModel(context: context))
    }

    var body: some View {
        TabView(selection: $selectedTab) {
            NavigationStack(path: $childPath) {
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        greetingHeader
                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                            ForEach(viewModel.childSummaries) { summary in
                                Button {
                                    withAnimation(.spring(response: 0.45, dampingFraction: 0.85)) {
                                        childPath.append(summary)
                                    }
                                } label: {
                                    ChildCardView(summary: summary)
                                }
                                .buttonStyle(.plain)
                                .accessibilityIdentifier("\(AppConstants.AccessibilityID.childCardPrefix)\(summary.id.uuidString)")
                            }
                        }
                    }
                    .padding()
                }
                .background(Color.ncBackground.ignoresSafeArea())
                .navigationTitle("Dashboard")
                .navigationDestination(for: KeyworkerChildSummary.self) { summary in
                    DailyDiaryListView(summary: summary, managedObjectContext: context)
                }
            }
            .tabItem {
                Label("My Children", systemImage: "figure.child")
            }
            .tag(0)
            .accessibilityIdentifier(AppConstants.AccessibilityID.myChildrenTab)

            NavigationStack {
                IncidentListView()
            }
            .tabItem {
                Label("Incidents", systemImage: "exclamationmark.triangle.fill")
            }
            .tag(1)
            .accessibilityIdentifier(AppConstants.AccessibilityID.incidentsTab)
        }
        .tint(Color.ncPrimary)
        .animation(.easeInOut(duration: 0.2), value: selectedTab)
        .task {
            await viewModel.refresh()
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

    private var greetingHeader: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Good morning, \(AppConstants.keyworkerDisplayName) 👋")
                .font(AppTheme.greetingRounded())
                .foregroundStyle(Color.primary)
            Text(Date().formattedMediumDate())
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Text(AppConstants.nurseryDisplayName)
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
    }
}

#Preview {
    KeyworkerDashboardView(context: PersistenceController.preview.container.viewContext)
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
