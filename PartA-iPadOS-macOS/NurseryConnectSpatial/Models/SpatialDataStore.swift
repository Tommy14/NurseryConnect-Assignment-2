//
//  SpatialDataStore.swift
//  NurseryConnect Spatial
//
//  Feature: Spatial
//  Created: 4 June 2026
//  Description: Observable mock data store for new spatial feature views. Provides realistic
//               sample data matching the children and incidents shown across the app.
//

import Combine
import Foundation
import SwiftUI

final class SpatialDataStore: ObservableObject {
    @Published var children:  [NCChild]          = NCChild.sampleData
    @Published var incidents: [NCIncident]        = NCIncident.sampleData
    @Published var threads:   [NCMessageThread]   = NCMessageThread.sampleData
    @Published var transport: NCTransportRun       = .sampleRun
    @Published var mealPlan:  NCWeeklyMealPlan    = .samplePlan
    @Published var attendance: [NCAttendanceRecord] = NCAttendanceRecord.sampleData

    var totalEnrolled: Int { children.count }
    var onSiteCount:   Int { children.filter { $0.status == .onSite }.count }
    var openIncidents: Int { incidents.filter { $0.status != .acknowledged }.count }
    var unreadMessages: Int { threads.reduce(0) { $0 + $1.unreadCount } }
}

// MARK: - NCChild sample data

extension NCChild {
    static let sampleData: [NCChild] = [
        .init(
            id: UUID(uuidString: "11111111-0000-0000-0000-000000000001")!,
            firstName: "Amy", lastName: "K.", preferredName: "Amy",
            dateOfBirth: dob(yearsAgo: 3, month: 4, day: 12),
            room: "Sunshine Room", keyworkerName: "Thamindu V D",
            allergies: [.init(name: "Strawberry", emoji: "🍓", severity: .allergy, avoidanceNote: "Avoid all strawberry products")],
            dietaryRestrictions: ["Halal"], medicalConditions: [],
            photoConsent: true, socialMediaConsent: false, status: .onSite
        ),
        .init(
            id: UUID(uuidString: "11111111-0000-0000-0000-000000000002")!,
            firstName: "Ayaan", lastName: "G.", preferredName: "Ayaan",
            dateOfBirth: dob(yearsAgo: 2, month: 9, day: 3),
            room: "Sunshine Room", keyworkerName: "Thamindu V D",
            allergies: [.init(name: "Egg", emoji: "🥚", severity: .allergy, avoidanceNote: "No egg in any form")],
            dietaryRestrictions: [], medicalConditions: [],
            photoConsent: true, socialMediaConsent: true, status: .onSite
        ),
        .init(
            id: UUID(uuidString: "11111111-0000-0000-0000-000000000003")!,
            firstName: "Jith", lastName: "Y.", preferredName: "Jith",
            dateOfBirth: dob(yearsAgo: 4, month: 1, day: 22),
            room: "Rainbow Room", keyworkerName: "Thamindu V D",
            allergies: [.init(name: "Dairy", emoji: "🥛", severity: .intolerance, avoidanceNote: "Dairy-free milk required")],
            dietaryRestrictions: ["Dairy-free"], medicalConditions: [],
            photoConsent: true, socialMediaConsent: true, status: .awaitingArrival
        ),
        .init(
            id: UUID(uuidString: "11111111-0000-0000-0000-000000000004")!,
            firstName: "Kavi", lastName: "A.", preferredName: "Kavindu",
            dateOfBirth: dob(yearsAgo: 3, month: 7, day: 8),
            room: "Sunshine Room", keyworkerName: "Thamindu V D",
            allergies: [
                .init(name: "Peanuts", emoji: "🥜", severity: .anaphylactic, avoidanceNote: "EpiPen on site — strict avoidance"),
            ],
            dietaryRestrictions: ["Vegetarian"], medicalConditions: [
                .init(name: "Peanut anaphylaxis", severity: .critical, note: "EpiPen kept in first aid room")
            ],
            photoConsent: true, socialMediaConsent: false, status: .onSite
        ),
        .init(
            id: UUID(uuidString: "11111111-0000-0000-0000-000000000005")!,
            firstName: "Luca", lastName: "M.", preferredName: "Luca",
            dateOfBirth: dob(yearsAgo: 4, month: 11, day: 30),
            room: "Rainbow Room", keyworkerName: "Thamindu V D",
            allergies: [],
            dietaryRestrictions: ["Pescatarian"], medicalConditions: [],
            photoConsent: true, socialMediaConsent: true, status: .onSite
        ),
        .init(
            id: UUID(uuidString: "11111111-0000-0000-0000-000000000006")!,
            firstName: "Mina", lastName: "P.", preferredName: "Mina",
            dateOfBirth: dob(yearsAgo: 3, month: 2, day: 18),
            room: "Sunshine Room", keyworkerName: "Thamindu V D",
            allergies: [.init(name: "Tree nuts", emoji: "🌰", severity: .allergy, avoidanceNote: "Avoid all tree nuts")],
            dietaryRestrictions: ["Vegetarian"], medicalConditions: [],
            photoConsent: true, socialMediaConsent: true, status: .onSite
        ),
        .init(
            id: UUID(uuidString: "11111111-0000-0000-0000-000000000007")!,
            firstName: "Nila", lastName: "F.", preferredName: "Nila",
            dateOfBirth: dob(yearsAgo: 2, month: 5, day: 14),
            room: "Sunshine Room", keyworkerName: "Priya S.",
            allergies: [], dietaryRestrictions: [], medicalConditions: [],
            photoConsent: true, socialMediaConsent: true, status: .onSite
        ),
        .init(
            id: UUID(uuidString: "11111111-0000-0000-0000-000000000008")!,
            firstName: "Sari", lastName: "T.", preferredName: "Sari",
            dateOfBirth: dob(yearsAgo: 3, month: 8, day: 6),
            room: "Rainbow Room", keyworkerName: "Priya S.",
            allergies: [], dietaryRestrictions: [], medicalConditions: [],
            photoConsent: false, socialMediaConsent: false, status: .checkedOut
        ),
        .init(
            id: UUID(uuidString: "11111111-0000-0000-0000-000000000009")!,
            firstName: "Theo", lastName: "B.", preferredName: "Theo",
            dateOfBirth: dob(yearsAgo: 4, month: 3, day: 25),
            room: "Rainbow Room", keyworkerName: "Priya S.",
            allergies: [], dietaryRestrictions: [], medicalConditions: [
                .init(name: "Asthma", severity: .important, note: "Blue inhaler in his bag")
            ],
            photoConsent: true, socialMediaConsent: true, status: .onSite
        ),
        .init(
            id: UUID(uuidString: "11111111-0000-0000-0000-000000000010")!,
            firstName: "Yeil", lastName: "A.", preferredName: "Yeil",
            dateOfBirth: dob(yearsAgo: 3, month: 6, day: 19),
            room: "Sunshine Room", keyworkerName: "Thamindu V D",
            allergies: [], dietaryRestrictions: [], medicalConditions: [],
            photoConsent: true, socialMediaConsent: false, status: .onSite
        ),
    ]

