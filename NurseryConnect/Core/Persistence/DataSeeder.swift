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
// 100426     Tommy1914   Keyworker fix-up and single save after seed.
// 140426     Tommy1914   Extended seed rows with profile fields (address, EYFS, consents, collectors).
// 140426     Tommy1914   Removed child gender field from model and seed data.
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

    /// - Description: Builds diverse sample children assigned to the demo keyworker.
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
        // GDPR: Synthetic demo records only; fictional names, addresses, and contacts.
        let samples: [SampleChildSeed] = [
            SampleChildSeed(
                firstName: "Kavindu",
                lastName: "Adithya",
                preferredName: "Kavi",
                dateOfBirth: Calendar.current.date(byAdding: .year, value: -3, to: Date()) ?? Date(),
                roomName: "Sunshine Room",
                allergies: "Peanuts",
                dietaryRequirements: "Vegetarian options",
                medicalNotes: "Asthma inhaler on site; reviewed with family Jan 2026.",
                photoConsent: true,
                homeAddress: "14 Maple Grove, Demo Town DT1 2QR",
                nationality: "British (Sri Lankan heritage)",
                familyDetails: "Mother: Tharani Adithya (07900 000001). Father: Rohan Adithya. Younger sibling: baby at home. Emergency: maternal grandmother 07700 900123.",
                eyfsDevelopmentNotes: "CL: enjoys story-led group time. PSED: separates confidently. PD: refining pencil grip. L: retells simple narratives. M: counts reliably to 10.",
                consentRecordsNotes: "Local walks: signed 12/2025. Farm trip: signed 01/2026. Photo/video for learning journals: yes. Data processing (nursery systems): yes.",
                authorisedCollectors: "Tharani Adithya\nRohan Adithya\nMaya Perera (aunt, photo ID on file)"
            ),
            SampleChildSeed(
                firstName: "Yeil",
                lastName: "Avyan",
                preferredName: "Yeil",
                dateOfBirth: Calendar.current.date(byAdding: .month, value: -42, to: Date()) ?? Date(),
                roomName: "Sunshine Room",
                allergies: "",
                dietaryRequirements: "Halal meals",
                medicalNotes: "No ongoing conditions; GP: Demo Medical Centre.",
                photoConsent: true,
                homeAddress: "88 River Lane, Demo Town DT2 5AA",
                nationality: "British",
                familyDetails: "Mother: Lina Avyan (07900 000002). Father: Omar Avyan. Speaks English and Arabic at home. Custody: shared; pickup notes in office file.",
                eyfsDevelopmentNotes: "EAD: sustained interest in block building. UTW: talks about family celebrations. Strong listening during carpet time.",
                consentRecordsNotes: "Swimming programme: deferred (parent choice). App messaging (updates): opted in. Allergy information shared with cook: yes.",
                authorisedCollectors: "Lina Avyan\nOmar Avyan"
            ),
            SampleChildSeed(
                firstName: "Ayaan",
                lastName: "Gunawardena",
                preferredName: "Ayaan",
                dateOfBirth: Calendar.current.date(byAdding: .month, value: -30, to: Date()) ?? Date(),
                roomName: "Sunshine Room",
                allergies: "Egg",
                dietaryRequirements: "",
                medicalNotes: "Eczema cream in bag (labelled); apply after water play if skin dry.",
                photoConsent: true,
                homeAddress: "3 Orchard Close, Demo Town DT1 8NN",
                nationality: "British",
                familyDetails: "Mother: Nisha Gunawardena (07900 000003). Father: Dineth Gunawardena. One older sibling at primary school (pickup different).",
                eyfsDevelopmentNotes: "PD: climbing with confidence; risk assessed. M: interest in sorting and patterns. Next step: scissor skills in short bursts.",
                consentRecordsNotes: "Sun cream application: parental brand supplied, consent on file. First aid: general consent signed. Visitors to setting: agreed.",
                authorisedCollectors: "Nisha Gunawardena\nDineth Gunawardena\nPriya M. (childminder, Mon/Wed — ID verified)"
            ),
            SampleChildSeed(
                firstName: "Jithev",
                lastName: "Yevan",
                preferredName: "Jith",
                dateOfBirth: Calendar.current.date(byAdding: .year, value: -2, to: Date()) ?? Date(),
                roomName: "Sunshine Room",
                allergies: "Dairy",
                dietaryRequirements: "Lactose-free milk",
                medicalNotes: "",
                photoConsent: false,
                homeAddress: "Flat 2, 55 Station Road, Demo Town DT3 1LL",
                nationality: "British",
                familyDetails: "Mother: Anika Yevan (07900 000004). Father: Sanjay Yevan. Dietary plan agreed with kitchen; review date March 2026.",
                eyfsDevelopmentNotes: "C&L: new vocabulary from small-world play. PSED: beginning to negotiate turns. Next: toileting independence checklist with family.",
                consentRecordsNotes: "Outings by coach: not yet signed (pending). Learning platform photos: declined — see photo consent flag.",
                authorisedCollectors: "Anika Yevan\nSanjay Yevan"
            ),
            SampleChildSeed(
                firstName: "Sara",
                lastName: "Tiana",
                preferredName: "Sari",
                dateOfBirth: Calendar.current.date(byAdding: .year, value: -2, to: Date()) ?? Date(),
                roomName: "Sunshine Room",
                allergies: "Dairy",
                dietaryRequirements: "Lactose-free milk",
                medicalNotes: "Mild lactose intolerance; symptoms monitored.",
                photoConsent: false,
                homeAddress: "The Willows, 2 Church Path, Demo Town DT4 0PP",
                nationality: "British / Italian",
                familyDetails: "Mother: Elena Tiana (07900 000005). Father: Marco Tiana. Bilingual: English and Italian. Grandmother collects Fridays.",
                eyfsDevelopmentNotes: "L: enjoys mark-making and songs. UTW: explores textures in messy play. EAD: dance and instruments — high engagement.",
                consentRecordsNotes: "Library visit: signed. Dental outreach: consent given. Marketing use of images: no.",
                authorisedCollectors: "Elena Tiana\nMarco Tiana\nRosa Tiana (grandmother — password: “sunflower”)"
            ),
            SampleChildSeed(
                firstName: "Nila",
                lastName: "Fernando",
                preferredName: "Nila",
                dateOfBirth: Calendar.current.date(byAdding: .month, value: -36, to: Date()) ?? Date(),
                roomName: "Sunshine Room",
                allergies: "Sesame",
                dietaryRequirements: "No sesame seeds or tahini products",
                medicalNotes: "Carries antihistamine prescribed by GP; care plan reviewed Feb 2026.",
                photoConsent: true,
                homeAddress: "27 Cedar Way, Demo Town DT2 6QH",
                nationality: "British / Sri Lankan",
                familyDetails: "Mother: Ishani Fernando (07900 000006). Father: Malik Fernando. Child attends Tuesday and Thursday dance class after nursery.",
                eyfsDevelopmentNotes: "EAD: imaginative role-play. C&L: asks clear questions in group time. Next step: confidence in early writing strokes.",
                consentRecordsNotes: "Forest school sessions: signed. Face painting: approved with hypoallergenic paints only. App notifications: enabled.",
                authorisedCollectors: "Ishani Fernando\nMalik Fernando\nKumari Perera (grandmother, photo ID on file)"
            ),
            SampleChildSeed(
                firstName: "Luca",
                lastName: "Martins",
                preferredName: "Luca",
                dateOfBirth: Calendar.current.date(byAdding: .month, value: -33, to: Date()) ?? Date(),
                roomName: "Sunshine Room",
                allergies: "",
                dietaryRequirements: "Pescatarian meals",
                medicalNotes: "No diagnosed conditions; hearing check completed Nov 2025.",
                photoConsent: true,
                homeAddress: "9 Brookside Mews, Demo Town DT5 4RL",
                nationality: "Portuguese / British",
                familyDetails: "Mother: Sofia Martins (07900 000007). Father: Daniel Martins. Home language mix: Portuguese and English.",
                eyfsDevelopmentNotes: "Maths: enjoys counting objects during tidy-up. UTW: curious about weather and seasons. PD: improving balance beam confidence.",
                consentRecordsNotes: "Community garden outing: signed. Toothbrushing programme: signed. Public-facing social media use: no.",
                authorisedCollectors: "Sofia Martins\nDaniel Martins\nHelena Costa (aunt, password on file)"
            ),
            SampleChildSeed(
                firstName: "Amara",
                lastName: "Kulathunga",
                preferredName: "Amy",
                dateOfBirth: Calendar.current.date(byAdding: .year, value: -4, to: Date()) ?? Date(),
                roomName: "Sunshine Room",
                allergies: "Strawberry",
                dietaryRequirements: "Halal meals",
                medicalNotes: "Mild speech delay follow-up with SALT every two weeks.",
                photoConsent: false,
                homeAddress: "41 Rosebank Terrace, Demo Town DT1 3YU",
                nationality: "British",
                familyDetails: "Mother: Farah Khan (07900 000008). Father: Ahmed Khan. Older brother in Reception class nearby.",
                eyfsDevelopmentNotes: "C&L: strong listening in small groups. PSED: kind peer support during transitions. Next step: sentence expansion in storytelling.",
                consentRecordsNotes: "External specialist visits: signed. Group photos for display boards: no. Emergency medicine consent: signed.",
                authorisedCollectors: "Farah Kulathunga\nAhmed Kulathunga\nSamira Kulathunga (aunt, verified)"
            ),
            SampleChildSeed(
                firstName: "Theo",
                lastName: "Bennett",
                preferredName: "Theo",
                dateOfBirth: Calendar.current.date(byAdding: .month, value: -29, to: Date()) ?? Date(),
                roomName: "Sunshine Room",
                allergies: "",
                dietaryRequirements: "",
                medicalNotes: "Occasional wheeze in cold weather; inhaler not required currently.",
                photoConsent: true,
                homeAddress: "6 Lantern Court, Demo Town DT6 2BC",
                nationality: "British",
                familyDetails: "Mother: Chloe Bennett (07900 000009). Father: Jack Bennett. Shared custody with alternating weekly pickups.",
                eyfsDevelopmentNotes: "PD: loves outdoor obstacle courses. EAD: enjoys drumming and rhythm games. Next step: cooperative play turn-taking.",
                consentRecordsNotes: "Off-site library walk: signed. Water play photography: yes for learning journal only. Allergy sharing with kitchen: not applicable.",
                authorisedCollectors: "Chloe Bennett\nJack Bennett\nMegan Price (childminder, Thu/Fri)"
            ),
            SampleChildSeed(
                firstName: "Mina",
                lastName: "Perera",
                preferredName: "Mina",
                dateOfBirth: Calendar.current.date(byAdding: .month, value: -40, to: Date()) ?? Date(),
                roomName: "Sunshine Room",
                allergies: "Tree nuts",
                dietaryRequirements: "Vegetarian meals",
                medicalNotes: "EpiPen stored in medical cabinet; annual review due July 2026.",
                photoConsent: true,
                homeAddress: "112 Hillcrest Avenue, Demo Town DT7 8NE",
                nationality: "British / Indian",
                familyDetails: "Mother: Priya Patel (07900 000010). Father: Arun Patel. Grandfather frequently attends stay-and-play sessions.",
                eyfsDevelopmentNotes: "Literacy: recognises name card independently. Maths: sorts by size and colour. Next step: phonological awareness games.",
                consentRecordsNotes: "Cooking activities: adapted plan signed. Face paints: no. Celebration photos in closed parent app: yes.",
                authorisedCollectors: "Priya Perera\nArun Perera\nRakesh Perera (grandfather, ID held)"
            )
        ]

        for row in samples {
            let child = Child(context: context)
            child.id = UUID()
            child.firstName = row.firstName
            child.lastName = row.lastName
            child.preferredName = row.preferredName
            child.dateOfBirth = row.dateOfBirth
            child.roomName = row.roomName
            child.allergies = row.allergies
            child.dietaryRequirements = row.dietaryRequirements
            child.medicalNotes = row.medicalNotes
            child.photoConsent = row.photoConsent
            child.homeAddress = row.homeAddress
            child.nationality = row.nationality
            child.familyDetails = row.familyDetails
            child.eyfsDevelopmentNotes = row.eyfsDevelopmentNotes
            child.consentRecordsNotes = row.consentRecordsNotes
            child.authorisedCollectors = row.authorisedCollectors
            child.keyworkerName = AppConstants.keyworkerDisplayName
        }
        seedTodayMarkedAbsentDemo(in: context)
    }

    /// - Description: Gives one seeded child an `AttendanceRecord` for today with `markedAbsent` so the dashboard “Absent today” section is visible on first launch.
    private static func seedTodayMarkedAbsentDemo(in context: NSManagedObjectContext) {
        let request: NSFetchRequest<Child> = Child.fetchRequest()
        request.predicate = NSPredicate(format: "firstName == %@", "Sara")
        request.fetchLimit = 1
        guard let child = try? context.fetch(request).first else { return }
        let dayStart = Date().startOfDay
        let existing: NSFetchRequest<AttendanceRecord> = AttendanceRecord.fetchRequest()
        existing.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [
            NSPredicate(format: "child == %@", child),
            NSPredicate(format: "dayStart == %@", dayStart as NSDate)
        ])
        existing.fetchLimit = 1
        if let row = try? context.fetch(existing).first {
            row.markedAbsent = true
            row.checkInAt = nil
            row.checkOutAt = nil
            row.droppedOffBy = ""
            row.collectedBy = nil
            return
        }
        let record = AttendanceRecord(context: context)
        record.id = UUID()
        record.dayStart = dayStart
        record.child = child
        record.droppedOffBy = ""
        record.markedAbsent = true
    }
}

// MARK: - Sample data shape

private struct SampleChildSeed {
    let firstName: String
    let lastName: String
    let preferredName: String
    let dateOfBirth: Date
    let roomName: String
    let allergies: String
    let dietaryRequirements: String
    let medicalNotes: String
    let photoConsent: Bool
    let homeAddress: String
    let nationality: String
    let familyDetails: String
    let eyfsDevelopmentNotes: String
    let consentRecordsNotes: String
    let authorisedCollectors: String
}
