//
//  DiarySupportingEnums.swift
//  NurseryConnect
//
//  Feature: Daily Diary
//  Role: Keyworker
//  Created: 3 April 2026
//  Description: Enumerations for pickers used when composing diary entries.
//
// -----------------------------------------------------------------
// Date       Name        What has done
// -----------------------------------------------------------------
// 030426     Tommy1914   Created the file with activity, EYFS, meal, and sleep enums.
// -----------------------------------------------------------------

import Foundation

/// - Description: Activity kinds for physical and learning experiences.
enum DiaryActivityKind: String, CaseIterable, Identifiable {
    case indoorPlay = "Indoor Play"
    case outdoorPlay = "Outdoor Play"
    case reading = "Reading"
    case arts = "Arts & Crafts"
    case educational = "Educational"
    case freePlay = "Free Play"
    case rest = "Rest"
    var id: String { rawValue }
}

/// - Description: EYFS areas of learning labels.
enum EyfsArea: String, CaseIterable, Identifiable {
    case communication = "Communication and language"
    case physical = "Physical development"
    case personal = "Personal, social and emotional"
    case literacy = "Literacy"
    case mathematics = "Mathematics"
    case understandingWorld = "Understanding the world"
    case expressiveArts = "Expressive arts and design"
    var id: String { rawValue }
}

/// - Description: Sleep posture categories for safe sleep logging.
enum SleepPosition: String, CaseIterable, Identifiable {
    case back = "Back"
    case side = "Side"
    case front = "Front"
    var id: String { rawValue }
}

/// - Description: Meal or snack slot labels.
enum MealSlot: String, CaseIterable, Identifiable {
    case breakfast = "Breakfast"
    case morningSnack = "Morning Snack"
    case lunch = "Lunch"
    case afternoonSnack = "Afternoon Snack"
    var id: String { rawValue }
}

/// - Description: Estimated proportion eaten — persisted via `mealConsumed` string.
enum MealConsumptionLevel: String, CaseIterable, Identifiable {
    case all = "all"
    case most = "most"
    case half = "half"
    case little = "little"
    case none = "none"
    case refused = "refused"

    /// - Description: Stable identity for pickers and lists.
    var id: String { rawValue }

    var title: String {
        rawValue.capitalized
    }
}

/// - Description: Fluid types for hydration logging.
enum FluidKind: String, CaseIterable, Identifiable {
    case water = "Water"
    case milk = "Milk"
    case squash = "Diluted squash"
    case other = "Other"
    var id: String { rawValue }
}

/// - Description: Nappy observation categories.
enum NappyObservationKind: String, CaseIterable, Identifiable {
    case wet = "Wet"
    case dirty = "Dirty"
    case both = "Both"
    case none = "None"
    var id: String { rawValue }
}