    private static func dob(yearsAgo: Int, month: Int, day: Int) -> Date {
        var comps = DateComponents()
        let year = Calendar.current.component(.year, from: Date()) - yearsAgo
        comps.year = year; comps.month = month; comps.day = day
        return Calendar.current.date(from: comps) ?? Date()
    }
}

// MARK: - NCIncident sample data

extension NCIncident {
    static let sampleData: [NCIncident] = [
        .init(
            id: UUID(), childName: "Yeil Avyan",
            category: .accidentMinor,
            timestamp: todayAt(hour: 11), location: "Outdoor play area",
            description: "Minor graze on right knee during outdoor play. Wound cleaned and plaster applied.",
            status: .parentNotified
        ),
        .init(
            id: UUID(), childName: "Kavindu Adithya",
            category: .nearMiss,
            timestamp: todayAt(hour: 10), location: "Sand pit area",
            description: "Child approached peer's snack — potential allergen exposure avoided. No reaction occurred.",
            status: .awaitingReview
        ),
        .init(
            id: UUID(), childName: "Theo Bennett",
            category: .accidentFirstAid,
            timestamp: todayAt(hour: 9), location: "Main room",
            description: "Child slipped on wet floor, minor head bump. First aid applied; parent notified; child observed for 30 mins.",
            status: .awaitingReview
        ),
    ]

    private static func todayAt(hour: Int) -> Date {
        Calendar.current.date(bySettingHour: hour, minute: 0, second: 0, of: Date()) ?? Date()
    }
}

// MARK: - NCAttendanceRecord sample data

extension NCAttendanceRecord {
    static let sampleData: [NCAttendanceRecord] = NCChild.sampleData.enumerated().map { idx, child in
        let checkIn: Date? = [.onSite, .checkedOut].contains(child.status)
            ? Calendar.current.date(bySettingHour: 8 + (idx % 3), minute: [0,15,30][idx % 3], second: 0, of: Date())
            : nil
        let checkOut: Date? = child.status == .checkedOut
            ? Calendar.current.date(bySettingHour: 15, minute: 30, second: 0, of: Date())
            : nil
        return NCAttendanceRecord(
            id: UUID(), child: child,
            status: child.status,
            checkInTime: checkIn, checkOutTime: checkOut,
            droppedOffBy: "Parent", arrivalMood: .happy,
            collectedBy: "", notes: ""
        )
    }
}

// MARK: - NCMessageThread sample data

