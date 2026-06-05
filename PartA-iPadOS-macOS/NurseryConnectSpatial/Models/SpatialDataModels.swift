//
//  SpatialDataModels.swift
//  NurseryConnect Spatial
//
//  Feature: Spatial
//  Created: 4 June 2026
//  Description: Pure-Swift mock data models for new spatial feature views (no CoreData dependency).
//

import Foundation
import SwiftUI

// MARK: - Child

struct NCChild: Identifiable, Hashable {
    let id: UUID
    let firstName: String
    let lastName: String
    let preferredName: String
    let dateOfBirth: Date
    let room: String
    let keyworkerName: String
    let allergies: [NCAllergen]
    let dietaryRestrictions: [String]
    let medicalConditions: [NCMedicalCondition]
    let photoConsent: Bool
    let socialMediaConsent: Bool
    let status: NCAttendanceStatus

    var fullName: String { "\(firstName) \(lastName)" }
    var displayName: String { preferredName.isEmpty ? firstName : preferredName }
    var initials: String {
        let f = firstName.prefix(1)
        let l = lastName.prefix(1)
        return "\(f)\(l)".uppercased()
    }
    var age: Int {
        Calendar.current.dateComponents([.year], from: dateOfBirth, to: Date()).year ?? 0
    }
}

enum NCAttendanceStatus: String, CaseIterable {
    case onSite = "On Site"
    case awaitingArrival = "Awaiting Arrival"
    case checkedOut = "Checked Out"
    case absent = "Absent"
}

struct NCAllergen: Identifiable, Hashable {
    let id = UUID()
    let name: String
    let emoji: String
    let severity: NCAllergenSeverity
    let avoidanceNote: String
}

enum NCAllergenSeverity: String {
    case intolerance = "Intolerance"
    case allergy = "Allergy"
    case anaphylactic = "Anaphylactic"

    var emoji: String {
        switch self {
        case .intolerance: return "🟡"
        case .allergy: return "🟠"
        case .anaphylactic: return "🔴"
        }
    }
}

struct NCMedicalCondition: Identifiable, Hashable {
    let id = UUID()
    let name: String
    let severity: NCConditionSeverity
    let note: String
}

enum NCConditionSeverity: String {
    case routine = "Routine"
    case important = "Important"
    case critical = "Critical"
}

// MARK: - Incident

struct NCIncident: Identifiable {
    let id: UUID
    let childName: String
    let category: NCIncidentCategory
    let timestamp: Date
    let location: String
    let description: String
    let status: NCIncidentStatus
}

enum NCIncidentCategory: String, CaseIterable {
    case accidentMinor = "Accident (Minor)"
    case accidentFirstAid = "Accident (First Aid)"
    case nearMiss = "Near Miss"
    case safeguarding = "Safeguarding Concern"
    case allergicReaction = "Allergic Reaction"
    case medical = "Medical Incident"

    var symbol: String {
        switch self {
        case .accidentMinor:   return "bandage.fill"
        case .accidentFirstAid: return "cross.case.fill"
        case .nearMiss:        return "exclamationmark.triangle.fill"
        case .safeguarding:    return "hand.raised.fill"
        case .allergicReaction: return "allergens"
        case .medical:         return "heart.text.square.fill"
        }
    }
}

enum NCIncidentStatus: String {
    case parentNotified = "Parent notified"
    case awaitingReview = "Awaiting review"
    case acknowledged = "Acknowledged"
}

// MARK: - Attendance

struct NCAttendanceRecord: Identifiable {
    let id: UUID
    let child: NCChild
    var status: NCAttendanceStatus
    var checkInTime: Date?
    var checkOutTime: Date?
    var droppedOffBy: String
    var arrivalMood: NCMoodLevel
    var collectedBy: String
    var notes: String
}

enum NCMoodLevel: Int, CaseIterable {
    case happy = 3, neutral = 2, upset = 1

    var emoji: String {
        switch self {
        case .happy: return "😊"
        case .neutral: return "😐"
        case .upset: return "😟"
        }
    }

    var label: String {
        switch self {
        case .happy: return "Happy"
        case .neutral: return "Neutral"
        case .upset: return "Upset"
        }
    }
}

// MARK: - Message

struct NCMessage: Identifiable {
    let id: UUID
    let senderName: String
    let role: NCMessageRole
    let body: String
    let timestamp: Date
    var isRead: Bool
    let childName: String?
}

enum NCMessageRole: String {
    case parent = "Parent"
    case settingManager = "Setting Manager"
    case keyworker = "Keyworker"
}

struct NCMessageThread: Identifiable {
    let id: UUID
    let participantName: String
    let participantRole: NCMessageRole
    let childName: String?
    var messages: [NCMessage]
    var unreadCount: Int { messages.filter { !$0.isRead && $0.role != .keyworker }.count }
    var lastMessage: NCMessage? { messages.last }
}

// MARK: - Transport

