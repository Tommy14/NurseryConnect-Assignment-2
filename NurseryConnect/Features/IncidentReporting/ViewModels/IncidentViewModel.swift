//
//  IncidentViewModel.swift
//  NurseryConnect
//
//  Feature: Incident Reporting
//  Role: Keyworker
//  Created: 6 April 2026
//  Description: Loads incidents, evaluates EYFS parent-notification risk, and persists updates.
//
// -----------------------------------------------------------------
// Date       Name        What has done
// -----------------------------------------------------------------
// 060426     Tommy1914   Created the file with filters, warnings, and RIDDOR helpers.
// 100426     Tommy1914   One parent-notification banner per child (avoid duplicate rows for same child).
// -----------------------------------------------------------------

import Combine
import CoreData
import Foundation

/// - Description: Time window for incident list segmentation.
enum IncidentListFilter: String, CaseIterable, Identifiable {
    case today
    case week
    case all

    var id: String { rawValue }

    var title: String {
        switch self {
        case .today: return "Today"
        case .week: return "This Week"
        case .all: return "All"
        }
    }
}

/// - Description: Banner payload when statutory parent follow-up may be overdue (one per child).
struct ParentNotificationBanner: Identifiable, Hashable {
    /// Stable per child so multiple qualifying incidents do not duplicate the banner.
    let id: String
    let childFirstName: String
    let message: String
}

/// - Description: Presentation copy for elapsed incident timing and escalation threshold.
struct IncidentEscalationPresentation: Equatable {
    let submittedAtText: String
    let elapsedText: String
    let statusLine: String
    let isEscalationDue: Bool
}

/// - Description: Coordinates incident fetching, filtering, and safeguarding checks.
@MainActor
final class IncidentViewModel: ObservableObject {
    // MARK: - Published State

    @Published private(set) var incidents: [Incident] = []
    @Published var filter: IncidentListFilter = .today
    @Published var errorMessage: String?
    @Published private(set) var parentNotificationBanners: [ParentNotificationBanner] = []
    @Published private(set) var assignableChildren: [Child] = []

    // MARK: - Properties

    private let context: NSManagedObjectContext
    private let syncQueue: SyncQueueService

    // MARK: - Lifecycle

    /// - Description: Creates a view model for the supplied Core Data context.
    /// - Parameters:
    ///   - context: Main-queue managed object context.
    init(context: NSManagedObjectContext, syncQueue: SyncQueueService? = nil) {
        self.context = context
        self.syncQueue = syncQueue ?? .shared
    }

    // MARK: - Public Methods

    /// - Description: Reloads incidents for the keyworker cohort and refreshes compliance banners.
    func refresh() async {
        do {
            try loadAssignableChildren()
            let fetched = try fetchIncidents()
            incidents = filterIncidents(fetched)
            parentNotificationBanners = computeParentNotificationBanners(from: fetched)
        } catch {
            errorMessage = "Could not load incidents."
        }
    }

    /// - Description: Loads on-site children assigned to the demo keyworker for incident pickers.
    func loadAssignableChildren() throws {
        let dayStart = Date().startOfDay
        let request: NSFetchRequest<AttendanceRecord> = AttendanceRecord.fetchRequest()
        request.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [
            NSPredicate(format: "dayStart == %@", dayStart as NSDate),
            NSPredicate(format: "child.keyworkerName == %@", AppConstants.keyworkerDisplayName),
            NSPredicate(format: "checkInAt != nil"),
            NSPredicate(format: "checkOutAt == nil"),
            NSPredicate(format: "markedAbsent == NO")
        ])
        request.sortDescriptors = [NSSortDescriptor(key: "child.firstName", ascending: true)]
        request.relationshipKeyPathsForPrefetching = ["child"]