extension NCMessageThread {
    static let sampleData: [NCMessageThread] = [
        .init(id: UUID(), participantName: "Amy's Mum", participantRole: .parent, childName: "Amy K.",
              messages: [
                .init(id: UUID(), senderName: "Amy's Mum", role: .parent,
                      body: "Hi, just wanted to check if Amy enjoyed her lunch today?", timestamp: Date().addingTimeInterval(-7200), isRead: false, childName: "Amy K."),
                .init(id: UUID(), senderName: "Thamindu V D", role: .keyworker,
                      body: "She had a great time at lunch! Ate most of her pasta.", timestamp: Date().addingTimeInterval(-3600), isRead: true, childName: "Amy K."),
              ]),
        .init(id: UUID(), participantName: "Ayaan's Dad", participantRole: .parent, childName: "Ayaan G.",
              messages: [
                .init(id: UUID(), senderName: "Ayaan's Dad", role: .parent,
                      body: "Ayaan may be coming in a bit late tomorrow, around 9:30.", timestamp: Date().addingTimeInterval(-1800), isRead: false, childName: "Ayaan G."),
              ]),
        .init(id: UUID(), participantName: "Setting Manager", participantRole: .settingManager, childName: nil,
              messages: [
                .init(id: UUID(), senderName: "Setting Manager", role: .settingManager,
                      body: "Reminder: EYFS documentation review is on Friday at 4pm.", timestamp: Date().addingTimeInterval(-86400), isRead: true, childName: nil),
              ]),
    ]
}

// MARK: - NCTransportRun sample data

extension NCTransportRun {
    static let sampleRun: NCTransportRun = {
        let route: [CLCoordinate] = [
            .init(latitude: 51.5074, longitude: -0.1278),
            .init(latitude: 51.5090, longitude: -0.1310),
            .init(latitude: 51.5120, longitude: -0.1350),
            .init(latitude: 51.5150, longitude: -0.1380),
            .init(latitude: 51.5180, longitude: -0.1400),
        ]
        return NCTransportRun(
            id: UUID(),
            routeName: "PM School Run",
            children: [
                .init(id: UUID(), childName: "Jith Y.", school: "Little Stars Primary", status: .boarded, boardingTime: Date().addingTimeInterval(-900)),
                .init(id: UUID(), childName: "Luca M.", school: "Little Stars Primary", status: .boarded, boardingTime: Date().addingTimeInterval(-600)),
                .init(id: UUID(), childName: "Theo B.", school: "Green Meadows Academy", status: .awaiting, boardingTime: nil),
                .init(id: UUID(), childName: "Sari T.", school: "Green Meadows Academy", status: .awaiting, boardingTime: nil),
            ],
            vanCoordinate: .init(latitude: 51.5120, longitude: -0.1350),
            estimatedArrival: Date().addingTimeInterval(15 * 60),
            routePath: route
        )
    }()
}

// MARK: - NCWeeklyMealPlan sample data

extension NCWeeklyMealPlan {
    static let samplePlan: NCWeeklyMealPlan = {
        func meal(_ name: String, allergens: [NCAllergenTag] = [], main: Bool = false, status: NCNutritionalStatus = .pass) -> NCMealEntry {
            NCMealEntry(id: UUID(), name: name, allergens: allergens, nutritionalPass: status, isMainMeal: main)
        }
        let days: [NCDayMeals] = [
            NCDayMeals(id: UUID(), day: "Mon",
                       breakfast: meal("Porridge with banana", allergens: [.dairy]),
                       amSnack: meal("Apple slices & rice cakes"),
                       lunch: meal("Beef bolognese with pasta", allergens: [.gluten], main: true),
                       pmSnack: meal("Cheese & crackers", allergens: [.dairy, .gluten])),
            NCDayMeals(id: UUID(), day: "Tue",
                       breakfast: meal("Scrambled eggs & toast", allergens: [.egg, .gluten]),
                       amSnack: meal("Cucumber & hummus", allergens: [.sesame]),
                       lunch: meal("Chicken & vegetable stew with rice", main: true),
                       pmSnack: meal("Yoghurt with berries", allergens: [.dairy])),
            NCDayMeals(id: UUID(), day: "Wed",
                       breakfast: meal("Weetabix with milk", allergens: [.gluten, .dairy]),
                       amSnack: meal("Orange segments"),
                       lunch: meal("Salmon fishcakes with peas & mash", allergens: [.fish, .gluten, .dairy], main: true),
                       pmSnack: meal("Toast with butter", allergens: [.gluten, .dairy])),
            NCDayMeals(id: UUID(), day: "Thu",
                       breakfast: meal("Pancakes with maple syrup", allergens: [.egg, .gluten, .dairy]),
                       amSnack: meal("Grapes & breadsticks", allergens: [.gluten]),
                       lunch: meal("Pork meatballs in tomato sauce with spaghetti", allergens: [.gluten], main: true),
                       pmSnack: meal("Pepperoni pizza slice ⚠️", allergens: [.gluten, .dairy], status: .borderline)),
            NCDayMeals(id: UUID(), day: "Fri",
                       breakfast: meal("Granola with yoghurt", allergens: [.gluten, .dairy, .nuts]),
                       amSnack: meal("Banana & peanut-free cereal bar"),
                       lunch: meal("Vegetarian pasta bake with salad", allergens: [.gluten, .dairy], main: true),
                       pmSnack: meal("Fruit platter")),
        ]
        return NCWeeklyMealPlan(id: UUID(), weekLabel: "w/c 2 June 2026", days: days)
    }()
}
