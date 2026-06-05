//
//  EndOfDaySummaryBuilder.swift
//  NurseryConnect
//
//  Feature: Messages
//  Role: Keyworker
//  Created: 29 May 2026
//  Description: Builds pre-populated end-of-day summary text from today's diary and incidents.
//

import CoreData
import Foundation

/// - Description: Pre-populated end-of-day summary for parent messaging.
struct EndOfDaySummaryDraft {
    var text: String
}

/// - Description: Reads Core Data directly to compose an editable end-of-day summary.
enum EndOfDaySummaryBuilder {
    /// - Description: Builds summary text for a child on the current calendar day.
    static func build(childID: UUID, in context: NSManagedObjectContext) throws -> EndOfDaySummaryDraft {
        let child = try fetchChild(id: childID, in: context)
        let displayName = childDisplayName(child)
        let start = Date().startOfDay
        let end = Date().endOfDay
        let entries = try fetchTodayDiaryEntries(childID: childID, start: start, end: end, in: context)
        let hasOpenIncident = try hasOpenIncidentToday(childID: childID, start: start, end: end, in: context)

        var lines: [String] = []
        lines.append("End of day summary for \(displayName)")
        lines.append("")

        let wellbeing = entries.filter { DiaryEntryType.fromPersistence($0.entryType ?? "") == .wellbeing }
            .sorted { ($0.timestamp ?? .distantPast) < ($1.timestamp ?? .distantPast) }
        if let arrival = wellbeing.first, Int(arrival.moodRating) > 0 {
            lines.append("Mood at arrival: \(moodLabel(Int(arrival.moodRating)))")
        }
        if wellbeing.count > 1, let departure = wellbeing.last, Int(departure.moodRating) > 0 {
            lines.append("Mood at departure: \(moodLabel(Int(departure.moodRating)))")
        } else if wellbeing.count == 1, Int(wellbeing[0].moodRating) > 0 {
            lines.append("Mood today: \(moodLabel(Int(wellbeing[0].moodRating)))")
        }

        let meals = entries.filter { DiaryEntryType.fromPersistence($0.entryType ?? "") == .meal }
        if !meals.isEmpty {
            lines.append("")
            lines.append("Meals:")
            for meal in meals {
                let food = meal.mealDescription?.trimmingCharacters(in: .whitespacesAndNewlines) ?? "Meal"
                let portion = meal.mealConsumed?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
                let portionText = portion.isEmpty ? "logged" : portion
                lines.append("• \(food) — \(portionText)")
            }
        }

        let sleepEntries = entries.filter { DiaryEntryType.fromPersistence($0.entryType ?? "") == .sleep }
        let totalSleepMinutes = sleepEntries.reduce(0) { $0 + max(Int($1.duration), 0) }
        if totalSleepMinutes > 0 {
            let hours = totalSleepMinutes / 60
            let minutes = totalSleepMinutes % 60
            let sleepText: String
            if hours > 0 && minutes > 0 {
                sleepText = "\(hours)h \(minutes)m"
            } else if hours > 0 {
                sleepText = "\(hours) hour\(hours == 1 ? "" : "s")"
            } else {
                sleepText = "\(minutes) minutes"
            }
            lines.append("")
            lines.append("Sleep today: \(sleepText)")
        }

        let activities = entries.filter { DiaryEntryType.fromPersistence($0.entryType ?? "") == .activity }
        if !activities.isEmpty {
            lines.append("")
            lines.append("Activities: \(activities.count) logged")
            let highlights = activities.prefix(3)
            for activity in highlights {
                let type = activity.activityType?.trimmingCharacters(in: .whitespacesAndNewlines) ?? "Activity"
                let note = activity.notes?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
                if note.isEmpty {
                    lines.append("• \(type)")
                } else {
                    lines.append("• \(type) — \(note)")
                }
            }
        }

        if hasOpenIncident {
            lines.append("")
            lines.append(AppConstants.endOfDaySummaryIncidentNotice)
        }

        lines.append("")
        lines.append("Kind regards,")
        lines.append(AppConstants.keyworkerDisplayName)

        return EndOfDaySummaryDraft(text: lines.joined(separator: "\n"))
    }

    private static func fetchChild(id: UUID, in context: NSManagedObjectContext) throws -> Child {
        let request: NSFetchRequest<Child> = Child.fetchRequest()
        request.fetchLimit = 1
        request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
        guard let child = try context.fetch(request).first else {
            throw MessagingError.childNotInCohort
        }
        return child
    }

    private static func childDisplayName(_ child: Child) -> String {
        let full = child.fullDisplayName
        return full == "Child" ? "your child" : full
    }

    private static func fetchTodayDiaryEntries(
        childID: UUID,
        start: Date,
        end: Date,
        in context: NSManagedObjectContext
    ) throws -> [DiaryEntry] {
        let request: NSFetchRequest<DiaryEntry> = DiaryEntry.fetchRequest()
        request.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [
            NSPredicate(format: "child.id == %@", childID as CVarArg),
            NSPredicate(format: "timestamp >= %@", start as NSDate),
            NSPredicate(format: "timestamp < %@", end as NSDate)
        ])
        request.sortDescriptors = [NSSortDescriptor(keyPath: \DiaryEntry.timestamp, ascending: true)]
        return try context.fetch(request)
    }

    private static func hasOpenIncidentToday(
        childID: UUID,
        start: Date,
        end: Date,
        in context: NSManagedObjectContext
    ) throws -> Bool {
        let request: NSFetchRequest<Incident> = Incident.fetchRequest()
        request.fetchLimit = 1
        request.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [
            NSPredicate(format: "child.id == %@", childID as CVarArg),
            NSPredicate(format: "timestamp >= %@", start as NSDate),
            NSPredicate(format: "timestamp < %@", end as NSDate),
            NSPredicate(format: "status != %@", IncidentStatus.acknowledged.persistenceValue)
        ])
        return try context.count(for: request) > 0
    }

    private static func moodLabel(_ rating: Int) -> String {
        switch rating {
        case 1: return "Unsettled"
        case 2: return "Quiet"
        case 3: return "Calm"
        case 4: return "Happy"
        case 5: return "Very happy"
        default: return "Recorded"
        }
    }
}
