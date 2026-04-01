//
//  IncidentListView.swift
//  NurseryConnect
//
//  Feature: Incident Reporting
//  Role: Keyworker
//  Created: 8 April 2026
//  Description: Filterable incident inbox with safeguarding banner and creation entry point.
//
// -----------------------------------------------------------------
// Date       Name        What has done
// -----------------------------------------------------------------
// 080426     Tommy1914   Created the file with segmented control, list rows, and FAB.
// 120426     Tommy1914   Atmosphere backdrop, gradient FAB (list rows unchanged behaviour).
// 120426     Tommy1914   One card per incident row; banner copy deduped per child in view model.
// 130426     Tommy1914   Composer binding from dashboard; fullScreenCover avoids tab-bar overlap.
// 130426     Tommy1914   Futuristic inbox: atmosphere, urgency rails, scope header, row accents, FAB polish.
// -----------------------------------------------------------------

import Combine
import CoreData
import SwiftUI

/// - Description: Lists incidents for the keyworker with quick filters and navigation to detail.
struct IncidentListView: View {
    @Environment(\.managedObjectContext) private var context
    @Environment(\.usesFloatingTabBarShell) private var usesFloatingTabBarShell
    @StateObject private var viewModel: IncidentViewModel
    @Binding var composerPresented: Bool
    @State private var timerToken = Timer.publish(every: 60, on: .main, in: .common).autoconnect()

