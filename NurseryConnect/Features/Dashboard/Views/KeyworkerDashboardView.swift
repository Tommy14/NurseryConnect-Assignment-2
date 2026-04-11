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
// 100426     Tommy1914   Loading and empty states for the child grid.
// 100426     Tommy1914   Vertical list of child cards (full width) instead of two-column grid.
// 100426     Tommy1914   Hero header (material + gradient), Today section label, soft top atmosphere.
// 100426     Tommy1914   Refresh child rows when returning to dashboard or switching tabs (diary saves).
// 100426     Tommy1914   Custom glass tab bar without per-tab selection capsule (dual stacks).
// 100426     Tommy1914   Incident composer binding + dismiss when leaving Incidents tab.
// 100426     Tommy1914   Floating tab bar uses `ncBackground` to match dashboard (not material blur).
// 100426     Tommy1914   Dashboard scroll + nav bar flat `ncBackground`; hero card matches child tile surface.
// 100426     Tommy1914   Futuristic dashboard polish: atmosphere orbs, hero snapshot rail, Today capsule.
// 100426     Tommy1914   Root tab shell now uses direct branch switching (avoids blank-screen render glitches).
// 100426     Tommy1914   Manual in-content title for tighter top spacing control.
// 100426     Tommy1914   Greeting tile now updates by real time (message, icon, and date readout).
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
    @State private var childSearchText = ""

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
                        .padding(.top, 0)
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
                        todaySectionLabel(count: filteredChildSummaries.count)
                        dashboardSearchField
                        LazyVStack(spacing: 10) {
                            ForEach(filteredChildSummaries) { summary in
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
                .padding(.horizontal)
                .padding(.bottom, AppConstants.floatingTabBarClearance + 12)
                .padding(.top, 8)
            }
            .scrollIndicators(.hidden)
            .scrollContentBackground(.hidden)
            .background { dashboardAtmosphereBackground }
            .navigationBarTitleDisplayMode(.inline)
            .navigationDestination(for: KeyworkerChildSummary.self) { summary in
                DailyDiaryListView(summary: summary, managedObjectContext: context)
            }
        }
    }

    private var dashboardSearchField: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(.secondary)
            TextField("Search children", text: $childSearchText)
                .textInputAutocapitalization(.words)
                .autocorrectionDisabled()
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color.ncCardSurface)
        )
        .overlay {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(Color.secondary.opacity(0.15), lineWidth: 1)
        }
    }

    private var filteredChildSummaries: [KeyworkerChildSummary] {
        let query = childSearchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard query.isEmpty == false else { return viewModel.childSummaries }
        return viewModel.childSummaries.filter { summary in
            let fullName = "\(summary.firstName) \(summary.lastName)"
            let ageText = Date.earlyYearsAgeDescription(dateOfBirth: summary.dateOfBirth)
            return fullName.localizedCaseInsensitiveContains(query)
                || summary.roomName.localizedCaseInsensitiveContains(query)
                || ageText.localizedCaseInsensitiveContains(query)
        }
    }

    private var assignedRoomName: String {
        let firstNonEmpty = viewModel.childSummaries
            .map(\.roomName)
            .first { $0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false }
        return firstNonEmpty ?? "Unassigned room"
    }

    private var incidentsRoot: some View {
        NavigationStack {
            IncidentListView(managedObjectContext: context, composerPresented: $incidentComposerPresented)
        }
    }

    private var glassTabBar: some View {
        let corner: CGFloat = 24
        return HStack(spacing: 0) {
            glassTabButton(
                title: "Children",
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
        .padding(.vertical, 8)
        .padding(.horizontal, 8)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: corner, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: corner, style: .continuous)
                .strokeBorder(Color.white.opacity(0.35), lineWidth: 0.8)
        }
        .compositingGroup()
        .shadow(color: Color.black.opacity(0.1), radius: 12, x: 0, y: 6)
        .padding(.horizontal, 18)
        .padding(.bottom, 8)
    }

    /// Soft radial “haze” behind the dashboard so it feels less flat than a single flat fill.
    private var dashboardAtmosphereBackground: some View {
        ZStack {
            Color.ncBackground
            Circle()
                .fill(Color.ncGlowBlue.opacity(0.13))
                .frame(width: 320, height: 320)
                .blur(radius: 70)
                .offset(x: -130, y: -210)
            Circle()
                .fill(Color.ncGlowViolet.opacity(0.11))
                .frame(width: 280, height: 280)
                .blur(radius: 62)
                .offset(x: 150, y: -120)
            Circle()
                .fill(Color.ncPrimary.opacity(0.08))
                .frame(width: 200, height: 200)
                .blur(radius: 40)
                .offset(x: 40, y: 150)
        }
        .ignoresSafeArea()
    }

    private func glassTabButton(title: String, systemImage: String, index: Int, accessibilityID: String) -> some View {
        let selected = selectedTab == index
        let selectedTint = selectedTabTint(for: index)
        return Button {
            withAnimation(.spring(response: 0.38, dampingFraction: 0.84)) {
                selectedTab = index
            }
        } label: {
            VStack(spacing: 5) {
                Image(systemName: systemImage)
                    .font(.system(size: 20, weight: selected ? .semibold : .regular))
                    .symbolRenderingMode(.hierarchical)
                Text(title)
                    .font(.caption2.weight(selected ? .semibold : .regular))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 6)
            .foregroundStyle(selected ? selectedTint : Color.secondary)
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(selected ? selectedTint.opacity(0.14) : Color.clear)
            )
            .overlay {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(selected ? selectedTint.opacity(0.42) : Color.clear, lineWidth: 0.8)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(title)
        .accessibilityAddTraits(selected ? [.isSelected] : [])
        .accessibilityIdentifier(accessibilityID)
    }

    private func selectedTabTint(for index: Int) -> Color {
        switch index {
        case 0: return Color.blue
        case 1: return Color.orange
        default: return Color.ncPrimary
        }
    }

    private var dashboardHeroHeader: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .center, spacing: 12) {
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
                Spacer(minLength: 8)
                HStack(spacing: 8) {
                    Image(systemName: "calendar")
                        .foregroundStyle(Color.ncPrimary)
                    Text(currentDate.formattedMediumDate())
                        .font(.footnote.weight(.medium).monospacedDigit())
                        .foregroundStyle(.secondary)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(
                    Capsule(style: .continuous)
                        .fill(Color.ncPrimary.opacity(0.08))
                )
            }

            HStack(alignment: .center, spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(greetingText)
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(.secondary)
                    Text(AppConstants.keyworkerDisplayName)
                        .font(AppTheme.greetingRounded())
                        .foregroundStyle(
                            LinearGradient(
                                colors: [Color.ncPrimary, Color.ncGlowBlue],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                }
                Spacer(minLength: 0)
                Image(systemName: greetingSymbolName)
                    .font(.system(size: 34, weight: .semibold))
                    .symbolRenderingMode(.palette)
                    .foregroundStyle(greetingPrimaryColor, greetingSecondaryColor)
                    .padding(8)
                    .background(
                        Circle()
                            .fill(greetingPrimaryColor.opacity(0.1))
                    )
                    .shadow(color: greetingPrimaryColor.opacity(0.35), radius: 12, x: 0, y: 3)
                    .offset(x: -10)
                    .accessibilityHidden(true)
            }

            HStack(spacing: 8) {
                Image(systemName: "door.left.hand.open")
                    .foregroundStyle(Color.ncPrimary.opacity(0.85))
                Text(assignedRoomName)
                    .font(.footnote.weight(.medium))
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background {
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(Color.ncCardSurface)
                .shadow(color: Color.black.opacity(0.07), radius: 14, x: 0, y: 8)
                .shadow(color: Color.ncPrimary.opacity(0.14), radius: 20, x: 0, y: 10)
        }
        .overlay(alignment: .bottomTrailing) {
            ZStack {
                Circle()
                    .fill(Color.ncGlowBlue.opacity(0.13))
                    .frame(width: 140, height: 140)
                    .blur(radius: 24)
                Circle()
                    .fill(Color.ncGlowViolet.opacity(0.11))
                    .frame(width: 100, height: 100)
                    .blur(radius: 18)
                    .offset(x: -18, y: -16)
            }
            .offset(x: 24, y: 26)
            .allowsHitTesting(false)
        }
        .overlay {
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(
                    LinearGradient(
                        colors: [Color.white.opacity(0.65), Color.ncPrimary.opacity(0.22), Color.ncGlowBlue.opacity(0.18)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
                .allowsHitTesting(false)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(
            "\(greetingText) \(AppConstants.keyworkerDisplayName). \(currentDate.formattedMediumDate()). Room: \(assignedRoomName)."
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
                    .foregroundStyle(Color.ncPrimary)
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
