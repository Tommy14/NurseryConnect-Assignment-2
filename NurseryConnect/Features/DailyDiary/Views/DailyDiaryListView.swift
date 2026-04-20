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
// 140426     Tommy1914   Daily journal makeover: grouped header card, ContentUnavailableView, circular FAB, nav chrome.
// 140426     Tommy1914   Transparent nav bar so top gradient merges with page (no solid strip).
// 140426     Tommy1914   Dossier header shows age only (no gender marker).
// 140426     Tommy1914   Dossier header uses `ncStudioElevatedSurface` (glass on iOS 26).
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
    @StateObject private var attendanceViewModel: AttendanceViewModel
    @State private var addSheet: AddDiarySheet?
    @State private var timelineClock = Date()
    @State private var showCheckInRequiredAlert = false
    @State private var showOutsideDiaryHoursAlert = false
    @State private var showAbsentBlocksDiaryAlert = false
    @State private var isAttendanceCardExpanded = false
    @State private var isSummaryCardExpanded = false
    @State private var hasAutoExpandedForPickupTime = false

    private enum AddDiarySheet: Identifiable {
        case freeform
        case planned(PlannedSessionLogContext)

        var id: String {
            switch self {
            case .freeform: return "add-freeform"
            case .planned(let ctx): return ctx.id
            }
        }
    }

    /// - Description: Creates a diary list bound to the supplied child summary and Core Data context.
    /// - Parameters:
    ///   - summary: Lightweight child metadata from the dashboard.
    ///   - managedObjectContext: Main-queue context shared with the app.
    init(summary: KeyworkerChildSummary, managedObjectContext: NSManagedObjectContext) {
        self.summary = summary
        _viewModel = StateObject(wrappedValue: DailyDiaryViewModel(childID: summary.id, context: managedObjectContext))
        _attendanceViewModel = StateObject(wrappedValue: AttendanceViewModel(childID: summary.id, context: managedObjectContext))
    }

    /// - Description: Diary rows may only be added while the child is checked in, on site, and within nursery diary hours (session open through two hours after closing).
    private var canLogObservations: Bool {
        attendanceViewModel.phase == .onPremises
            && NurseryDaySchedule.isDiaryLoggingPermitted(at: timelineClock, calendar: .current)
    }

    /// - Description: Hides warning surfaces unless the child is currently on site.
    private var shouldShowWarnings: Bool {
        switch attendanceViewModel.phase {
        case .expected, .absent, .departed:
            return false
        case .onPremises:
            return true
        }
    }

    /// - Description: Explains why the empty timeline cannot be filled yet.
    private var emptyStateDescription: String {
        if attendanceViewModel.phase == .absent {
            return "\(summary.firstName) is marked absent today. Tap “Mark as attending” on the attendance card when they arrive, then check them in to add observations."
        }
        if attendanceViewModel.phase != .onPremises {
            return "Check \(summary.firstName) in first. After arrival is recorded, you can add diary observations here when the session window allows."
        }
        if NurseryDaySchedule.isDiaryLoggingPermitted(at: timelineClock, calendar: .current) == false {
            return "Diary logging opens when the nursery session starts and stays available until two hours after closing. Try again during that window."
        }
        return "The timeline shows today’s nursery schedule. Add entries to record \(summary.firstName)’s day."
    }

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    sessionDossierHeader
                    TodayAttendanceCard(
                        firstName: summary.firstName,
                        viewModel: attendanceViewModel,
                        isExpanded: $isAttendanceCardExpanded
                    )
                    DailyDiarySummaryCard(summary: viewModel.dailySummary, isExpanded: $isSummaryCardExpanded)
                    VStack(alignment: .leading, spacing: 10) {
                        if viewModel.entries.isEmpty {
                            ContentUnavailableView {
                                Label("No observations logged yet", systemImage: "calendar.badge.clock")
                            } description: {
                                Text(emptyStateDescription)
                            }
                            .padding(.top, 4)
                        }
                        HStack(spacing: 8) {
                            Image(systemName: "list.bullet.rectangle.fill")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(Color.ncPrimary)
                            Text("Schedule & observations")
                                .font(.caption.weight(.bold))
                                .tracking(0.6)
                                .foregroundStyle(.secondary)
                            Spacer(minLength: 0)
                        }
                        DiaryTimelineView(
                            mergedRows: viewModel.mergedTimelineRows,
                            viewModel: viewModel,
                            now: timelineClock,
                            onLogForPlannedSession: { segment in
                                guard canLogObservations else {
                                    presentLoggingBlockedFeedback()
                                    return
                                }
                                addSheet = .planned(PlannedSessionLogContext(segment: segment, referenceNow: timelineClock))
                            }
                        )
                        .animation(.spring(response: 0.45, dampingFraction: 0.86), value: viewModel.mergedTimelineRows.count)
                    }
                }
                .padding()
                .padding(.bottom, usesFloatingTabBarShell ? AppConstants.floatingTabBarClearance + 8 : 0)
            }
            .scrollIndicators(.hidden)
            .scrollContentBackground(.hidden)

            Button {
                guard canLogObservations else {
                    presentLoggingBlockedFeedback()
                    return
                }
                addSheet = .freeform
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
                    .opacity(canLogObservations ? 1.0 : 0.42)
            }
            .padding(.horizontal, 16)
            .padding(.top, 16)
            .padding(.bottom, 16 + (usesFloatingTabBarShell ? AppConstants.floatingTabBarClearance : 0))
            .accessibilityIdentifier(AppConstants.AccessibilityID.addDiaryFAB)
            .accessibilityLabel("Add diary entry")
            .accessibilityHint(
                canLogObservations
                    ? "Opens the form to log a new diary observation."
                    : (attendanceViewModel.phase == .absent
                        ? "Clear absent status and check the child in before logging."
                        : attendanceViewModel.phase != .onPremises
                        ? "Check the child in on site before logging. Add is unavailable after check-out."
                        : "Diary logging is only available during nursery hours (session start through two hours after closing).")
            )
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
        .sheet(item: $addSheet) { sheet in
            Group {
                switch sheet {
                case .freeform:
                    AddDiaryEntryView(
                        childID: summary.id,
                        viewModel: viewModel,
                        childAllergies: summary.allergies,
                        plannedSessionContext: nil,
                        isDiaryLoggingPermitted: {
                            attendanceViewModel.phase == .onPremises
                                && NurseryDaySchedule.isDiaryLoggingPermitted(at: Date(), calendar: .current)
                        }
                    )
                case .planned(let ctx):
                    AddDiaryEntryView(
                        childID: summary.id,
                        viewModel: viewModel,
                        childAllergies: summary.allergies,
                        plannedSessionContext: ctx,
                        isDiaryLoggingPermitted: {
                            attendanceViewModel.phase == .onPremises
                                && NurseryDaySchedule.isDiaryLoggingPermitted(at: Date(), calendar: .current)
                        }
                    )
                }
            }
            .environment(\.managedObjectContext, context)
            .presentationDetents([.large])
            .presentationDragIndicator(.visible)
        }
        .task {
            await viewModel.loadEntries()
            await attendanceViewModel.load()
            applyInitialCardExpansionState(at: timelineClock)
        }
        .onReceive(Timer.publish(every: 30, on: .main, in: .common).autoconnect()) {
            timelineClock = $0
            autoExpandCardsIfNeeded(at: $0)
        }
        .alert("Something went wrong", isPresented: Binding(
            get: { viewModel.errorMessage != nil || attendanceViewModel.errorMessage != nil },
            set: {
                if !$0 {
                    viewModel.errorMessage = nil
                    attendanceViewModel.errorMessage = nil
                }
            }
        )) {
            Button("OK", role: .cancel) {
                viewModel.errorMessage = nil
                attendanceViewModel.errorMessage = nil
            }
        } message: {
            Text(viewModel.errorMessage ?? attendanceViewModel.errorMessage ?? "")
        }
        .alert("Check in first", isPresented: $showCheckInRequiredAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("Check the child in before logging diary observations. Adding entries is not available before check-in or after check-out.")
        }
        .alert("Outside diary hours", isPresented: $showOutsideDiaryHoursAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("Diary entries can only be added from when the nursery session starts until two hours after closing (local time).")
        }
        .alert("Marked absent", isPresented: $showAbsentBlocksDiaryAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("Use “Mark as attending” on the attendance card if \(summary.firstName) arrives, then check them in before logging diary observations.")
        }
    }

    /// - Description: Routes the correct alert when logging is blocked (attendance vs schedule).
    private func presentLoggingBlockedFeedback() {
        switch attendanceViewModel.phase {
        case .absent:
            return
        case .onPremises:
            showOutsideDiaryHoursAlert = true
        case .expected:
            return
        case .departed:
            showCheckInRequiredAlert = true
        }
    }

    /// Single place for the child’s full name; nav uses screen title instead to avoid repetition.
    private var sessionDossierHeader: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 8) {
                Circle()
                    .fill(sessionStatusDotColor.opacity(0.9))
                    .frame(width: 7, height: 7)
                Text(sessionStatusTitle)
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

            if shouldShowWarnings && summary.hasOpenIncident {
                NavigationLink {
                    ChildProfileView(childId: summary.id, context: context)
                } label: {
                    HStack(spacing: 10) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.body.weight(.semibold))
                            .foregroundStyle(Color.ncDanger)
                        Text("Open incident — review in profile")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.primary)
                            .multilineTextAlignment(.leading)
                        Spacer(minLength: 0)
                        Image(systemName: "chevron.right")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.tertiary)
                    }
                    .padding(12)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.ncDanger.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                }
                .buttonStyle(.plain)
                .accessibilityHint("Opens this child’s profile.")
            }

            if shouldShowWarnings && !summary.allergies.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
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
        .ncStudioElevatedSurface(cornerRadius: 16)
    }

    private var sessionStatusTitle: String {
        switch attendanceViewModel.phase {
        case .departed: return "Checked out"
        case .onPremises: return "On site"
        case .expected: return "Not checked in yet"
        case .absent: return "Absent today"
        }
    }

    private var sessionStatusDotColor: Color {
        switch attendanceViewModel.phase {
        case .departed: return Color.secondary
        case .onPremises: return Color.green
        case .expected: return Color.ncAccentWarm
        case .absent: return Color.ncDanger
        }
    }

    private func applyInitialCardExpansionState(at date: Date) {
        let shouldExpand = shouldAutoExpandCards(at: date)
        isAttendanceCardExpanded = shouldExpand
        isSummaryCardExpanded = shouldExpand
        hasAutoExpandedForPickupTime = shouldExpand
    }

    private func autoExpandCardsIfNeeded(at date: Date) {
        guard shouldAutoExpandCards(at: date), !hasAutoExpandedForPickupTime else { return }
        withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
            isAttendanceCardExpanded = true
            isSummaryCardExpanded = true
        }
        hasAutoExpandedForPickupTime = true
    }

    private func shouldAutoExpandCards(at date: Date) -> Bool {
        let components = Calendar.current.dateComponents([.hour, .minute], from: date)
        guard let hour = components.hour, let minute = components.minute else { return false }
        return hour > 17 || (hour == 17 && minute >= 30)
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
                keyworkerName: "Alex",
                allergies: "Peanuts",
                photoConsent: true,
                dateOfBirth: Date(),
                dot: .complete,
                sleepIntervals: [],
                checkInAt: nil,
                checkOutAt: nil,
                usesAttendanceForActivityLine: false,
                attendanceBucket: .awaiting,
                latestMoodRating: nil,
                hasOpenIncident: false
            ),
            managedObjectContext: ctx
        )
        .environment(\.managedObjectContext, ctx)
    }
}