        let records = try context.fetch(request)
        assignableChildren = records.compactMap(\.child)
    }

    /// - Description: Gates statutory RIDDOR/Ofsted workflow and only returns `true` for serious incidents.
    /// - Parameters:
    ///   - category: Selected incident category.
    /// - Returns: `true` when the selected category is a serious incident.
    func suggestsRiddor(for category: IncidentCategory) -> Bool {
        category.suggestsRiddor
    }

    /// - Description: Persists a newly created incident as submitted to leadership.
    /// - Parameters:
    ///   - incident: Managed object inserted into the context.
    func submit(incident: Incident) async {
        incident.status = IncidentStatus.submitted.persistenceValue
        do {
            try context.save()
            await syncQueue.enqueueIncident(incident)
            await refresh()
        } catch {
            errorMessage = "Unable to submit incident."
        }
    }

    /// - Description: Updates an existing draft incident after edits.
    /// - Parameters:
    ///   - incident: Draft incident to persist.
    func saveDraft(incident: Incident) async {
        do {
            try context.save()
            await syncQueue.enqueueIncident(incident)
            await refresh()
        } catch {
            errorMessage = "Unable to save draft."
        }
    }

    /// - Description: Marks parent notification fields for audit when leadership confirms contact.
    /// - Parameters:
    ///   - incident: Target incident record.
    func markParentNotified(incident: Incident) async {
        incident.isParentNotified = true
        incident.parentNotificationTimestamp = Date()
        incident.status = IncidentStatus.parentNotified.persistenceValue
        do {
            try context.save()
            await syncQueue.enqueueIncident(incident)
            await refresh()
        } catch {
            errorMessage = "Unable to update parent notification state."
        }
    }

    /// - Description: Returns effective queue state for incident sync status badges.
    func syncState(for incident: Incident) -> SyncState {
        SyncState.fromPersistence(incident.syncState)
    }

    /// - Description: Manually retries sync for incidents that failed transport.
    func retrySync(for incident: Incident) async {
        await syncQueue.retryIncident(incident)
        await refresh()
    }

    /// - Description: Builds manager-review/escalation wording for an incident.
    /// - Parameters:
    ///   - incident: Incident to evaluate.
    ///   - referenceDate: Date used as "now" for elapsed calculations.
    /// - Returns: Presentation payload when timing can be computed.
    func escalationPresentation(for incident: Incident, referenceDate: Date = Date()) -> IncidentEscalationPresentation? {
        guard let submittedAt = incident.timestamp else { return nil }
        let elapsedSeconds = max(0, Int(referenceDate.timeIntervalSince(submittedAt)))
        let thresholdSeconds = Int(AppConstants.parentNotificationWarningThresholdSeconds)
        let isDue = elapsedSeconds >= thresholdSeconds

        let submittedAtText = submittedAt.formatted(date: .omitted, time: .shortened)
        let elapsedText = Self.elapsedDurationText(from: elapsedSeconds)
        let thresholdText = Self.elapsedDurationText(from: thresholdSeconds)
        let remainingSeconds = max(0, thresholdSeconds - elapsedSeconds)
        let remainingText = Self.elapsedDurationText(from: remainingSeconds)
        let statusLine = isDue
            ? "Submitted \(elapsedText) ago - escalation due (\(thresholdText) threshold)"
            : "Submitted \(elapsedText) ago - escalation in \(remainingText)"

        return IncidentEscalationPresentation(
            submittedAtText: submittedAtText,
            elapsedText: elapsedText,
            statusLine: statusLine,
            isEscalationDue: isDue
        )
    }

    // MARK: - Private Methods

    /// - Description: Fetches incidents for assigned children only.
    /// - Returns: All matching incidents sorted by newest first.
    private func fetchIncidents() throws -> [Incident] {
        let request: NSFetchRequest<Incident> = Incident.fetchRequest()
        // GDPR: Restrict incident lists to the practitioner’s assigned cohort.
        request.predicate = NSPredicate(format: "child.keyworkerName == %@", AppConstants.keyworkerDisplayName)
        request.sortDescriptors = [NSSortDescriptor(keyPath: \Incident.timestamp, ascending: false)]
        request.relationshipKeyPathsForPrefetching = ["child"]
        return try context.fetch(request)
    }

    /// - Description: Applies the user-selected time filter.
    /// - Parameters:
    ///   - incidents: Full incident array.
    /// - Returns: Filtered incidents.
    private func filterIncidents(_ incidents: [Incident]) -> [Incident] {
        incidents.filter { incident in
            guard let timestamp = incident.timestamp else { return false }
            return isDate(timestamp, in: filter)
        }
    }

    /// - Description: Determines whether a date falls inside the filter window.
    /// - Parameters:
    ///   - date: Incident timestamp.
    ///   - filter: Active list filter.
    /// - Returns: `true` when the incident should be listed.
    private func isDate(_ date: Date, in filter: IncidentListFilter) -> Bool {
        switch filter {
        case .today:
            return date.isSameDay(as: Date())
        case .week:
            let calendar = Calendar.current
            guard let interval = calendar.dateInterval(of: .weekOfYear, for: Date()) else {
                return true
            }
            return date >= interval.start && date < interval.end
        case .all:
            return true
        }
    }

    /// - Description: Builds parent-notification warning banners for statutory follow-up.
    /// - Parameters:
    ///   - incidents: All incidents for the practitioner (unfiltered).
    /// - Returns: Banner models for UI presentation.
    private func computeParentNotificationBanners(from incidents: [Incident]) -> [ParentNotificationBanner] {
        let referenceDate = Date()
        var seenChildObjectIDs = Set<NSManagedObjectID>()
        var banners: [ParentNotificationBanner] = []
        for incident in incidents {
            guard let timestamp = incident.timestamp else { continue }
            let status = IncidentStatus.fromPersistence(incident.status ?? "")
            if status == .draft { continue }
            if incident.isParentNotified { continue }
            let age = referenceDate.timeIntervalSince(timestamp)
            if age <= AppConstants.parentNotificationWarningThresholdSeconds { continue }
            guard let child = incident.child else { continue }
            if seenChildObjectIDs.contains(child.objectID) { continue }
            seenChildObjectIDs.insert(child.objectID)
            let childName = child.firstName ?? "Child"
            let bannerId = child.objectID.uriRepresentation().absoluteString
            guard let timing = escalationPresentation(for: incident, referenceDate: referenceDate) else { continue }
            let message = incident.managerCountersigned
                ? "Awaiting parent notification - submitted at \(timing.submittedAtText). \(timing.statusLine)"
                : "Awaiting manager review - submitted at \(timing.submittedAtText). \(timing.statusLine)"
            banners.append(ParentNotificationBanner(id: bannerId, childFirstName: childName, message: message))
        }
        return banners
    }

    private static func elapsedDurationText(from seconds: Int) -> String {
        let totalMinutes = seconds / 60
        let hours = totalMinutes / 60
        let minutes = totalMinutes % 60
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        }
        return "\(minutes)m"
    }
}