    init(managedObjectContext: NSManagedObjectContext, composerPresented: Binding<Bool>) {
        _viewModel = StateObject(wrappedValue: IncidentViewModel(context: managedObjectContext))
        _composerPresented = composerPresented
    }

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    if !viewModel.parentNotificationBanners.isEmpty {
                        ForEach(viewModel.parentNotificationBanners) { banner in
                            parentNotificationUrgencyBanner(childFirstName: banner.childFirstName)
                        }
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        HStack(spacing: 8) {
                            Image(systemName: "square.stack.3d.down.right.fill")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: [Color.ncPrimary, Color.cyan.opacity(0.75)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .accessibilityHidden(true)
                            Text("INBOX SCOPE")
                                .font(.caption2.weight(.heavy))
                                .tracking(1.35)
                                .foregroundStyle(.secondary)
                        }
                        .accessibilityHidden(true)

                        Picker("Filter", selection: $viewModel.filter) {
                            ForEach(IncidentListFilter.allCases) { filter in
                                Text(filter.title).tag(filter)
                            }
                        }
                        .pickerStyle(.segmented)
                        .tint(Color.ncPrimary)
                    }

                    if viewModel.incidents.isEmpty {
                        EmptyStateView(
                            symbolName: "shield.lefthalf.filled",
                            title: "No incidents",
                            message: "You have no incidents for this filter."
                        )
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 36)
                    } else {
                        LazyVStack(spacing: 12) {
                            ForEach(viewModel.incidents, id: \.objectID) { incident in
                                NavigationLink {
                                    IncidentDetailView(incident: incident, viewModel: viewModel)
                                } label: {
                                    IncidentRowView(incident: incident)
                                        .padding(.horizontal, 14)
                                        .padding(.vertical, 10)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                        .contentShape(Rectangle())
                                }
                                .buttonStyle(.plain)
                                .background(Color.ncCardSurface)
                                .clipShape(RoundedRectangle(cornerRadius: AppConstants.cardCornerRadius, style: .continuous))
                                .shadow(color: Color.black.opacity(0.07), radius: 12, x: 0, y: 6)
                                .shadow(color: Color.ncPrimary.opacity(0.08), radius: 20, x: 0, y: 10)
                                .overlay {
                                    RoundedRectangle(cornerRadius: AppConstants.cardCornerRadius, style: .continuous)
                                        .stroke(
                                            LinearGradient(
                                                colors: [
                                                    Color.white.opacity(0.65),
                                                    Color.ncPrimary.opacity(0.18),
                                                    Color.cyan.opacity(0.12)
                                                ],
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            ),
                                            lineWidth: 1
                                        )
                                        .allowsHitTesting(false)
                                }
                                .overlay(alignment: .leading) {
                                    RoundedRectangle(cornerRadius: 2, style: .continuous)
                                        .fill(
                                            LinearGradient(
                                                colors: [Color.ncPrimary.opacity(0.95), Color.cyan.opacity(0.45)],
                                                startPoint: .top,
                                                endPoint: .bottom
                                            )
                                        )
                                        .frame(width: 3)
                                        .padding(.vertical, 12)
                                        .padding(.leading, 3)
                                        .allowsHitTesting(false)
                                }
                            }
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
                .padding(.bottom, usesFloatingTabBarShell ? AppConstants.floatingTabBarClearance + 8 : 0)
            }
            .scrollIndicators(.hidden)
            .scrollContentBackground(.hidden)

            Button {
                composerPresented = true
            } label: {
                Image(systemName: "plus")
                    .font(.title2.weight(.semibold))
                    .foregroundStyle(Color.white)
                    .frame(width: 56, height: 56)
                    .background(
                        LinearGradient(
                            colors: [Color.ncPrimary, Color.cyan.opacity(0.82)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .clipShape(RoundedRectangle(cornerRadius: AppConstants.fabCornerRadius, style: .continuous))
                    .overlay {
                        RoundedRectangle(cornerRadius: AppConstants.fabCornerRadius, style: .continuous)
                            .strokeBorder(Color.white.opacity(0.35), lineWidth: 1)
                    }
                    .shadow(color: Color.ncPrimary.opacity(0.28), radius: 16, x: 0, y: 8)
                    .shadow(color: Color.black.opacity(0.16), radius: 12, x: 0, y: 6)
            }
            .padding(.horizontal, 16)
            .padding(.top, 16)
            .padding(.bottom, 16 + (usesFloatingTabBarShell ? AppConstants.floatingTabBarClearance : 0))
            .accessibilityIdentifier(AppConstants.AccessibilityID.addIncidentFAB)
            .accessibilityLabel("New incident")
        }
        .background { incidentAtmosphereBackground }
        .navigationTitle("Incidents")
        .toolbarBackground(Color.ncBackground, for: .navigationBar)
        .fullScreenCover(isPresented: $composerPresented) {
            NewIncidentFormView(viewModel: viewModel)
                .environment(\.managedObjectContext, context)
        }
        .task {
            await viewModel.refresh()
        }
        .onChange(of: viewModel.filter) { _, _ in
            Task { await viewModel.refresh() }
        }
        .onReceive(timerToken) { _ in
            Task { await viewModel.refresh() }
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

    /// Soft depth field behind the inbox (aligned with dashboard atmosphere).
    private var incidentAtmosphereBackground: some View {
        ZStack {
            Color.ncBackground
            Circle()
                .fill(Color.ncPrimary.opacity(0.065))
                .frame(width: 300, height: 300)
                .blur(radius: 65)
                .offset(x: 140, y: -220)
            Circle()
                .fill(Color.cyan.opacity(0.05))
                .frame(width: 240, height: 240)
                .blur(radius: 50)
                .offset(x: -120, y: 40)
        }
        .ignoresSafeArea()
    }

    private func parentNotificationUrgencyBanner(childFirstName: String) -> some View {
        HStack(alignment: .center, spacing: 12) {
            ZStack {
                Circle()
                    .fill(Color.white.opacity(0.2))
                    .frame(width: 38, height: 38)
                Image(systemName: "bell.badge.fill")
                    .font(.body.weight(.semibold))
                    .foregroundStyle(.white)
                    .shadow(color: Color.black.opacity(0.2), radius: 2, x: 0, y: 1)
            }
            Text("Action required: Parent not yet notified of \(childFirstName)’s incident.")
                .font(.footnote.weight(.semibold))
                .foregroundStyle(Color.white)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [Color.ncDanger, Color.ncDanger.opacity(0.78)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .shadow(color: Color.ncDanger.opacity(0.4), radius: 14, x: 0, y: 8)
        }
        .overlay {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(Color.white.opacity(0.22), lineWidth: 1)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Action required: Parent not yet notified of \(childFirstName)’s incident.")
    }
}

#Preview {
    struct IncidentListPreview: View {
        @State private var composer = false
        var body: some View {
            let ctx = PersistenceController.preview.container.viewContext
            NavigationStack {
                IncidentListView(managedObjectContext: ctx, composerPresented: $composer)
            }
            .environment(\.managedObjectContext, ctx)
        }
    }
    return IncidentListPreview()
}
