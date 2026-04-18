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
// 140426     Tommy1914   Native large nav title → compact centered “Dashboard” when scrolling.
// 140426     Tommy1914   No solid toolbar override; rely on global scroll-edge vs standard translucency.
// 140426     Tommy1914   Inline nav title + hidden toolbar: removes large-title gap; bar stays see-through.
// 140426     Tommy1914   Scroll offset: big in-content “Dashboard” at top; compact nav title when scrolled.
// 140426     Tommy1914   Top scroll sentinel + hysteresis so compact+frosted bar tracks scroll reliably.
// 140426     Tommy1914   Top safe-area padding when large title visible (empty nav bar would draw under notch).
// 140426     Tommy1914   System large nav title only (no duplicate in-scroll title / manual top inset).
// 140426     Tommy1914   Nav title “Children” (leading large title; matches tab naming).
// 140426     Tommy1914   Inline nav title to remove extra space above “Children” (no large-title band).
// 140426     Tommy1914   Large title “Children” at top; transparent bar + centered title when scrolled.
// 140426     Tommy1914   iOS 26: Liquid Glass tab bar + nav chrome; legacy ultra-thin material on older OS.
// 140426     Tommy1914   Iconic liquid glass dock (`KeyworkerSectionTabBar`): sliding lens + specular rim.
// 140426     Tommy1914   Section tab bar extracted to `KeyworkerSectionTabBar` (dock + sliding glass lens).
// 140426     Tommy1914   Hero header uses `ncStudioElevatedSurface` (liquid glass plate on iOS 26).
// 140426     Tommy1914   Selecting Children tab clears `childPath` (root list from any depth / other tab).
// 150426     Tommy1914   Trailing profile toolbar opens keyworker profile sheet.
// 160426     Tommy1914   Leading toolbar brand mark (`NurseryConnectNavLogo`).
// 160426     Tommy1914   Nav logo shown as plain image (no rounded clip / crop).
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
    @State private var isKeyworkerProfilePresented = false
    @State private var quickCheckInSummary: KeyworkerChildSummary?

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
            KeyworkerSectionTabBar(selectedIndex: $selectedTab) { index in
                if index == 0 {
                    childPath = NavigationPath()
                }
            }
        }
        .task {
            await viewModel.refresh()
            await KeyworkerMoodReminderScheduler.registerHourlyMoodRemindersDuringSession()
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
                childPath = NavigationPath()
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
                        LazyVStack(spacing: 12) {
                            ForEach(KeyworkerAttendanceBucket.dashboardSectionOrder, id: \.self) { bucket in
                                let rows = filteredChildSummaries
                                    .filter { $0.attendanceBucket == bucket }
                                    .sorted { $0.firstName < $1.firstName }
                                if rows.isEmpty == false {
                                    Text(bucket.sectionTitle)
                                        .font(.caption.weight(.heavy))
                                        .foregroundStyle(.secondary)
                                        .textCase(.uppercase)
                                        .tracking(0.85)
                                        .frame(maxWidth: .infinity, alignment: .leading)

                                    ForEach(rows) { summary in
                                        Button {
                                            switch summary.attendanceBucket {
                                            case .awaiting:
                                                quickCheckInSummary = summary
                                            case .onSite, .absent, .departed:
                                                withAnimation(.spring(response: 0.45, dampingFraction: 0.85)) {
                                                    childPath.append(summary)
                                                }
                                            }
                                        } label: {
                                            ChildCardView(summary: summary, currentDate: currentDate)
                                                .frame(maxWidth: .infinity, alignment: .leading)
                                        }
                                        .id(summary.dashboardRowIdentity)
                                        .buttonStyle(.plain)
                                        .accessibilityIdentifier("\(AppConstants.AccessibilityID.childCardPrefix)\(summary.id.uuidString)")
                                    }
                                }
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
                .padding(.horizontal)
                .padding(.bottom, AppConstants.floatingTabBarClearance + 12)
            }
            .scrollIndicators(.hidden)
            .scrollContentBackground(.hidden)
            .ncRootScrollEdgeEffectForTopNavigation()
            .background { dashboardAtmosphereBackground }
            .navigationTitle(AppConstants.navTitleKeyworkerChildrenList)
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Image("NurseryConnectNavLogo")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 36, height: 36)
                        .accessibilityLabel("NurseryConnect")
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        isKeyworkerProfilePresented = true
                    } label: {
                        Image(systemName: "person.crop.circle.fill")
                            .font(.body.weight(.medium))
                            .foregroundStyle(Color.ncPrimary)
                    }
                    .accessibilityLabel("My profile")
                    .accessibilityIdentifier(AppConstants.AccessibilityID.keyworkerProfileButton)
                }
            }
            .sheet(isPresented: $isKeyworkerProfilePresented) {
                NavigationStack {
                    KeyworkerProfileView(assignedRoomName: assignedRoomName)
                }
            }
            .sheet(item: $quickCheckInSummary) { summary in
                DashboardQuickCheckInSheet(
                    summary: summary,
                    context: context,
                    onSuccess: {
                        let childID = summary.id
                        quickCheckInSummary = nil
                        Task {
                            await Task.yield()
                            await viewModel.reloadChildSummariesFromStore(showLoading: false)
                            let updated = viewModel.childSummaries.first { $0.id == childID }
                            if let updated {
                                withAnimation(.spring(response: 0.45, dampingFraction: 0.85)) {
                                    childPath.append(updated)
                                }
                            }
                        }
                    },
                    onCancel: { quickCheckInSummary = nil }
                )
            }
            .navigationDestination(for: KeyworkerChildSummary.self) { summary in
                DailyDiaryListView(summary: summary, managedObjectContext: context)
            }
        }
    }

    private var dashboardSearchField: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(.secondary)
            TextField("Search My Children", text: $childSearchText)
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
                VStack(alignment: .leading, spacing: 6) {
                    Text(greetingText)
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(.secondary)
                    Text(assignedRoomName)
                        .font(AppTheme.greetingRounded())
                        .foregroundStyle(
                            LinearGradient(
                                colors: [Color.ncPrimary, Color.ncGlowBlue],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .lineLimit(2)
                        .minimumScaleFactor(0.85)
                    Text(AppConstants.keyworkerDisplayName)
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(.secondary)
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
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .ncStudioElevatedSurface(cornerRadius: 22)
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
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(
            "\(greetingText). \(assignedRoomName). \(AppConstants.keyworkerDisplayName). \(currentDate.formattedMediumDate())."
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

// MARK: - Dashboard quick check-in

/// - Description: Sheet shown when a child card is tapped before check-in: captures drop-off name only; arrival time is `Date()` at save.
private struct DashboardQuickCheckInSheet: View {
    let summary: KeyworkerChildSummary
    let context: NSManagedObjectContext
    let onSuccess: () -> Void
    let onCancel: () -> Void

    @StateObject private var attendanceViewModel: AttendanceViewModel
    @State private var droppedOffBy = ""

    init(summary: KeyworkerChildSummary, context: NSManagedObjectContext, onSuccess: @escaping () -> Void, onCancel: @escaping () -> Void) {
        self.summary = summary
        self.context = context
        self.onSuccess = onSuccess
        self.onCancel = onCancel
        _attendanceViewModel = StateObject(wrappedValue: AttendanceViewModel(childID: summary.id, context: context))
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Full name", text: $droppedOffBy)
                        .textInputAutocapitalization(.words)
                } header: {
                    Text("Who dropped \(summary.firstName) off?")
                } footer: {
                    Text("Arrival time is saved automatically as the current time.")
                }
            }
            .navigationTitle("Check in")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel", action: onCancel)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        Task {
                            await attendanceViewModel.checkIn(at: Date(), droppedOffBy: droppedOffBy)
                            if attendanceViewModel.errorMessage == nil {
                                onSuccess()
                            }
                        }
                    }
                    .fontWeight(.semibold)
                    .accessibilityIdentifier(AppConstants.AccessibilityID.dashboardQuickCheckInSave)
                }
            }
        }
        .presentationDragIndicator(.visible)
        .task {
            await attendanceViewModel.load()
        }
        .alert("Check-in", isPresented: Binding(
            get: { attendanceViewModel.errorMessage != nil },
            set: { if !$0 { attendanceViewModel.errorMessage = nil } }
        )) {
            Button("OK", role: .cancel) { attendanceViewModel.errorMessage = nil }
        } message: {
            Text(attendanceViewModel.errorMessage ?? "")
        }
    }
}

#Preview {
    KeyworkerDashboardView(context: PersistenceController.preview.container.viewContext)
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
