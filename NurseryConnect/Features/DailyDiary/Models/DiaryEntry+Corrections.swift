//
//  DiaryEntry+Corrections.swift
//  NurseryConnect
//
//  Feature: Daily Diary
//  Role: Keyworker
//  Created: 21 April 2026
//  Description: Helpers for immutable diary correction snapshots and history rows.
//

import CoreData
import Foundation

struct DiaryEntrySnapshot: Codable {
    let entryType: String
    let timestamp: Date?
    let notes: String
    let activityType: String
    let eyfsArea: String
    let duration: Int32
    let mealDescription: String
    let mealConsumed: String
    let fluidIntake: Int32
    let fluidType: String
    let nappyType: String
    let moodRating: Int16
    let sleepPosition: String

    init(
        entryType: String,
        timestamp: Date?,
        notes: String,
        activityType: String,
        eyfsArea: String,
        duration: Int32,
        mealDescription: String,
        mealConsumed: String,
        fluidIntake: Int32,
        fluidType: String,
        nappyType: String,
        moodRating: Int16,
        sleepPosition: String
    ) {
        self.entryType = entryType
        self.timestamp = timestamp
        self.notes = notes
        self.activityType = activityType
        self.eyfsArea = eyfsArea
        self.duration = duration
        self.mealDescription = mealDescription
        self.mealConsumed = mealConsumed
        self.fluidIntake = fluidIntake
        self.fluidType = fluidType
        self.nappyType = nappyType
        self.moodRating = moodRating
        self.sleepPosition = sleepPosition
    }

    init(entry: DiaryEntry) {
        entryType = entry.entryType ?? ""
        timestamp = entry.timestamp
        notes = entry.notes ?? ""
        activityType = entry.activityType ?? ""
        eyfsArea = entry.eyfsArea ?? ""
        duration = entry.duration
        mealDescription = entry.mealDescription ?? ""
        mealConsumed = entry.mealConsumed ?? ""
        fluidIntake = entry.fluidIntake
        fluidType = entry.fluidType ?? ""
        nappyType = entry.nappyType ?? ""
        moodRating = entry.moodRating
        sleepPosition = entry.sleepPosition ?? ""
    }
}

struct DiaryCorrectionFieldChange {
    let fieldName: String
    let oldValue: String
    let newValue: String
}

extension DiaryEntry {
    var decodedOriginalSnapshot: DiaryEntrySnapshot? {
        guard
            let originalSnapshotJSON,
            let data = originalSnapshotJSON.data(using: .utf8)
        else { return nil }

        return try? JSONDecoder().decode(DiaryEntrySnapshot.self, from: data)
    }

    var sortedCorrections: [DiaryEntryCorrection] {
        let rawSet = corrections as? Set<DiaryEntryCorrection> ?? []
        return rawSet.sorted { lhs, rhs in
            (lhs.correctedAt ?? .distantPast) < (rhs.correctedAt ?? .distantPast)
        }
    }

    func storeOriginalSnapshotIfNeeded() {
        guard originalSnapshotJSON?.isEmpty != false else { return }
        let snapshot = DiaryEntrySnapshot(entry: self)
        guard
            let data = try? JSONEncoder().encode(snapshot),
            let json = String(data: data, encoding: .utf8)
        else { return }
        originalSnapshotJSON = json
    }

    func applyDraft(_ draft: DiaryEntryDraftValues) {
        timestamp = draft.timestamp
        entryType = draft.entryType.persistenceValue
        notes = draft.notes
        activityType = draft.activityType
        eyfsArea = draft.eyfsArea
        duration = draft.duration
        mealDescription = draft.mealDescription
        // Core Data model stores this as required string; keep empty instead of nil.
        mealConsumed = draft.mealConsumed ?? ""
        fluidIntake = draft.fluidIntake
        fluidType = draft.fluidType
        nappyType = draft.nappyType
        moodRating = draft.moodRating
        sleepPosition = draft.sleepPosition
    }

    func correctionChanges(comparedTo draft: DiaryEntryDraftValues) -> [DiaryCorrectionFieldChange] {
        let oldSnapshot = DiaryEntrySnapshot(entry: self)
        let newSnapshot = draft.snapshot
        var changes: [DiaryCorrectionFieldChange] = []

        func append(_ fieldName: String, _ oldValue: String, _ newValue: String) {
            guard oldValue != newValue else { return }
            changes.append(DiaryCorrectionFieldChange(fieldName: fieldName, oldValue: oldValue, newValue: newValue))
        }

        append("entryType", oldSnapshot.entryType, newSnapshot.entryType)
        append("timestamp", Self.displayDate(oldSnapshot.timestamp), Self.displayDate(newSnapshot.timestamp))
        append("notes", oldSnapshot.notes, newSnapshot.notes)
        append("activityType", oldSnapshot.activityType, newSnapshot.activityType)
        append("eyfsArea", oldSnapshot.eyfsArea, newSnapshot.eyfsArea)
        append("duration", "\(oldSnapshot.duration)", "\(newSnapshot.duration)")
        append("mealDescription", oldSnapshot.mealDescription, newSnapshot.mealDescription)
        append("mealConsumed", oldSnapshot.mealConsumed, newSnapshot.mealConsumed)
        append("fluidIntake", "\(oldSnapshot.fluidIntake)", "\(newSnapshot.fluidIntake)")
        append("fluidType", oldSnapshot.fluidType, newSnapshot.fluidType)
        append("nappyType", oldSnapshot.nappyType, newSnapshot.nappyType)
        append("moodRating", "\(oldSnapshot.moodRating)", "\(newSnapshot.moodRating)")
        append("sleepPosition", oldSnapshot.sleepPosition, newSnapshot.sleepPosition)

        return changes
    }

    private static func displayDate(_ date: Date?) -> String {
        guard let date else { return "" }
        return ISO8601DateFormatter().string(from: date)
    }
}
