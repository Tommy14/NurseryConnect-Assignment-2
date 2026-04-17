//
//  KeyworkerMoodReminderScheduler.swift
//  NurseryConnect
//
//  Feature: Dashboard
//  Role: Keyworker
//  Created: 20 April 2026
//  Description: Schedules repeating local notifications during nursery hours to prompt hourly wellbeing mood logs.
//

import Foundation
import UserNotifications

/// - Description: Registers one notification per clock hour while the nursery session is active (local time).
enum KeyworkerMoodReminderScheduler {
    private static let identifierPrefix = "com.nurseryconnect.mood.hourly."

    /// - Description: Requests notification permission if needed, then schedules hourly mood reminders for each hour from session start through the hour before session end.
    static func registerHourlyMoodRemindersDuringSession() async {
        let center = UNUserNotificationCenter.current()
        let settings = await center.notificationSettings()
        if settings.authorizationStatus == .denied { return }

        if settings.authorizationStatus == .notDetermined {
            let granted = (try? await center.requestAuthorization(options: [.alert, .sound])) ?? false
            guard granted else { return }
        }

        let startHour = NurseryDaySchedule.sessionStartMinutesFromMidnight / 60
        let endHour = NurseryDaySchedule.sessionEndMinutesFromMidnight / 60
        let hours = Array(startHour ..< endHour)

        center.removePendingNotificationRequests(withIdentifiers: hours.map { Self.identifier(for: $0) })

        for hour in hours {
            var components = DateComponents()
            components.hour = hour
            components.minute = 0
            let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
            let content = UNMutableNotificationContent()
            content.title = "Mood check"
            content.body = "Log every assigned child’s wellbeing mood for this hour."
            content.sound = .default
            let request = UNNotificationRequest(
                identifier: Self.identifier(for: hour),
                content: content,
                trigger: trigger
            )
            try? await center.add(request)
        }
    }

    private static func identifier(for hour: Int) -> String {
        "\(identifierPrefix)\(hour)"
    }
}
