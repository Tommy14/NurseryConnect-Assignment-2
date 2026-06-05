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
// 100426     Tommy1914   Atmosphere backdrop, gradient FAB (list rows unchanged behaviour).
// 100426     Tommy1914   One card per incident row; banner copy deduped per child in view model.
// 100426     Tommy1914   Composer binding from dashboard; fullScreenCover avoids tab-bar overlap.
// 100426     Tommy1914   Futuristic inbox: atmosphere, urgency rails, scope header, row accents, FAB polish.
// 100426     Tommy1914   Category-tinted row surfaces and rails for clearer incident-type contrast.
// 100426     Tommy1914   Manual in-content title for tighter top spacing alignment with dashboard.
// 140426     Tommy1914   System large nav title “Incidents” (matches children list behaviour).
// 140426     Tommy1914   iOS 26: soft top scroll edge for nav legibility with Liquid Glass.
// 140426     Tommy1914   Row backgrounds via `NCLiquidGlassChrome.incidentRowBackground`.
// -----------------------------------------------------------------

import Combine
import CoreData
import SwiftUI

/// - Description: Lists incidents for the keyworker with quick filters and navigation to detail.
struct IncidentListView: View {
    @Environment(\.managedObjectContext) private var context
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(\.usesFloatingTabBarShell) private var usesFloatingTabBarShell
    @StateObject private var viewModel: IncidentViewModel
    @Binding var composerPresented: Bool
    @State private var timerToken = Timer.publish(every: 60, on: .main, in: .common).autoconnect()

    init(managedObjectContext: NSManagedObjectContext, composerPresented: Binding<Bool>) {
        _viewModel = StateObject(wrappedValue: IncidentViewModel(context: managedObjectContext))
        _composerPresented = composerPresented
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                if !viewModel.parentNotificationBanners.isEmpty {
                    ForEach(viewModel.parentNotificationBanners) { banner in
                        parentNotificationUrgencyBanner(childDisplayName: banner.childDisplayName, message: banner.message)
                    }
                }

                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 8) {
                        Image(systemName: "square.stack.3d.down.right.fill")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [Color.ncPrimary, Color.ncGlowBlue.opacity(0.82)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .accessibilityHidden(true)
                        Text("INBOX SCOPE")
                            .ncSectionOverlineStyle()
                    }
                    .accessibilityHidden(true)

                    Picker("Filter", selection: $viewModel.filter) {
                        ForEach(IncidentListFilter.allCases) { filter in
                            Text(filter.title).tag(filter)
                        }
                    }
                    .pickerStyle(.segmented)
                    .tint(Color.ncPrimary)
                    .animation(.spring(response: 0.35, dampingFraction: 0.85), value: viewModel.filter)
                }

                complianceHighlightTile(text: ComplianceContent.incidentListComplianceNote)

                if viewModel.incidents.isEmpty {
                    EmptyStateView(
                        symbolName: "shield.lefthalf.filled",
                        title: "No incidents",
                        message: "You have no incidents for this filter.",
                        actionTitle: "Log Incident",
                        action: { composerPresented = true }
                    )
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 36)
                    .transition(.opacity.combined(with: .scale(scale: 0.96)))
                } else {
                    LazyVStack(spacing: 12) {
                        ForEach(viewModel.incidents, id: \.objectID) { incident in
                            NavigationLink {
                                IncidentDetailView(incident: incident, viewModel: viewModel)
                            } label: {
                                IncidentRowView(incident: incident)
                                    .padding(.horizontal, 14)
                                    .padding(.vertical, 12)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .contentShape(Rectangle())
                            }
                            .buttonStyle(.plain)
                            .background(
                                RoundedRectangle(cornerRadius: AppConstants.cardCornerRadius, style: .continuous)
                                    .fill(Color.ncCardSurface)
                            )
                            .clipShape(RoundedRectangle(cornerRadius: AppConstants.cardCornerRadius, style: .continuous))
                            .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 4)
                            .overlay {
                                RoundedRectangle(cornerRadius: AppConstants.cardCornerRadius, style: .continuous)
                                    .stroke(Color.secondary.opacity(0.12), lineWidth: 1)
                                    .allowsHitTesting(false)
                            }
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal)
            .padding(.bottom)
            .padding(.top, 8)
            .padding(.bottom, usesFloatingTabBarShell ? 100 : 80)
        }
        .scrollIndicators(.hidden)
        .scrollContentBackground(.hidden)
        .ncRootScrollEdgeEffectForTopNavigation()
        .refreshable { await viewModel.refresh() }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            HStack {
                Spacer()
                Button {
                    composerPresented = true
                } label: {
                    Image(systemName: "plus")
                        .font(.title2.weight(.semibold))
                        .foregroundStyle(.white)
                        .frame(width: 56, height: 56)
                        .background(Color.ncPrimary, in: Circle())
                        .shadow(color: Color.ncPrimary.opacity(0.35), radius: 12, x: 0, y: 6)
                        .shadow(color: Color.black.opacity(0.12), radius: 4, x: 0, y: 2)
                }
                .accessibilityLabel("New Incident")
                .accessibilityIdentifier(AppConstants.AccessibilityID.addIncidentFAB)
                .keyboardShortcut("n", modifiers: .command)
                .padding(.trailing, 24)
                .padding(.bottom, usesFloatingTabBarShell ? 88 : 24)
                .padding(.top, 8)
            }
        }
        .ncStudioScreenBackdrop()
        .navigationTitle(AppConstants.navTitleKeyworkerIncidentsList)
        .navigationBarTitleDisplayMode(.large)
        .fullScreenCover(isPresented: fullScreenComposerPresented) {
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

    private var usesOverlayComposer: Bool {
        horizontalSizeClass == .regular
    }

    private var fullScreenComposerPresented: Binding<Bool> {
        Binding(
            get: { composerPresented && !usesOverlayComposer },
            set: { composerPresented = $0 }
        )
    }

    private func parentNotificationUrgencyBanner(childDisplayName: String, message: String) -> some View {
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
            Text(message)
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
                .shadow(color: Color.ncDanger.opacity(0.35), radius: 12, x: 0, y: 6)
        }
        .overlay {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(Color.ncGlassHighlight(lightOpacity: 0.22), lineWidth: 1)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(childDisplayName) incident alert. \(message)")
    }

    private func complianceHighlightTile(text: String) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "shield.lefthalf.filled")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Color.ncPrimary)
                .accessibilityHidden(true)
            Text(text)
                .font(.footnote.weight(.medium))
                .foregroundStyle(.primary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            LinearGradient(
                colors: [
                    Color.ncPrimary.opacity(0.14),
                    Color.ncGlowBlue.opacity(0.08),
                    Color.ncGlassHighlight(lightOpacity: 0.28)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(
                    LinearGradient(
                        colors: [
                            Color.ncGlassHighlight(lightOpacity: 0.7),
                            Color.ncPrimary.opacity(0.18),
                            Color.ncGlowBlue.opacity(0.16)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
                .allowsHitTesting(false)
        }
        .overlay(alignment: .top) {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            Color.ncGlassHighlight(lightOpacity: 0.42),
                            Color.clear
                        ],
                        startPoint: .top,
                        endPoint: .center
                    )
                )
                .padding(1)
                .allowsHitTesting(false)
        }
        .shadow(color: Color.ncPrimary.opacity(0.12), radius: 8, x: 0, y: 4)
        .accessibilityElement(children: .combine)
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
