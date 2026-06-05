//
//  MessageFormatting.swift
//  NurseryConnect
//
//  Feature: Messages
//  Role: Keyworker
//  Created: 29 May 2026
//  Description: Relative time formatting for message thread rows.
//

import Foundation

enum MessageFormatting {
    static func relativeTime(from date: Date, now: Date = Date()) -> String {
        if date.isSameDay(as: now) {
            return date.formattedTime()
        }
        let days = Calendar.current.dateComponents([.day], from: date.startOfDay, to: now.startOfDay).day ?? 0
        if days == 1 { return "Yesterday" }
        if days < 7 { return "\(days)d ago" }
        return date.formattedMediumDate()
    }
}
