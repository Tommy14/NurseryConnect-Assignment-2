//
//  KeyworkerMoodReminderScheduler.swift
//  NurseryConnect
//
//  Feature: Dashboard
//  Role: Keyworker
//  Created: 16 April 2026
//  Description: Schedules repeating local notifications during nursery hours to prompt hourly wellbeing mood logs.
//

import Foundation
import UserNotifications

/// - Description: Registers daily local reminders for mood checks and pre-meal allergy checks when reminder policy allows scheduling.
enum KeyworkerMoodReminderScheduler {
    private static let moodIdentifierPrefix = "com.nurseryconnect.mood.hourly."
    private static let allergyIdentifierPrefix = "com.nurseryconnect.allergy.premeal."
    private static let allergyLeadMinutes = 5
    private static let sessionStartMinutesFromMidnight = 8 * 60
    private static let sessionEndMinutesFromMidnight = 18 * 60
    private static let mealStartMinutesFromMidnight = [
        8 * 60,         // Breakfast
        10 * 60,        // Morning snack
        12 * 60,        // Lunch
        14 * 60 + 30    // Afternoon snack
    ]

    /// - Description: Requests notification permission if needed, then schedules today's reminders when at least one child is checked in and policy windows allow notifications.
    static func registerDailyReminders(hasCheckedInChildren: Bool, now: Date = Date(), calendar: Calendar = .current) async {
        let center = UNUserNotificationCenter.current()
        let settings = await center.notificationSettings()
        if settings.authorizationStatus == .denied {
            await removeManagedPendingRequests(from: center)
            return
        }

        if settings.authorizationStatus == .notDetermined {
            let granted = (try? await center.requestAuthorization(options: [.alert, .sound])) ?? false
            guard granted else {
                await removeManagedPendingRequests(from: center)
                return
            }
        }

        guard hasCheckedInChildren, isAllowedReminderDay(now, calendar: calendar), isWithinMaintenanceWindowUTC(now) == false else {
            await removeManagedPendingRequests(from: center)
            return
        }

        await removeManagedPendingRequests(from: center)

        for reminderDate in dailyMoodReminderDates(on: now, calendar: calendar) where reminderDate > now {
            let components = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: reminderDate)
            let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
            let content = UNMutableNotificationContent()
            content.title = "Mood check"
            content.body = "Log every assigned child’s wellbeing mood for this hour."
            content.sound = .default
            let request = UNNotificationRequest(
                identifier: moodIdentifier(for: reminderDate, calendar: calendar),
                content: content,
                trigger: trigger
            )
            try? await center.add(request)
        }

        for meal in preMealAllergyReminderDates(on: now, leadMinutes: allergyLeadMinutes, calendar: calendar) where meal > now {
            let components = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: meal)
            let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
            let content = UNMutableNotificationContent()
            content.title = "Allergy check"
            content.body = "Meal time is near. Check allergies for checked-in children."
            content.sound = .default
            let request = UNNotificationRequest(
                identifier: allergyIdentifier(for: meal, calendar: calendar),
                content: content,
                trigger: trigger
            )
            try? await center.add(request)
        }
    }

    /// - Description: Nursery operates Monday-Saturday in local nursery time.
    static func isAllowedReminderDay(_ date: Date, calendar: Calendar = .current) -> Bool {
        let weekday = calendar.component(.weekday, from: date)
        return weekday != 1
    }

    /// - Description: Planned maintenance window when reminders are suppressed: Sunday 02:00-04:00 UTC.
    static func isWithinMaintenanceWindowUTC(_ date: Date) -> Bool {
        var utcCalendar = Calendar(identifier: .gregorian)
        utcCalendar.timeZone = TimeZone(secondsFromGMT: 0) ?? .gmt
        let weekday = utcCalendar.component(.weekday, from: date)
        guard weekday == 1 else { return false }
        let hour = utcCalendar.component(.hour, from: date)
        return hour >= 2 && hour < 4
    }

    /// - Description: Mood reminder timestamps on the same local day as `reference` for each session hour.
    static func dailyMoodReminderDates(on reference: Date, calendar: Calendar = .current) -> [Date] {
        let startHour = sessionStartMinutesFromMidnight / 60
        let endHour = sessionEndMinutesFromMidnight / 60
        let startOfDay = calendar.startOfDay(for: reference)
        return (startHour ..< endHour).compactMap { hour in
            calendar.date(byAdding: DateComponents(hour: hour), to: startOfDay)
        }
    }

    /// - Description: Allergy reminder timestamps generated `leadMinutes` before each meal start for `reference` day.
    static func preMealAllergyReminderDates(on reference: Date, leadMinutes: Int, calendar: Calendar = .current) -> [Date] {
        let startOfDay = calendar.startOfDay(for: reference)
        return mealStartMinutesFromMidnight.compactMap { mealStartMinutes in
            let minuteOffset = max(0, mealStartMinutes - leadMinutes)
            return calendar.date(byAdding: .minute, value: minuteOffset, to: startOfDay)
        }
    }

    private static func moodIdentifier(for date: Date, calendar: Calendar) -> String {
        let key = notificationDayKey(for: date, calendar: calendar)
        let hour = calendar.component(.hour, from: date)
        return "\(moodIdentifierPrefix)\(key).\(hour)"
    }

    private static func allergyIdentifier(for date: Date, calendar: Calendar) -> String {
        let key = notificationDayKey(for: date, calendar: calendar)
        let hour = calendar.component(.hour, from: date)
        let minute = calendar.component(.minute, from: date)
        return "\(allergyIdentifierPrefix)\(key).\(hour)-\(minute)"
    }

    private static func notificationDayKey(for date: Date, calendar: Calendar) -> String {
        let components = calendar.dateComponents([.year, .month, .day], from: date)
        let year = components.year ?? 0
        let month = components.month ?? 0
        let day = components.day ?? 0
        return String(format: "%04d%02d%02d", year, month, day)
    }

    private static func removeManagedPendingRequests(from center: UNUserNotificationCenter) async {
        let requests = await center.pendingNotificationRequests()
        let identifiers = requests
            .map(\.identifier)
            .filter { id in
                id.hasPrefix(moodIdentifierPrefix) || id.hasPrefix(allergyIdentifierPrefix)
            }
        guard identifiers.isEmpty == false else { return }
        center.removePendingNotificationRequests(withIdentifiers: identifiers)
    }
}
