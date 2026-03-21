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
// -----------------------------------------------------------------

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

/// - Description: Banner payload when statutory parent follow-up may be overdue.
struct ParentNotificationBanner: Identifiable, Hashable {
    let id: UUID
    let childFirstName: String
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

    // MARK: - Lifecycle

    /// - Description: Creates a view model for the supplied Core Data context.
    /// - Parameters:
    ///   - context: Main-queue managed object context.
    init(context: NSManagedObjectContext) {
        self.context = context
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

    /// - Description: Loads children assigned to the demo keyworker for pickers.
    func loadAssignableChildren() throws {
        let request: NSFetchRequest<Child> = Child.fetchRequest()
        request.predicate = NSPredicate(format: "keyworkerName == %@", AppConstants.keyworkerDisplayName)
        request.sortDescriptors = [NSSortDescriptor(keyPath: \Child.firstName, ascending: true)]
        assignableChildren = try context.fetch(request)
    }

    /// - Description: Suggests whether RIDDOR reporting should be toggled from category alone.
    /// - Parameters:
    ///   - category: Selected incident category.
    /// - Returns: `true` when the category typically triggers statutory reporting review.
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
            await refresh()
        } catch {
            errorMessage = "Unable to update parent notification state."
        }
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
        incidents.compactMap { incident in
            guard let timestamp = incident.timestamp else { return nil }
            let status = IncidentStatus.fromPersistence(incident.status ?? "")
            if status == .draft {
                return nil
            }
            if incident.isParentNotified {
                return nil
            }
            let age = Date().timeIntervalSince(timestamp)
            if age <= AppConstants.parentNotificationWarningThresholdSeconds {
                return nil
            }
            let childName = incident.child?.firstName ?? "Child"
            guard let id = incident.id else { return nil }
            // EYFS: Escalate when timely parent communication has not been recorded.
            return ParentNotificationBanner(id: id, childFirstName: childName)
        }
    }
}
