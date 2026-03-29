//
//  DataSeeder.swift
//  NurseryConnect
//
//  Feature: Core
//  Role: Keyworker
//  Created: 30 March 2026
//  Description: Inserts sample children on first launch for demonstration and UI testing.
//
// -----------------------------------------------------------------
// Date       Name        What has done
// -----------------------------------------------------------------
// 300326     Tommy1914   Created the file with four seeded children for the keyworker demo.
// -----------------------------------------------------------------

import CoreData
import Foundation

/// - Description: Populates Core Data with deterministic sample records when the store is empty.
enum DataSeeder {
    // MARK: - Public Methods

    /// - Description: Seeds the persistent store once if no `Child` entities exist.
    /// - Parameters:
    ///   - context: Managed object context to insert into (main queue).
    static func seedIfNeeded(context: NSManagedObjectContext) {
        do {
            let fetch: NSFetchRequest<Child> = Child.fetchRequest()
            fetch.fetchLimit = 1
            let count = try context.count(for: fetch)
            if count == 0 {
                insertSampleChildren(into: context)
                UserDefaults.standard.set(true, forKey: AppConstants.hasSeededSampleDataKey)
            }
            try assignDemoKeyworkerToOrphansIfNeeded(in: context)
            if context.hasChanges {
                try context.save()
            }
        } catch {
            assertionFailure("Seeding failed: \(error.localizedDescription)")
        }
    }

    /// - Description: Inserts preview-only children for SwiftUI previews (in-memory contexts).
    /// - Parameters:
    ///   - context: Context used by preview stacks.
    static func seedPreviewData(in context: NSManagedObjectContext) {
        insertSampleChildren(into: context)
        do {
            try context.save()
        } catch {
            assertionFailure("Preview seed failed: \(error.localizedDescription)")
        }
    }

    // MARK: - Private Methods

    /// - Description: Builds four diverse sample children assigned to the demo keyworker.
    /// - Parameters:
    ///   - context: Insertion context.
    /// - Description: Ensures legacy or partially migrated `Child` rows match the demo keyworker so the dashboard predicate returns them.
    /// - Parameters:
    ///   - context: Context to read and update.
    private static func assignDemoKeyworkerToOrphansIfNeeded(in context: NSManagedObjectContext) throws {
        let request: NSFetchRequest<Child> = Child.fetchRequest()
        request.predicate = NSCompoundPredicate(orPredicateWithSubpredicates: [
            NSPredicate(format: "keyworkerName == nil"),
            NSPredicate(format: "keyworkerName == %@", "")
        ])
        let orphans = try context.fetch(request)
        for child in orphans {
            child.keyworkerName = AppConstants.keyworkerDisplayName
        }
    }

    private static func insertSampleChildren(into context: NSManagedObjectContext) {
        // GDPR: Synthetic demo records only; minimise fields to what the MVP surfaces.
        let samples: [(String, String, Date, String, String, String, String, Bool)] = [
            ("Emma", "Wilson", Calendar.current.date(byAdding: .year, value: -3, to: Date()) ?? Date(), "Sunshine Room", "Peanuts", "Vegetarian options", "Asthma inhaler on site", true),
            ("Oliver", "Patel", Calendar.current.date(byAdding: .month, value: -42, to: Date()) ?? Date(), "Rainbow Room", "", "Halal meals", "", true),
            ("Sophie", "Nguyen", Calendar.current.date(byAdding: .month, value: -30, to: Date()) ?? Date(), "Sunshine Room", "Egg", "", "Eczema cream in bag", true),
            ("Noah", "Brown", Calendar.current.date(byAdding: .year, value: -2, to: Date()) ?? Date(), "Rainbow Room", "Dairy", "Lactose-free milk", "", false)
        ]

        for row in samples {
            let child = Child(context: context)
            child.id = UUID()
            child.firstName = row.0
            child.lastName = row.1
            child.dateOfBirth = row.2
            child.roomName = row.3
            child.allergies = row.4
            child.dietaryRequirements = row.5
            child.medicalNotes = row.6
            child.photoConsent = row.7
            child.keyworkerName = AppConstants.keyworkerDisplayName
        }
    }
}
