//
//  KeyworkerDashboardView.swift
//  NurseryConnect
//
//  Feature: Dashboard
//  Role: Keyworker
//  Created: 2 April 2026
//  Description: Top-level tab container with the keyworker greeting and child list navigation.
//
// -----------------------------------------------------------------
// Date       Name        What has done
// -----------------------------------------------------------------
// 020426     Tommy1914   Created the file with tabs, navigation stack, and greeting header.
// 120426     Tommy1914   Loading and empty states for the child grid.
// 120426     Tommy1914   Vertical list of child cards (full width) instead of two-column grid.
// 120426     Tommy1914   Hero header (material + gradient), Today section label, soft top atmosphere.
// 120426     Tommy1914   Refresh child rows when returning to dashboard or switching tabs (diary saves).
// 130426     Tommy1914   Custom glass tab bar without per-tab selection capsule (dual stacks).
// 130426     Tommy1914   Incident composer binding + dismiss when leaving Incidents tab.
// 130426     Tommy1914   Floating tab bar uses `ncBackground` to match dashboard (not material blur).
// 130426     Tommy1914   Dashboard scroll + nav bar flat `ncBackground`; hero card matches child tile surface.
// 130426     Tommy1914   Futuristic dashboard polish: atmosphere orbs, hero snapshot rail, Today capsule.
// 130426     Tommy1914   Root tab shell now uses direct branch switching (avoids blank-screen render glitches).
// 130426     Tommy1914   Manual in-content title for tighter top spacing control.
// 130426     Tommy1914   Greeting tile now updates by real time (message, icon, and date readout).
// -----------------------------------------------------------------

import Combine
import CoreData
import SwiftUI

/// - Description: Root dashboard that launches directly after app start (no authentication UI).
struct KeyworkerDashboardView: View {
    @Environment(\.managedObjectContext) private var context
    @StateObject private var viewModel: KeyworkerDashboardViewModel
    @State private var selectedTab = 0
    @State private var childPath = NavigationPath()
    /// Owned here so tab switches can dismiss the composer; presentation covers the custom tab bar.
    @State private var incidentComposerPresented = false
    @State private var currentDate = Date()

    init(context: NSManagedObjectContext) {
        _viewModel = StateObject(wrappedValue: KeyworkerDashboardViewModel(context: context))
    }

    /// - Description: Same as `init(context:)`; matches common Core Data environment naming.
    init(managedObjectContext: NSManagedObjectContext) {
        self.init(context: managedObjectContext)
    }