struct NCTransportStop: Identifiable {
    let id: UUID
    let name: String
    let coordinate: CLCoordinate
}

struct CLCoordinate {
    var latitude: Double
    var longitude: Double
}

struct NCTransportChild: Identifiable {
    let id: UUID
    let childName: String
    let school: String
    var status: NCTransportStatus
    var boardingTime: Date?
}

enum NCTransportStatus: String {
    case awaiting = "Awaiting collection"
    case boarded = "Boarded"
    case notFound = "Not found"
}

struct NCTransportRun: Identifiable {
    let id: UUID
    let routeName: String
    var children: [NCTransportChild]
    var vanCoordinate: CLCoordinate
    var estimatedArrival: Date
    let routePath: [CLCoordinate]
    var boardedCount: Int { children.filter { $0.status == .boarded }.count }
}

// MARK: - Meal Plan

struct NCMealEntry: Identifiable {
    let id: UUID
    let name: String
    let allergens: [NCAllergenTag]
    let nutritionalPass: NCNutritionalStatus
    let isMainMeal: Bool
}

enum NCAllergenTag: String, CaseIterable {
    case egg = "Egg 🥚"
    case dairy = "Dairy 🥛"
    case gluten = "Gluten 🌾"
    case nuts = "Nuts 🥜"
    case fish = "Fish 🐟"
    case soya = "Soya"
    case sesame = "Sesame"
    case lupin = "Lupin"
    case shellfish = "Shellfish"
    case celery = "Celery"
    case mustard = "Mustard"
    case sulphites = "Sulphites"
    case molluscs = "Molluscs"
    case peanuts = "Peanuts"

    var shortName: String { rawValue.components(separatedBy: " ").first ?? rawValue }
    var emoji: String {
        switch self {
        case .egg: return "🥚"
        case .dairy: return "🥛"
        case .gluten: return "🌾"
        case .nuts: return "🥜"
        case .fish: return "🐟"
        default: return "⚠️"
        }
    }
}

enum NCNutritionalStatus {
    case pass, borderline, fail
}

struct NCDayMeals: Identifiable {
    let id: UUID
    let day: String
    let breakfast: NCMealEntry
    let amSnack: NCMealEntry
    let lunch: NCMealEntry
    let pmSnack: NCMealEntry
}

struct NCWeeklyMealPlan: Identifiable {
    let id: UUID
    let weekLabel: String
    let days: [NCDayMeals]
}

// MARK: - Daily Diary

struct NCDiaryActivityEntry: Identifiable {
    let id: UUID
    let time: Date
    let activityName: String
    let emoji: String
    let eyfsArea: String
    let duration: String
    let observation: String?
}

struct NCSleepEntry {
    let startTime: Date
    let endTime: Date
    var duration: String {
        let mins = Int(endTime.timeIntervalSince(startTime) / 60)
        return "\(mins / 60)h \(mins % 60)m"
    }
}

struct NCMealLogEntry {
    let mealName: String
    let items: [NCFoodItem]
    let fluidMl: Int
}

struct NCFoodItem: Identifiable {
    let id = UUID()
    let name: String
    let consumption: NCConsumptionLevel
}

enum NCConsumptionLevel: Int, CaseIterable {
    case all = 5, most = 4, half = 3, little = 2, none = 1

    var label: String {
        switch self {
        case .all: return "All"
        case .most: return "Most"
        case .half: return "Half"
        case .little: return "Little"
        case .none: return "None"
        }
    }

    var color: String {
        switch self {
        case .all, .most: return "green"
        case .half: return "yellow"
        case .little, .none: return "red"
        }
    }
}

struct NCNappyEntry: Identifiable {
    let id = UUID()
    let time: Date
    let type: String
}

struct NCDailyDiary {
    let child: NCChild
    let date: Date
    let checkInTime: Date
    let droppedOffBy: String
    let arrivalMood: NCMoodLevel
    let activities: [NCDiaryActivityEntry]
    let sleep: NCSleepEntry?
    let meals: [NCMealLogEntry]
    let nappyLog: [NCNappyEntry]
    let morningWellbeing: NCMoodLevel
    let middayWellbeing: NCMoodLevel
    let departureWellbeing: NCMoodLevel
    let checkOutTime: Date
    let collectedBy: String
    let collectorRelationship: String
}

// MARK: - EYFS Progress

struct NCEYFSArea: Identifiable {
    let id = UUID()
    let name: String
    let stage: String
    let progress: Double
    var color: Color {
        NurseryTheme.EYFS.color(for: name)
    }
}

struct NCMilestoneEntry: Identifiable {
    let id = UUID()
    let date: Date
    let area: String
    let description: String
}

// MARK: - Staff Ratios

struct NCStaffRatioGroup: Identifiable {
    let id = UUID()
    let label: String
    let ratio: String
    let onSiteCount: Int
    let requiredStaff: Int
    var isCompliant: Bool { onSiteCount >= requiredStaff }
}
