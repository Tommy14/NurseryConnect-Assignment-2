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
// 040626     Tommy1914   Added visionOS spatial demo store with all-success presentation data.
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
            try backfillSessionWeekdaysIfNeeded(in: context)
            seedDemoMessagesIfNeeded(in: context)
            if context.hasChanges {
                try context.save()
            }
        } catch {
            assertionFailure("Seeding failed: \(error.localizedDescription)")
        }
    }

    /// - Description: Seeds the in-memory visionOS store with presentation-friendly “all green” metrics.
    /// - Parameters:
    ///   - context: Spatial app view context (always in-memory).
    static func seedSpatialDemoStore(in context: NSManagedObjectContext) {
        seedPreviewData(in: context)
        seedDemoWellbeingIfNeeded(in: context)
        applySpatialDemoSuccessState(in: context)
        do {
            try context.save()
        } catch {
            assertionFailure("Spatial demo seed failed: \(error.localizedDescription)")
        }
    }

    /// - Description: Inserts preview-only children for SwiftUI previews (in-memory contexts).
    /// - Parameters:
    ///   - context: Context used by preview stacks.
    static func seedPreviewData(in context: NSManagedObjectContext) {
        insertSampleChildren(into: context)
        seedDemoMessagesIfNeeded(in: context)
        seedDemoWellbeingIfNeeded(in: context)
        do {
            try context.save()
        } catch {
            assertionFailure("Preview seed failed: \(error.localizedDescription)")
        }
    }

    /// - Description: Inserts seven-day wellbeing mood trends and today's diary entries for spatial/chart demos.
    /// - Parameters:
    ///   - context: Managed object context.
    static func seedDemoWellbeingIfNeeded(in context: NSManagedObjectContext) {
        do {
            let childFetch: NSFetchRequest<Child> = Child.fetchRequest()
            childFetch.predicate = NSPredicate(format: "keyworkerName == %@", AppConstants.keyworkerDisplayName)
            childFetch.sortDescriptors = [NSSortDescriptor(keyPath: \Child.firstName, ascending: true)]
            let children = try context.fetch(childFetch)
            guard !children.isEmpty else { return }

            let calendar = Calendar.current
            let today = Date().startOfDay
            let moodPatterns: [[Int16]] = [
                [3, 3, 4, 4, 3, 4, 5],
                [4, 3, 2, 3, 4, 4, 3],
                [5, 4, 4, 3, 3, 4, 5]
            ]

            for (index, child) in children.prefix(3).enumerated() {
                guard let childID = child.id else { continue }
                let wellbeingFetch: NSFetchRequest<DiaryEntry> = DiaryEntry.fetchRequest()
                wellbeingFetch.fetchLimit = 1
                wellbeingFetch.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [
                    NSPredicate(format: "child.id == %@", childID as CVarArg),
                    NSPredicate(format: "entryType == %@", DiaryEntryType.wellbeing.persistenceValue)
                ])
                guard try context.count(for: wellbeingFetch) == 0 else { continue }

                let pattern = moodPatterns[index % moodPatterns.count]
                for dayOffset in 0..<7 {
                    guard let day = calendar.date(byAdding: .day, value: -(6 - dayOffset), to: today) else { continue }
                    let entry = DiaryEntry(context: context)
                    entry.id = UUID()
                    entry.child = child
                    entry.entryType = DiaryEntryType.wellbeing.persistenceValue
                    entry.moodRating = pattern[dayOffset]
                    entry.timestamp = calendar.date(byAdding: .hour, value: 9, to: day) ?? day
                    entry.notes = "Wellbeing observation"
                    entry.syncState = "synced"
                }

                if index == 0 {
                    insertTodayDiaryDemo(for: child, on: today, in: context)
                }
            }

            if context.hasChanges {
                try context.save()
            }
        } catch {
            assertionFailure("Wellbeing seed failed: \(error.localizedDescription)")
        }
    }

    /// - Description: Inserts demo secure messaging threads when the store has none.
    /// - Parameters:
    ///   - context: Managed object context.
    private static func seedDemoMessagesIfNeeded(in context: NSManagedObjectContext) {
        do {
            let threadFetch: NSFetchRequest<MessageThread> = MessageThread.fetchRequest()
            threadFetch.fetchLimit = 1
            let existing = try context.count(for: threadFetch)
            guard existing == 0 else { return }

            let childFetch: NSFetchRequest<Child> = Child.fetchRequest()
            childFetch.predicate = NSPredicate(format: "keyworkerName == %@", AppConstants.keyworkerDisplayName)
            childFetch.sortDescriptors = [NSSortDescriptor(keyPath: \Child.firstName, ascending: true)]
            let children = try context.fetch(childFetch)
            guard children.count >= 2 else { return }

            let kavi = children[0]
            let yeil = children[1]
            let broadcastChild = children.count > 2 ? children[2] : kavi
            let incidentChild = children.count > 3 ? children[3] : yeil

            let now = Date()
            let calendar = Calendar.current
            let yesterday = calendar.date(byAdding: .day, value: -1, to: now) ?? now

            // Parent thread A — fully read
            let threadA = insertThread(
                childID: kavi.id ?? UUID(),
                initiatorRole: MessageInitiatorRole.parent.persistenceValue,
                subject: "Pick-up time today",
                createdAt: yesterday,
                in: context
            )
            insertMessage(
                threadID: threadA.id ?? UUID(),
                senderRole: MessageSenderRole.parent.persistenceValue,
                senderDisplayName: "Tharani Adithya",
                body: "Could we collect Kavi at 4:15pm today? Thank you.",
                sentAt: yesterday,
                isRead: true,
                messageType: MessageType.message.persistenceValue,
                in: context
            )
            insertMessage(
                threadID: threadA.id ?? UUID(),
                senderRole: MessageSenderRole.keyworker.persistenceValue,
                senderDisplayName: AppConstants.keyworkerDisplayName,
                body: "Yes, that is fine. I will have him ready at the door.",
                sentAt: calendar.date(byAdding: .hour, value: 1, to: yesterday) ?? yesterday,
                isRead: true,
                messageType: MessageType.message.persistenceValue,
                in: context
            )

            // Parent thread B — unread inbound
            let threadB = insertThread(
                childID: yeil.id ?? UUID(),
                initiatorRole: MessageInitiatorRole.parent.persistenceValue,
                subject: "Allergy update",
                createdAt: calendar.date(byAdding: .hour, value: -2, to: now) ?? now,
                in: context
            )
            insertMessage(
                threadID: threadB.id ?? UUID(),
                senderRole: MessageSenderRole.parent.persistenceValue,
                senderDisplayName: "Lina Avyan",
                body: "Please note Yeil had a mild reaction to a new snack at home — no nursery food involved.",
                sentAt: calendar.date(byAdding: .hour, value: -2, to: now) ?? now,
                isRead: false,
                messageType: MessageType.message.persistenceValue,
                in: context
            )

            // Broadcast from Setting Manager
            let broadcastThread = insertThread(
                childID: broadcastChild.id ?? UUID(),
                initiatorRole: MessageInitiatorRole.broadcast.persistenceValue,
                subject: "Reminder: fire drill Friday 10am",
                createdAt: calendar.date(byAdding: .hour, value: -5, to: now) ?? now,
                in: context
            )
            insertMessage(
                threadID: broadcastThread.id ?? UUID(),
                senderRole: MessageSenderRole.manager.persistenceValue,
                senderDisplayName: AppConstants.settingManagerDisplayName,
                body: "Reminder: fire drill Friday 10am. Please ensure children wear coats and sensible footwear.",
                sentAt: calendar.date(byAdding: .hour, value: -5, to: now) ?? now,
                isRead: false,
                messageType: MessageType.broadcast.persistenceValue,
                in: context
            )

            // Incident notification — GDPR-safe body
            let incidentThread = insertThread(
                childID: incidentChild.id ?? UUID(),
                initiatorRole: MessageInitiatorRole.manager.persistenceValue,
                subject: "Safeguarding notification",
                createdAt: calendar.date(byAdding: .day, value: -2, to: now) ?? now,
                in: context
            )
            insertMessage(
                threadID: incidentThread.id ?? UUID(),
                senderRole: MessageSenderRole.manager.persistenceValue,
                senderDisplayName: AppConstants.settingManagerDisplayName,
                body: "A safeguarding notification has been logged for your child today. Your keyworker will contact you directly. No further details are shared in this message.",
                sentAt: calendar.date(byAdding: .day, value: -2, to: now) ?? now,
                isRead: true,
                messageType: MessageType.incidentNotification.persistenceValue,
                in: context
            )

            UserDefaults.standard.set(true, forKey: AppConstants.hasSeededDemoMessagesKey)
        } catch {
            assertionFailure("Message seeding failed: \(error.localizedDescription)")
        }
    }

    private static func insertThread(
        childID: UUID,
        initiatorRole: String,
        subject: String,
        createdAt: Date,
        in context: NSManagedObjectContext
    ) -> MessageThread {
        let thread = MessageThread(context: context)
        thread.id = UUID()
        thread.childID = childID
        thread.initiatorRole = initiatorRole
        thread.subject = subject
        thread.createdAt = createdAt
        thread.isArchived = false
        return thread
    }

    private static func insertMessage(
        threadID: UUID,
        senderRole: String,
        senderDisplayName: String,
        body: String,
        sentAt: Date,
        isRead: Bool,
        messageType: String,
        in context: NSManagedObjectContext
    ) {
        let message = Message(context: context)
        message.id = UUID()
        message.threadID = threadID
        message.senderRole = senderRole
        message.senderDisplayName = senderDisplayName
        message.body = body
        message.sentAt = sentAt
        message.isRead = isRead
        message.messageType = messageType
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

    /// - Description: Ensures legacy rows have a recurring session pattern for midnight attendance baselines.
    private static func backfillSessionWeekdaysIfNeeded(in context: NSManagedObjectContext) throws {
        let request: NSFetchRequest<Child> = Child.fetchRequest()
        request.predicate = NSCompoundPredicate(orPredicateWithSubpredicates: [
            NSPredicate(format: "sessionWeekdays == nil"),
            NSPredicate(format: "sessionWeekdays == %@", "")
        ])
        let rows = try context.fetch(request)
        for child in rows {
            child.sessionWeekdays = ChildSessionSchedule.defaultWeekdaysStorageValue
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
                sessionWeekdays: ChildSessionSchedule.defaultWeekdaysStorageValue,
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
                sessionWeekdays: ChildSessionSchedule.defaultWeekdaysStorageValue,
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
                sessionWeekdays: ChildSessionSchedule.defaultWeekdaysStorageValue,
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
                sessionWeekdays: ChildSessionSchedule.defaultWeekdaysStorageValue,
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
                sessionWeekdays: ChildSessionSchedule.defaultWeekdaysStorageValue,
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
                sessionWeekdays: ChildSessionSchedule.defaultWeekdaysStorageValue,
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
                sessionWeekdays: ChildSessionSchedule.defaultWeekdaysStorageValue,
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
                sessionWeekdays: ChildSessionSchedule.defaultWeekdaysStorageValue,
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
                sessionWeekdays: ChildSessionSchedule.defaultWeekdaysStorageValue,
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
                sessionWeekdays: ChildSessionSchedule.defaultWeekdaysStorageValue,
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
            child.sessionWeekdays = row.sessionWeekdays
        }
        seedTodayMarkedAbsentDemo(in: context)
    }

    /// - Description: Ensures several children appear checked in today so spatial catering and manager views have on-site counts.
    static func seedSpatialCateringDemoIfNeeded(in context: NSManagedObjectContext) {
        if hasOnSiteChildrenToday(in: context) { return }

        let key = "com.nurseryconnect.hasSeededSpatialCatering"
        guard !UserDefaults.standard.bool(forKey: key) else {
            seedTodayCheckInsForSpatialDemo(in: context)
            try? context.save()
            return
        }
        seedTodayCheckInsForSpatialDemo(in: context)
        try? context.save()
        UserDefaults.standard.set(true, forKey: key)
    }

    private static func hasOnSiteChildrenToday(in context: NSManagedObjectContext) -> Bool {
        let dayStart = Date().startOfDay
        let request: NSFetchRequest<AttendanceRecord> = AttendanceRecord.fetchRequest()
        request.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [
            NSPredicate(format: "dayStart == %@", dayStart as NSDate),
            NSPredicate(format: "checkInAt != nil"),
            NSPredicate(format: "checkOutAt == nil"),
            NSPredicate(format: "markedAbsent == NO")
        ])
        return ((try? context.count(for: request)) ?? 0) > 0
    }

    private static func seedTodayCheckInsForSpatialDemo(in context: NSManagedObjectContext) {
        let dayStart = Date().startOfDay
        let calendar = Calendar.current
        let checkIn = calendar.date(byAdding: .hour, value: 8, to: dayStart) ?? dayStart

        let request: NSFetchRequest<Child> = Child.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(keyPath: \Child.firstName, ascending: true)]
        request.fetchLimit = 6
        guard let children = try? context.fetch(request) else { return }

        for child in children {
            let existing: NSFetchRequest<AttendanceRecord> = AttendanceRecord.fetchRequest()
            existing.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [
                NSPredicate(format: "child == %@", child),
                NSPredicate(format: "dayStart == %@", dayStart as NSDate)
            ])
            existing.fetchLimit = 1
            if let row = try? context.fetch(existing).first {
                if row.markedAbsent { continue }
                if row.checkInAt == nil {
                    row.checkInAt = checkIn
                    row.markedAbsent = false
                }
                continue
            }
            let record = AttendanceRecord(context: context)
            record.id = UUID()
            record.dayStart = dayStart
            record.child = child
            record.checkInAt = checkIn
            record.markedAbsent = false
            record.droppedOffBy = "Demo drop-off"
        }
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

    /// - Description: Inserts meal, sleep, and activity entries for today's end-of-day summary demo.
    private static func insertTodayDiaryDemo(for child: Child, on dayStart: Date, in context: NSManagedObjectContext) {
        insertTodayCareLogDemo(for: child, on: dayStart, in: context)
        let calendar = Calendar.current

        let arrivalWellbeing = DiaryEntry(context: context)
        arrivalWellbeing.id = UUID()
        arrivalWellbeing.child = child
        arrivalWellbeing.entryType = DiaryEntryType.wellbeing.persistenceValue
        arrivalWellbeing.moodRating = 4
        arrivalWellbeing.timestamp = calendar.date(byAdding: .hour, value: 8, to: dayStart) ?? dayStart
        arrivalWellbeing.notes = "Settled quickly on arrival"
        arrivalWellbeing.syncState = "synced"
    }

    private static func insertTodayCareLogDemo(for child: Child, on dayStart: Date, in context: NSManagedObjectContext) {
        let calendar = Calendar.current

        let meal = DiaryEntry(context: context)
        meal.id = UUID()
        meal.child = child
        meal.entryType = DiaryEntryType.meal.persistenceValue
        meal.mealDescription = "Vegetable pasta"
        meal.mealConsumed = "Most"
        meal.timestamp = calendar.date(byAdding: .hour, value: 12, to: dayStart) ?? dayStart
        meal.syncState = "synced"

        let sleep = DiaryEntry(context: context)
        sleep.id = UUID()
        sleep.child = child
        sleep.entryType = DiaryEntryType.sleep.persistenceValue
        sleep.duration = 75
        sleep.timestamp = calendar.date(byAdding: .hour, value: 13, to: dayStart) ?? dayStart
        sleep.syncState = "synced"

        let activity = DiaryEntry(context: context)
        activity.id = UUID()
        activity.child = child
        activity.entryType = DiaryEntryType.activity.persistenceValue
        activity.activityType = "Outdoor play"
        activity.notes = "Explored the sand pit and water table."
        activity.timestamp = calendar.date(byAdding: .hour, value: 10, to: dayStart) ?? dayStart
        activity.syncState = "synced"
    }

    // MARK: - Spatial demo (visionOS)

    /// Positive seven-day mood scores for volumetric chart and welfare review (average ≥ 2.5).
    private static let spatialDemoMoodPattern: [Int16] = [4, 4, 5, 4, 5, 5, 5]

    /// - Description: Normalises seeded data so spatial dashboards show zero alerts, full attendance, and complete diaries.
    private static func applySpatialDemoSuccessState(in context: NSManagedObjectContext) {
        do {
            let children = try context.fetch(Child.fetchRequest())
            for child in children {
                child.photoConsent = true
            }

            try ensureAllChildrenCheckedInToday(in: context)
            try ensureSpatialWellbeingTrends(in: context)
            try ensureSpatialTodayDiariesComplete(in: context)
            try markAllMessagesRead(in: context)
            try seedSpatialEngagementMessagesIfNeeded(in: context)
            try seedSpatialDemoIncidentsIfNeeded(in: context)
        } catch {
            assertionFailure("Spatial success state failed: \(error.localizedDescription)")
        }
    }

    private static func ensureAllChildrenCheckedInToday(in context: NSManagedObjectContext) throws {
        let dayStart = Date().startOfDay
        let calendar = Calendar.current
        let checkIn = calendar.date(byAdding: .hour, value: 8, to: dayStart) ?? dayStart
        let children = try context.fetch(Child.fetchRequest())

        for child in children {
            let existing: NSFetchRequest<AttendanceRecord> = AttendanceRecord.fetchRequest()
            existing.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [
                NSPredicate(format: "child == %@", child),
                NSPredicate(format: "dayStart == %@", dayStart as NSDate)
            ])
            existing.fetchLimit = 1
            let record = try context.fetch(existing).first ?? {
                let row = AttendanceRecord(context: context)
                row.id = UUID()
                row.dayStart = dayStart
                row.child = child
                return row
            }()
            record.markedAbsent = false
            record.checkOutAt = nil
            if record.checkInAt == nil {
                record.checkInAt = checkIn
            }
            if (record.droppedOffBy ?? "").isEmpty {
                record.droppedOffBy = "Demo drop-off"
            }
        }
    }

    private static func ensureSpatialWellbeingTrends(in context: NSManagedObjectContext) throws {
        let childFetch: NSFetchRequest<Child> = Child.fetchRequest()
        childFetch.predicate = NSPredicate(format: "keyworkerName == %@", AppConstants.keyworkerDisplayName)
        childFetch.sortDescriptors = [NSSortDescriptor(keyPath: \Child.firstName, ascending: true)]
        let children = try context.fetch(childFetch)
        guard !children.isEmpty else { return }

        let calendar = Calendar.current
        let today = Date().startOfDay

        for child in children {
            let wellbeingFetch: NSFetchRequest<DiaryEntry> = DiaryEntry.fetchRequest()
            wellbeingFetch.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [
                NSPredicate(format: "child == %@", child),
                NSPredicate(format: "entryType == %@", DiaryEntryType.wellbeing.persistenceValue)
            ])
            wellbeingFetch.sortDescriptors = [NSSortDescriptor(keyPath: \DiaryEntry.timestamp, ascending: true)]
            let existing = try context.fetch(wellbeingFetch)

            if existing.isEmpty {
                for dayOffset in 0..<7 {
                    guard let day = calendar.date(byAdding: .day, value: -(6 - dayOffset), to: today) else { continue }
                    let entry = DiaryEntry(context: context)
                    entry.id = UUID()
                    entry.child = child
                    entry.entryType = DiaryEntryType.wellbeing.persistenceValue
                    entry.moodRating = spatialDemoMoodPattern[dayOffset]
                    entry.timestamp = calendar.date(byAdding: .hour, value: 9, to: day) ?? day
                    entry.notes = "Settled and engaged"
                    entry.syncState = "synced"
                }
                continue
            }

            let lastSeven = Set(Date.lastSevenCalendarDays().map(\.startOfDay))
            let inRange = existing.filter { entry in
                guard let timestamp = entry.timestamp else { return false }
                return lastSeven.contains(timestamp.startOfDay)
            }
            let grouped = Dictionary(grouping: inRange) { ($0.timestamp ?? .distantPast).startOfDay }
            let sortedDays = grouped.keys.sorted()

            if sortedDays.count < 7 {
                for entry in inRange {
                    context.delete(entry)
                }
                for dayOffset in 0..<7 {
                    guard let day = calendar.date(byAdding: .day, value: -(6 - dayOffset), to: today) else { continue }
                    let entry = DiaryEntry(context: context)
                    entry.id = UUID()
                    entry.child = child
                    entry.entryType = DiaryEntryType.wellbeing.persistenceValue
                    entry.moodRating = spatialDemoMoodPattern[dayOffset]
                    entry.timestamp = calendar.date(byAdding: .hour, value: 9, to: day) ?? day
                    entry.notes = "Settled and engaged"
                    entry.syncState = "synced"
                }
                continue
            }

            for (index, day) in sortedDays.enumerated() {
                let rating = spatialDemoMoodPattern[min(index, spatialDemoMoodPattern.count - 1)]
                for entry in grouped[day] ?? [] {
                    entry.moodRating = max(entry.moodRating, rating)
                    entry.syncState = "synced"
                }
            }
        }
    }

    private static func ensureSpatialTodayDiariesComplete(in context: NSManagedObjectContext) throws {
        let childFetch: NSFetchRequest<Child> = Child.fetchRequest()
        childFetch.predicate = NSPredicate(format: "keyworkerName == %@", AppConstants.keyworkerDisplayName)
        childFetch.sortDescriptors = [NSSortDescriptor(keyPath: \Child.firstName, ascending: true)]
        let children = try context.fetch(childFetch)
        let today = Date().startOfDay

        for child in children {
            let request: NSFetchRequest<DiaryEntry> = DiaryEntry.fetchRequest()
            request.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [
                NSPredicate(format: "child == %@", child),
                NSPredicate(format: "timestamp >= %@ AND timestamp < %@", today as NSDate, today.endOfDay as NSDate)
            ])
            let entries = try context.fetch(request)
            let types = Set(entries.compactMap { DiaryEntryType.fromPersistence($0.entryType ?? "") })
            let hasWellbeing = types.contains(.wellbeing)
            let hasCareLog = types.contains(.meal) || types.contains(.nappy) || types.contains(.activity)

            if hasWellbeing && hasCareLog { continue }

            if !hasWellbeing {
                let arrival = DiaryEntry(context: context)
                arrival.id = UUID()
                arrival.child = child
                arrival.entryType = DiaryEntryType.wellbeing.persistenceValue
                arrival.moodRating = 5
                arrival.timestamp = Calendar.current.date(byAdding: .hour, value: 8, to: today) ?? today
                arrival.notes = "Happy and settled on arrival"
                arrival.syncState = "synced"
            }

            if !hasCareLog {
                insertTodayCareLogDemo(for: child, on: today, in: context)
            }
        }
    }

    private static func markAllMessagesRead(in context: NSManagedObjectContext) throws {
        let request: NSFetchRequest<Message> = Message.fetchRequest()
        request.predicate = NSPredicate(format: "isRead == NO")
        let unread = try context.fetch(request)
        for message in unread {
            message.isRead = true
        }
    }

    /// - Description: Inserts today’s demo incidents for spatial keyworker and Setting Manager dashboards.
    private static func seedSpatialDemoIncidentsIfNeeded(in context: NSManagedObjectContext) throws {
        let check: NSFetchRequest<Incident> = Incident.fetchRequest()
        check.fetchLimit = 1
        guard try context.count(for: check) == 0 else { return }

        let childFetch: NSFetchRequest<Child> = Child.fetchRequest()
        childFetch.sortDescriptors = [NSSortDescriptor(keyPath: \Child.firstName, ascending: true)]
        let children = try context.fetch(childFetch)
        func child(named firstName: String) -> Child? {
            children.first { $0.firstName == firstName }
        }

        guard let kavi = child(named: "Kavindu"),
              let yeil = child(named: "Yeil"),
              let theo = child(named: "Theo") else { return }

        let calendar = Calendar.current
        let today = Date().startOfDay

        insertSpatialDemoIncident(
            child: kavi,
            category: "nearMiss",
            severity: "nearMiss",
            status: "managerReviewed",
            parentNotified: false,
            managerCountersigned: true,
            riddorRequired: false,
            timestamp: calendar.date(byAdding: .hour, value: 10, to: today) ?? today,
            location: "Outdoor play area",
            incidentDescription: "Child tripped on edging; no injury. Area cordoned and surface checked.",
            action: "Comforted child, brief observation, parent informed at collection.",
            in: context
        )
        insertSpatialDemoIncident(
            child: yeil,
            category: "accidentMinor",
            severity: "minor",
            status: "parentNotified",
            parentNotified: true,
            managerCountersigned: true,
            riddorRequired: false,
            timestamp: calendar.date(byAdding: .hour, value: 11, to: today) ?? today,
            location: "Sunshine Room",
            incidentDescription: "Small graze on knee during free play; cleaned and plaster applied.",
            action: "First aid completed; accident form shared with parent via secure message.",
            in: context
        )
        insertSpatialDemoIncident(
            child: theo,
            category: "accidentFirstAid",
            severity: "requiresFirstAid",
            status: "submitted",
            parentNotified: false,
            managerCountersigned: false,
            riddorRequired: false,
            timestamp: calendar.date(byAdding: .hour, value: 9, to: today) ?? today,
            location: "Soft play",
            incidentDescription: "Bump to forehead from low-height tumble; ice pack applied, child calm.",
            action: "Monitored for 20 minutes; manager review requested.",
            in: context
        )
    }

    private static func insertSpatialDemoIncident(
        child: Child,
        category: String,
        severity: String,
        status: String,
        parentNotified: Bool,
        managerCountersigned: Bool,
        riddorRequired: Bool,
        timestamp: Date,
        location: String,
        incidentDescription: String,
        action: String,
        in context: NSManagedObjectContext
    ) {
        let incident = Incident(context: context)
        incident.id = UUID()
        incident.child = child
        incident.category = category
        incident.severity = severity
        incident.status = status
        incident.timestamp = timestamp
        incident.location = location
        incident.incidentDescription = incidentDescription
        incident.immediateActionTaken = action
        incident.witnesses = "Demo keyworker on duty"
        incident.riddorRequired = riddorRequired
        incident.isParentNotified = parentNotified
        incident.managerCountersigned = managerCountersigned
        incident.syncState = "synced"
    }

    /// - Description: Spreads parent messages across the last seven days so the engagement chart is populated during spatial demos.
    private static func seedSpatialEngagementMessagesIfNeeded(in context: NSManagedObjectContext) throws {
        let childIDs = try KeyworkerGDPRScope.assignedChildIDs(in: context)
        let threadIDs = try MessagingGDPRScope.assignedThreadIDs(childIDs: childIDs, in: context)
        guard let threadID = threadIDs.first else { return }

        let calendar = Calendar.current
        let today = Date().startOfDay

        for dayOffset in 0..<7 {
            guard let day = calendar.date(byAdding: .day, value: -dayOffset, to: today) else { continue }
            let dayEnd = calendar.date(byAdding: .day, value: 1, to: day) ?? day
            let check: NSFetchRequest<Message> = Message.fetchRequest()
            check.fetchLimit = 1
            check.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [
                NSPredicate(format: "threadID == %@", threadID as CVarArg),
                NSPredicate(format: "senderRole == %@", MessageSenderRole.parent.persistenceValue),
                NSPredicate(format: "sentAt >= %@ AND sentAt < %@", day as NSDate, dayEnd as NSDate)
            ])
            guard try context.count(for: check) == 0 else { continue }

            insertMessage(
                threadID: threadID,
                senderRole: MessageSenderRole.parent.persistenceValue,
                senderDisplayName: "Demo parent",
                body: "Thanks for today's update — all good at home.",
                sentAt: calendar.date(byAdding: .hour, value: 10, to: day) ?? day,
                isRead: true,
                messageType: MessageType.message.persistenceValue,
                in: context
            )
        }
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
    let sessionWeekdays: String
    let authorisedCollectors: String
}