    var body: some View {
        ZStack {
            Color.ncBackground.ignoresSafeArea()
            if selectedTab == 0 {
                myChildrenRoot
            } else {
                incidentsRoot
            }
        }
        .animation(.easeInOut(duration: 0.22), value: selectedTab)
        .environment(\.usesFloatingTabBarShell, true)
        .safeAreaInset(edge: .bottom, spacing: 0) {
            glassTabBar
        }
        .task {
            await viewModel.refresh()
        }
        .onReceive(Timer.publish(every: 60, on: .main, in: .common).autoconnect()) { tick in
            currentDate = tick
        }
        .onChange(of: childPath.count) { _, newCount in
            if newCount == 0 {
                Task { await viewModel.reloadChildSummariesFromStore(showLoading: false) }
            }
        }
        .onChange(of: selectedTab) { _, newTab in
            if newTab != 1 {
                incidentComposerPresented = false
            }
            if newTab == 0 {
                Task { await viewModel.reloadChildSummariesFromStore(showLoading: false) }
            }
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

    private var myChildrenRoot: some View {
        NavigationStack(path: $childPath) {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text("Dashboard")
                        .font(.system(size: 38, weight: .bold, design: .rounded))
                        .foregroundStyle(.primary)
                        .padding(.top, 2)
                    dashboardHeroHeader
                    if viewModel.isLoading {
                        ProgressView()
                            .controlSize(.large)
                            .tint(Color.ncPrimary)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 48)
                    } else if viewModel.childSummaries.isEmpty {
                        ContentUnavailableView(
                            "No children to show",
                            systemImage: "figure.child",
                            description: Text("Assigned children appear here after the list loads. Delete and reinstall the app if sample data never appears.")
                        )
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 24)
                    } else {
                        todaySectionLabel(count: viewModel.childSummaries.count)
                        LazyVStack(spacing: 10) {
                            ForEach(viewModel.childSummaries) { summary in
                                Button {
                                    withAnimation(.spring(response: 0.45, dampingFraction: 0.85)) {
                                        childPath.append(summary)
                                    }
                                } label: {
                                    ChildCardView(summary: summary)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                }
                                .buttonStyle(.plain)
                                .accessibilityIdentifier("\(AppConstants.AccessibilityID.childCardPrefix)\(summary.id.uuidString)")
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
                .padding()
            }
            .scrollIndicators(.hidden)
            .scrollContentBackground(.hidden)
            .background { dashboardAtmosphereBackground }
            .toolbarBackground(Color.ncBackground, for: .navigationBar)
            .navigationBarTitleDisplayMode(.inline)
            .navigationDestination(for: KeyworkerChildSummary.self) { summary in
                DailyDiaryListView(summary: summary, managedObjectContext: context)
            }
        }
    }

    private var incidentsRoot: some View {
        NavigationStack {
            IncidentListView(managedObjectContext: context, composerPresented: $incidentComposerPresented)
        }
    }

    private var glassTabBar: some View {
        let corner: CGFloat = 28
        return HStack(spacing: 0) {
            glassTabButton(
                title: "My Children",
                systemImage: "figure.child",
                index: 0,
                accessibilityID: AppConstants.AccessibilityID.myChildrenTab
            )
            glassTabButton(
                title: "Incidents",
                systemImage: "exclamationmark.triangle.fill",
                index: 1,
                accessibilityID: AppConstants.AccessibilityID.incidentsTab
            )
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 6)
        .background(Color.ncBackground, in: RoundedRectangle(cornerRadius: corner, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: corner, style: .continuous)
                .strokeBorder(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(0.35),
                            Color.ncPrimary.opacity(0.22),
                            Color.cyan.opacity(0.15)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 0.5
                )
        }
        .compositingGroup()
        .shadow(color: Color.black.opacity(0.06), radius: 14, x: 0, y: 6)
        .padding(.horizontal, 20)
        .padding(.bottom, 6)
    }

    /// Soft radial “haze” behind the dashboard so it feels less flat than a single flat fill.
    private var dashboardAtmosphereBackground: some View {
        ZStack {
            Color.ncBackground
            Circle()
                .fill(Color.ncPrimary.opacity(0.07))
                .frame(width: 320, height: 320)
                .blur(radius: 70)
                .offset(x: -130, y: -200)
            Circle()
                .fill(Color.cyan.opacity(0.055))
                .frame(width: 260, height: 260)
                .blur(radius: 55)
                .offset(x: 150, y: -120)
            Circle()
                .fill(Color.ncPrimary.opacity(0.04))
                .frame(width: 200, height: 200)
                .blur(radius: 45)
                .offset(x: 40, y: 120)
        }
        .ignoresSafeArea()
    }

    private func glassTabButton(title: String, systemImage: String, index: Int, accessibilityID: String) -> some View {
        let selected = selectedTab == index
        return Button {
            withAnimation(.spring(response: 0.38, dampingFraction: 0.84)) {
                selectedTab = index
            }
        } label: {
            VStack(spacing: 5) {
                Image(systemName: systemImage)
                    .font(.system(size: 21, weight: selected ? .semibold : .regular))
                    .symbolRenderingMode(.monochrome)
                Text(title)
                    .font(.caption2.weight(selected ? .semibold : .medium))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 6)
            .foregroundStyle(selected ? Color.ncPrimary : Color.secondary)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(title)
        .accessibilityAddTraits(selected ? [.isSelected] : [])
        .accessibilityIdentifier(accessibilityID)
    }

    private var dashboardHeroHeader: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 8) {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [Color.green.opacity(0.95), Color.green.opacity(0.35)],
                            center: .center,
                            startRadius: 0,
                            endRadius: 5
                        )
                    )
                    .frame(width: 8, height: 8)
                    .shadow(color: Color.green.opacity(0.45), radius: 4, x: 0, y: 0)
                Text("LIVE SNAPSHOT")
                    .font(.caption2.weight(.heavy))
                    .tracking(1.3)
                    .foregroundStyle(Color.secondary)
            }
            .accessibilityHidden(true)

