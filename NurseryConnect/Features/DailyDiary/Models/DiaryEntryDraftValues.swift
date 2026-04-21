//
//  DiaryEntryDraftValues.swift
//  NurseryConnect
//
//  Feature: Daily Diary
//  Role: Keyworker
//  Created: 21 April 2026
//  Description: Canonical editable diary payload used by create/correction flows.
//

import Foundation

struct DiaryEntryDraftValues {
    let timestamp: Date
    let entryType: DiaryEntryType
    let notes: String
    let activityType: String
    let eyfsArea: String
    let duration: Int32
    let mealDescription: String
    let mealConsumed: String?
    let fluidIntake: Int32
    let fluidType: String
    let nappyType: String
    let moodRating: Int16
    let sleepPosition: String
    let milestonePhotoData: Data?
    let milestonePhotoMimeType: String
    let milestonePhotoBlurredFaceCount: Int16

    var snapshot: DiaryEntrySnapshot {
        DiaryEntrySnapshot(
            entryType: entryType.persistenceValue,
            timestamp: timestamp,
            notes: notes,
            activityType: activityType,
            eyfsArea: eyfsArea,
            duration: duration,
            mealDescription: mealDescription,
            mealConsumed: mealConsumed ?? "",
            fluidIntake: fluidIntake,
            fluidType: fluidType,
            nappyType: nappyType,
            moodRating: moodRating,
            sleepPosition: sleepPosition,
            hasMilestonePhoto: milestonePhotoData != nil,
            milestonePhotoMimeType: milestonePhotoMimeType,
            milestonePhotoBlurredFaceCount: milestonePhotoBlurredFaceCount
        )
    }
}