            HStack(alignment: .top, spacing: 12) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(greetingText)
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(.secondary)
                    Text("\(AppConstants.keyworkerDisplayName) 👋")
                        .font(AppTheme.greetingRounded())
                        .foregroundStyle(
                            LinearGradient(
                                colors: [Color.ncPrimary, Color.cyan.opacity(0.88)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                }
                Spacer(minLength: 0)
                Image(systemName: greetingSymbolName)
                    .font(.title2)
                    .symbolRenderingMode(.palette)
                    .foregroundStyle(greetingPrimaryColor, greetingSecondaryColor)
                    .shadow(color: greetingPrimaryColor.opacity(0.35), radius: 10, x: 0, y: 2)
                    .accessibilityHidden(true)
            }
            VStack(alignment: .leading, spacing: 8) {
                Label {
                    Text(currentDate.formattedMediumDate())
                        .font(.footnote.weight(.medium).monospacedDigit())
                } icon: {
                    Image(systemName: "calendar")
                        .foregroundStyle(Color.ncPrimary)
                }
                .foregroundStyle(.secondary)
                Label {
                    Text(AppConstants.nurseryDisplayName)
                        .fixedSize(horizontal: false, vertical: true)
                } icon: {
                    Image(systemName: "building.2.fill")
                        .foregroundStyle(Color.ncPrimary.opacity(0.85))
                }
                .font(.footnote)
                .foregroundStyle(.secondary)
            }
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background {
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(Color.ncCardSurface)
                .shadow(color: Color.black.opacity(0.07), radius: 14, x: 0, y: 8)
                .shadow(color: Color.ncPrimary.opacity(0.12), radius: 28, x: 0, y: 12)
        }
        .overlay {
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(0.75),
                            Color.ncPrimary.opacity(0.22),
                            Color.cyan.opacity(0.14)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
                .allowsHitTesting(false)
        }
        .overlay(alignment: .top) {
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [Color.white.opacity(0.45), Color.clear],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(height: 56)
                .allowsHitTesting(false)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(
            "\(greetingText) \(AppConstants.keyworkerDisplayName). \(currentDate.formattedMediumDate()). \(AppConstants.nurseryDisplayName)."
        )
    }

    private var greetingText: String {
        let hour = Calendar.current.component(.hour, from: currentDate)
        switch hour {
        case 5..<12: return "Good morning"
        case 12..<17: return "Good afternoon"
        case 17..<22: return "Good evening"
        default: return "Good night"
        }
    }

    private var greetingSymbolName: String {
        let hour = Calendar.current.component(.hour, from: currentDate)
        switch hour {
        case 6..<17: return "sun.max.fill"
        case 17..<20: return "sunset.fill"
        default: return "moon.stars.fill"
        }
    }

    private var greetingPrimaryColor: Color {
        let hour = Calendar.current.component(.hour, from: currentDate)
        switch hour {
        case 6..<17: return Color.orange
        case 17..<20: return Color.purple
        default: return Color.indigo
        }
    }

    private var greetingSecondaryColor: Color {
        let hour = Calendar.current.component(.hour, from: currentDate)
        switch hour {
        case 6..<17: return Color.yellow.opacity(0.75)
        case 17..<20: return Color.pink.opacity(0.7)
        default: return Color.cyan.opacity(0.7)
        }
    }

    private func todaySectionLabel(count: Int) -> some View {
        HStack(alignment: .center, spacing: 10) {
            HStack(spacing: 8) {
                Image(systemName: "waveform.path.ecg")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color.ncPrimary, Color.cyan.opacity(0.75)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .accessibilityHidden(true)
                Text("TODAY")
                    .font(.caption.weight(.heavy))
                    .tracking(1.4)
                    .foregroundStyle(.secondary)
            }
            Spacer(minLength: 8)
            HStack(spacing: 6) {
                Text("\(count)")
                    .font(.caption.weight(.bold).monospacedDigit())
                    .foregroundStyle(Color.ncPrimary)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(
                        Capsule(style: .continuous)
                            .fill(Color.ncPrimary.opacity(0.12))
                    )
                Text("assigned")
                    .font(.caption2.weight(.medium))
                    .foregroundStyle(.tertiary)
            }
        }
        .padding(.top, 4)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Today, \(count) assigned")
    }
}

#Preview {
    KeyworkerDashboardView(context: PersistenceController.preview.container.viewContext)
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
