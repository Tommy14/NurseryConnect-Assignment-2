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
            seedDemoWellbeingIfNeeded(in: context)
            seedHistoricalDiaryEntries(in: context)
            seedMilestonesIfNeeded(in: context)
            seedExtendedMessagesIfNeeded(in: context)
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
                [5, 4, 4, 3, 3, 4, 5],
                [4, 4, 5, 4, 4, 5, 5],
                [3, 4, 4, 5, 5, 4, 4],
                [5, 5, 4, 4, 5, 5, 5],
                [4, 3, 4, 3, 4, 4, 5],
                [3, 4, 5, 5, 4, 3, 4],
                [5, 4, 3, 4, 5, 5, 4],
                [4, 4, 4, 5, 4, 4, 5]
            ]

            for (index, child) in children.enumerated() {
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
                    entry.notes = demoWellbeingNote(for: pattern[dayOffset])
                    entry.syncState = "synced"
                }

                insertTodayDiaryDemo(for: child, on: today, in: context)
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
        let firstName = child.firstName ?? ""

        func at(_ hour: Int, _ minute: Int = 0) -> Date {
            let base = calendar.date(byAdding: .hour, value: hour, to: dayStart) ?? dayStart
            return calendar.date(byAdding: .minute, value: minute, to: base) ?? base
        }

        let breakfast = DiaryEntry(context: context)
        breakfast.id = UUID()
        breakfast.child = child
        breakfast.entryType = DiaryEntryType.meal.persistenceValue
        breakfast.mealDescription = childBreakfastDescription(for: firstName)
        breakfast.mealConsumed = "all"
        breakfast.timestamp = at(8, 30)
        breakfast.syncState = "synced"

        let morningSnack = DiaryEntry(context: context)
        morningSnack.id = UUID()
        morningSnack.child = child
        morningSnack.entryType = DiaryEntryType.meal.persistenceValue
        morningSnack.mealDescription = "Fresh fruit pieces and water"
        morningSnack.mealConsumed = "most"
        morningSnack.timestamp = at(10, 30)
        morningSnack.syncState = "synced"

        let morningActivity = DiaryEntry(context: context)
        morningActivity.id = UUID()
        morningActivity.child = child
        morningActivity.entryType = DiaryEntryType.activity.persistenceValue
        morningActivity.activityType = childMorningActivity(for: firstName)
        morningActivity.notes = childMorningActivityNote(for: firstName)
        morningActivity.timestamp = at(10)
        morningActivity.syncState = "synced"

        let lunch = DiaryEntry(context: context)
        lunch.id = UUID()
        lunch.child = child
        lunch.entryType = DiaryEntryType.meal.persistenceValue
        lunch.mealDescription = childLunchDescription(for: firstName)
        lunch.mealConsumed = "most"
        lunch.timestamp = at(12)
        lunch.syncState = "synced"

        let sleep = DiaryEntry(context: context)
        sleep.id = UUID()
        sleep.child = child
        sleep.entryType = DiaryEntryType.sleep.persistenceValue
        sleep.duration = childSleepDuration(for: firstName)
        sleep.sleepPosition = "Back"
        sleep.timestamp = at(13)
        sleep.syncState = "synced"

        let afternoonActivity = DiaryEntry(context: context)
        afternoonActivity.id = UUID()
        afternoonActivity.child = child
        afternoonActivity.entryType = DiaryEntryType.activity.persistenceValue
        afternoonActivity.activityType = childAfternoonActivity(for: firstName)
        afternoonActivity.notes = childAfternoonActivityNote(for: firstName)
        afternoonActivity.timestamp = at(14)
        afternoonActivity.syncState = "synced"

        let afternoonSnack = DiaryEntry(context: context)
        afternoonSnack.id = UUID()
        afternoonSnack.child = child
        afternoonSnack.entryType = DiaryEntryType.meal.persistenceValue
        afternoonSnack.mealDescription = childAfternoonSnack(for: firstName)
        afternoonSnack.mealConsumed = "most"
        afternoonSnack.timestamp = at(15)
        afternoonSnack.syncState = "synced"

        if childNeedsNappyLog(firstName: firstName) {
            let nappy1 = DiaryEntry(context: context)
            nappy1.id = UUID()
            nappy1.child = child
            nappy1.entryType = DiaryEntryType.nappy.persistenceValue
            nappy1.nappyType = "wet"
            nappy1.timestamp = at(11)
            nappy1.notes = "Nappy changed after morning play."
            nappy1.syncState = "synced"

            let nappy2 = DiaryEntry(context: context)
            nappy2.id = UUID()
            nappy2.child = child
            nappy2.entryType = DiaryEntryType.nappy.persistenceValue
            nappy2.nappyType = "dirty"
            nappy2.timestamp = at(13, 15)
            nappy2.notes = "Nappy changed after lunch."
            nappy2.syncState = "synced"
        }
    }

    private static func childBreakfastDescription(for firstName: String) -> String {
        switch firstName {
        case "Kavindu": return "Porridge with banana (vegetarian)"
        case "Yeil": return "Halal toast with spread and orange juice"
        case "Ayaan": return "Porridge with blueberries (egg-free)"
        case "Jithev": return "Dairy-free cereal with oat milk"
        case "Sara": return "Wholegrain toast with dairy-free spread"
        case "Nila": return "Fruit toast — sesame-free bread"
        case "Luca": return "Porridge with mixed berries"
        case "Amara": return "Halal toast fingers with fresh fruit"
        case "Theo": return "Scrambled eggs on wholegrain toast"
        case "Mina": return "Vegetarian breakfast muffin"
        default: return "Toast and fresh fruit"
        }
    }

    private static func childLunchDescription(for firstName: String) -> String {
        switch firstName {
        case "Kavindu": return "Vegetable pasta bake (vegetarian)"
        case "Yeil": return "Halal chicken and rice with peas"
        case "Ayaan": return "Cheese and tomato sandwich (egg-free bread)"
        case "Jithev": return "Dairy-free jacket potato with beans"
        case "Sara": return "Vegetable minestrone with crusty bread"
        case "Nila": return "Noodle stir-fry — sesame-free sauce"
        case "Luca": return "Tuna pasta salad"
        case "Amara": return "Halal chicken wrap with salad"
        case "Theo": return "Beef and vegetable stew with mash"
        case "Mina": return "Vegetarian lentil soup with bread"
        default: return "Vegetable pasta"
        }
    }

    private static func childAfternoonSnack(for firstName: String) -> String {
        switch firstName {
        case "Jithev": return "Dairy-free rice cakes with hummus"
        case "Sara": return "Dairy-free crackers and fruit"
        case "Nila": return "Breadsticks and dip — sesame-free"
        case "Mina": return "Vegetarian oat biscuits"
        default: return "Crackers and hummus with apple slices"
        }
    }

    private static func childMorningActivity(for firstName: String) -> String {
        switch firstName {
        case "Kavindu": return "Outdoor Play"
        case "Yeil": return "Indoor Play"
        case "Ayaan": return "Arts & Crafts"
        case "Jithev": return "Free Play"
        case "Sara": return "Educational"
        case "Nila": return "Free Play"
        case "Luca": return "Outdoor Play"
        case "Amara": return "Reading"
        case "Theo": return "Outdoor Play"
        case "Mina": return "Educational"
        default: return "Free Play"
        }
    }

    private static func childMorningActivityNote(for firstName: String) -> String {
        switch firstName {
        case "Kavindu": return "Sand pit and water table — great imaginative play with peers."
        case "Yeil": return "Block tower building — stacked to record room height, beaming with pride."
        case "Ayaan": return "Handprint butterfly craft using poster paint — loved the process."
        case "Jithev": return "Small-world play with farm animals on the mat."
        case "Sara": return "Number sorting with coloured cups — identified all correctly."
        case "Nila": return "Kitchen role-play — took on the 'chef' role with confidence."
        case "Luca": return "Balance beam and climbing frame challenge — great persistence."
        case "Amara": return "Group story time — attentive listener, asked great questions."
        case "Theo": return "Obstacle course — tunnels, balance beam, and jump station."
        case "Mina": return "Shape sorting and colour matching activity — worked independently."
        default: return "Engaged in morning activity."
        }
    }

    private static func childAfternoonActivity(for firstName: String) -> String {
        switch firstName {
        case "Kavindu": return "Arts & Crafts"
        case "Yeil": return "Educational"
        case "Ayaan": return "Outdoor Play"
        case "Jithev": return "Reading"
        case "Sara": return "Free Play"
        case "Nila": return "Arts & Crafts"
        case "Luca": return "Educational"
        case "Amara": return "Free Play"
        case "Theo": return "Indoor Play"
        case "Mina": return "Reading"
        default: return "Free Play"
        }
    }

    private static func childAfternoonActivityNote(for firstName: String) -> String {
        switch firstName {
        case "Kavindu": return "Leaf-print collage — wonderful concentration and fine-motor control."
        case "Yeil": return "Counting beads on wire — matched numbers 1–5 independently."
        case "Ayaan": return "Garden exploration — watered the plants and named three flowers."
        case "Jithev": return "Bedtime story books in the reading corner — chose three books."
        case "Sara": return "Dance and movement session — incredibly enthusiastic and joyful."
        case "Nila": return "Self-portrait painting — detailed features and expressive use of colour."
        case "Luca": return "Weather chart discussion — described seasons with confidence."
        case "Amara": return "Retold 'Goldilocks' with puppets — excellent vocabulary and structure."
        case "Theo": return "Drum and rhythm session — maintained a steady beat, loved it."
        case "Mina": return "Phonics picture-matching cards — recognised five letter sounds."
        default: return "Engaged in afternoon session."
        }
    }

    private static func childSleepDuration(for firstName: String) -> Int32 {
        switch firstName {
        case "Kavindu": return 60
        case "Yeil": return 90
        case "Ayaan": return 75
        case "Jithev": return 90
        case "Sara": return 80
        case "Nila": return 60
        case "Luca": return 45
        case "Amara": return 30
        case "Theo": return 70
        case "Mina": return 65
        default: return 60
        }
    }

    private static func childNeedsNappyLog(firstName: String) -> Bool {
        ["Ayaan", "Jithev", "Sara", "Theo"].contains(firstName)
    }

    private static func demoWellbeingNote(for rating: Int16) -> String {
        switch rating {
        case 5: return "Bright and energetic — wonderful mood all session."
        case 4: return "Settled and content throughout the morning."
        case 3: return "Calm; needed some gentle reassurance on arrival."
        case 2: return "Quieter than usual; monitored closely and offered comfort."
        default: return "Wellbeing observation recorded."
        }
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

    // MARK: - Historical diary entries (past 6 days)

    private static func seedHistoricalDiaryEntries(in context: NSManagedObjectContext) {
        do {
            let childFetch: NSFetchRequest<Child> = Child.fetchRequest()
            childFetch.predicate = NSPredicate(format: "keyworkerName == %@", AppConstants.keyworkerDisplayName)
            childFetch.sortDescriptors = [NSSortDescriptor(keyPath: \Child.firstName, ascending: true)]
            let children = try context.fetch(childFetch)
            guard !children.isEmpty else { return }

            let calendar = Calendar.current
            let today = Date().startOfDay

            let histMeals = [
                "Vegetable pasta bake", "Halal chicken and rice with peas",
                "Fish pie and garden peas", "Jacket potato with baked beans",
                "Tomato and lentil soup with bread", "Mac and cheese (vegetarian)",
                "Vegetable curry and basmati rice"
            ]
            let histActivities: [(String, String)] = [
                ("Outdoor Play", "Playground session — swings and slide with friends."),
                ("Arts & Crafts", "Sponge painting with seasonal colours."),
                ("Reading", "Group story — 'The Very Hungry Caterpillar'."),
                ("Indoor Play", "Foam block construction — cooperative build."),
                ("Educational", "Colour and shape sorting on the carpet."),
                ("Free Play", "Home corner role-play — shops and cooking."),
                ("Outdoor Play", "Ball games and parachute in the garden.")
            ]
            let sleepDurations: [Int32] = [45, 60, 75, 90, 60, 70]
            let sleepPositions = ["Back", "Side", "Back", "Back", "Side", "Back"]

            for dayOffset in 1...6 {
                guard let historicalDay = calendar.date(byAdding: .day, value: -dayOffset, to: today) else { continue }
                let dayEnd = calendar.date(byAdding: .day, value: 1, to: historicalDay) ?? historicalDay

                for (childIndex, child) in children.enumerated() {
                    let existingCheck: NSFetchRequest<DiaryEntry> = DiaryEntry.fetchRequest()
                    existingCheck.fetchLimit = 1
                    existingCheck.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [
                        NSPredicate(format: "child == %@", child),
                        NSPredicate(format: "entryType == %@", DiaryEntryType.meal.persistenceValue),
                        NSPredicate(format: "timestamp >= %@ AND timestamp < %@",
                                    historicalDay as NSDate, dayEnd as NSDate)
                    ])
                    guard try context.count(for: existingCheck) == 0 else { continue }

                    let mealIndex = (childIndex + dayOffset) % histMeals.count
                    let actIndex = (childIndex + dayOffset + 1) % histActivities.count

                    let meal = DiaryEntry(context: context)
                    meal.id = UUID()
                    meal.child = child
                    meal.entryType = DiaryEntryType.meal.persistenceValue
                    meal.mealDescription = histMeals[mealIndex]
                    meal.mealConsumed = dayOffset % 2 == 0 ? "all" : "most"
                    meal.timestamp = calendar.date(byAdding: .hour, value: 12, to: historicalDay) ?? historicalDay
                    meal.syncState = "synced"

                    let snack = DiaryEntry(context: context)
                    snack.id = UUID()
                    snack.child = child
                    snack.entryType = DiaryEntryType.meal.persistenceValue
                    snack.mealDescription = "Fresh fruit pieces"
                    snack.mealConsumed = "most"
                    snack.timestamp = calendar.date(byAdding: .hour, value: 10, to: historicalDay) ?? historicalDay
                    snack.syncState = "synced"

                    let (actType, actNote) = histActivities[actIndex]
                    let activity = DiaryEntry(context: context)
                    activity.id = UUID()
                    activity.child = child
                    activity.entryType = DiaryEntryType.activity.persistenceValue
                    activity.activityType = actType
                    activity.notes = actNote
                    activity.timestamp = calendar.date(byAdding: .hour, value: 10, to: historicalDay) ?? historicalDay
                    activity.syncState = "synced"

                    let sleepEntry = DiaryEntry(context: context)
                    sleepEntry.id = UUID()
                    sleepEntry.child = child
                    sleepEntry.entryType = DiaryEntryType.sleep.persistenceValue
                    sleepEntry.duration = sleepDurations[(childIndex + dayOffset) % sleepDurations.count]
                    sleepEntry.sleepPosition = sleepPositions[dayOffset % sleepPositions.count]
                    sleepEntry.timestamp = calendar.date(byAdding: .hour, value: 13, to: historicalDay) ?? historicalDay
                    sleepEntry.syncState = "synced"

                    let firstName = child.firstName ?? ""
                    if childNeedsNappyLog(firstName: firstName) {
                        let nappy = DiaryEntry(context: context)
                        nappy.id = UUID()
                        nappy.child = child
                        nappy.entryType = DiaryEntryType.nappy.persistenceValue
                        nappy.nappyType = dayOffset % 2 == 0 ? "wet" : "dirty"
                        nappy.timestamp = calendar.date(byAdding: .hour, value: 11, to: historicalDay) ?? historicalDay
                        nappy.syncState = "synced"
                    }
                }
            }

            if context.hasChanges {
                try context.save()
            }
        } catch {
            assertionFailure("Historical diary seeding failed: \(error.localizedDescription)")
        }
    }

    // MARK: - Milestones

    private static func seedMilestonesIfNeeded(in context: NSManagedObjectContext) {
        do {
            let check: NSFetchRequest<DiaryEntry> = DiaryEntry.fetchRequest()
            check.predicate = NSPredicate(format: "entryType == %@", DiaryEntryType.milestone.persistenceValue)
            check.fetchLimit = 1
            guard try context.count(for: check) == 0 else { return }

            let childFetch: NSFetchRequest<Child> = Child.fetchRequest()
            childFetch.predicate = NSPredicate(format: "keyworkerName == %@", AppConstants.keyworkerDisplayName)
            childFetch.sortDescriptors = [NSSortDescriptor(keyPath: \Child.firstName, ascending: true)]
            let children = try context.fetch(childFetch)
            guard !children.isEmpty else { return }

            let calendar = Calendar.current
            let today = Date().startOfDay

            // (hourOfDay, eyfsArea, milestoneTitle, observationNote) — all seeded today so MilestoneEntriesView shows them
            let allMilestones: [[(Int, String, String, String)]] = [
                // Kavindu
                [(9,  "Communication and language", "First nursery song solo",
                  "Sang 'Twinkle Twinkle' to the group unprompted — superb confidence."),
                 (11, "Personal, social and emotional", "Shared toy independently",
                  "Handed the train to a peer without being asked — a lovely moment."),
                 (14, "Literacy", "Recognised own name on peg",
                  "Found his name card at coat pegs correctly on first attempt.")],
                // Yeil
                [(9,  "Expressive arts and design", "Built tallest block tower",
                  "Balanced 12 blocks — new room record — beaming with pride."),
                 (11, "Mathematics", "Counted to 10 independently",
                  "Counted toy animals to 10 during tidy-up with no support."),
                 (14, "Understanding the world", "Named four seasons",
                  "Correctly labelled all four seasons from picture cards.")],
                // Ayaan
                [(9,  "Physical development", "Climbed full climbing frame",
                  "Completed the outdoor frame with safety — huge confidence boost."),
                 (11, "Communication and language", "Began asking 'why?' questions",
                  "Started asking purposeful questions during outdoor walks."),
                 (14, "Expressive arts and design", "First detailed self-portrait",
                  "Named every feature in her painting — great body awareness.")],
                // Jithev
                [(9,  "Personal, social and emotional", "First successful goodbye wave",
                  "Waved goodbye to parent without tears — major milestone for him."),
                 (11, "Communication and language", "Named five colours correctly",
                  "Sorted bricks by colour and named each one clearly."),
                 (14, "Physical development", "Walked along balance beam",
                  "Crossed the full balance beam without stepping off — great focus.")],
                // Sara
                [(9,  "Expressive arts and design", "Led a group dance session",
                  "Choreographed a short routine and guided three peers confidently."),
                 (11, "Literacy", "Wrote first two name letters independently",
                  "Formed 'Sa' with pencil unprompted — strong grip control."),
                 (14, "Mathematics", "Sorted by two attributes simultaneously",
                  "Sorted coloured shapes by colour AND size — impressive logic.")],
                // Nila
                [(9,  "Literacy", "Held book and retold story",
                  "Held picture book correctly and described each page in sequence."),
                 (11, "Personal, social and emotional", "Comforted a distressed peer",
                  "Noticed a friend was upset and brought her a comfort toy unprompted."),
                 (14, "Communication and language", "Joined group circle-time discussion",
                  "Raised hand and contributed a full sentence to circle-time.")],
                // Luca
                [(9,  "Mathematics", "Counted backwards from 5",
                  "During rocket launch play counted '5-4-3-2-1' correctly and independently."),
                 (11, "Understanding the world", "Explained plant life cycle",
                  "Described how seeds grow after our garden project — excellent recall."),
                 (14, "Physical development", "Confident on full balance beam",
                  "Crossed beam arms-out, smooth and controlled — no wobbles.")],
                // Amara
                [(9,  "Communication and language", "Seven-word spontaneous sentence",
                  "'I want to build a really big castle today please' — beautiful structure."),
                 (11, "Literacy", "Recognised five phonics sounds",
                  "Identified s, a, t, p, i from letter cards with no prompting."),
                 (14, "Personal, social and emotional", "Organised group role-play",
                  "Invited five friends into a 'supermarket' role-play and assigned roles.")],
                // Theo
                [(9,  "Physical development", "Completed obstacle course unaided",
                  "Ran, balanced, and jumped through the full course independently."),
                 (11, "Expressive arts and design", "Maintained a steady drum beat",
                  "Held a pulse for 30 seconds with eyes closed — impressive focus."),
                 (14, "Personal, social and emotional", "Waited turns in a board game",
                  "Waited patiently through four turns in a row — great impulse control.")],
                // Mina
                [(9,  "Literacy", "Recognised letter M independently",
                  "Spotted 'M' on labels and books across the room — 'that's mine!'"),
                 (11, "Mathematics", "Sorted objects by three sizes",
                  "Arranged small, medium, and large items correctly without prompting."),
                 (14, "Communication and language", "Told a three-part story",
                  "Beginning, middle, and end — all present and clearly sequenced.")],
            ]

            for (childIndex, child) in children.enumerated() {
                let milestones = allMilestones[childIndex % allMilestones.count]
                for (hour, eyfsArea, title, notes) in milestones {
                    let entry = DiaryEntry(context: context)
                    entry.id = UUID()
                    entry.child = child
                    entry.entryType = DiaryEntryType.milestone.persistenceValue
                    entry.eyfsArea = eyfsArea
                    entry.notes = "[\(title)] \(notes)"
                    entry.timestamp = calendar.date(byAdding: .hour, value: hour, to: today) ?? today
                    entry.syncState = "synced"
                }
            }

            if context.hasChanges {
                try context.save()
            }
        } catch {
            assertionFailure("Milestone seeding failed: \(error.localizedDescription)")
        }
    }

    // MARK: - Extended messaging (children 5–10)

    private static func seedExtendedMessagesIfNeeded(in context: NSManagedObjectContext) {
        do {
            let childFetch: NSFetchRequest<Child> = Child.fetchRequest()
            childFetch.predicate = NSPredicate(format: "keyworkerName == %@", AppConstants.keyworkerDisplayName)
            childFetch.sortDescriptors = [NSSortDescriptor(keyPath: \Child.firstName, ascending: true)]
            let children = try context.fetch(childFetch)
            guard children.count >= 5 else { return }

            let calendar = Calendar.current
            let now = Date()

            struct ExtendedThread {
                let childIndex: Int
                let subject: String
                let initiator: String
                let messages: [(role: String, name: String, body: String, hoursAgo: Double, isRead: Bool)]
            }

            let threads: [ExtendedThread] = [
                ExtendedThread(
                    childIndex: 4, subject: "Sara — absence note for Monday",
                    initiator: "parent",
                    messages: [
                        ("parent", "Elena Tiana",
                         "Good morning! Sara has a cold and won't be in on Monday. Thank you for your understanding.", -48, true),
                        ("keyworker", AppConstants.keyworkerDisplayName,
                         "Thank you for letting us know — hope Sara feels better soon! We will note her absence and look forward to seeing her back.", -47, true),
                        ("parent", "Elena Tiana",
                         "Thank you so much. She is already improving and asking about her nursery friends!", -46, true)
                    ]
                ),
                ExtendedThread(
                    childIndex: 5, subject: "Nila — Tuesday dance class reminder",
                    initiator: "parent",
                    messages: [
                        ("parent", "Ishani Fernando",
                         "Hi, just a reminder that Nila has dance class after nursery every Tuesday. Her dance bag will be with her.", -36, true),
                        ("keyworker", AppConstants.keyworkerDisplayName,
                         "Noted — thank you! We will make sure Nila has her bag ready for collection. Looking forward to hearing how she gets on.", -35, true)
                    ]
                ),
                ExtendedThread(
                    childIndex: 6, subject: "Luca — potty training support",
                    initiator: "parent",
                    messages: [
                        ("parent", "Sofia Martins",
                         "Hello! We have started potty training at home this week. Could you please support this at nursery too?", -24, true),
                        ("keyworker", AppConstants.keyworkerDisplayName,
                         "Absolutely — well done Luca! We will follow his lead and offer gentle prompts. Please send spare clothes in his bag each day.", -23, true),
                        ("parent", "Sofia Martins",
                         "Perfect, thank you so much! A spare set is already in his bag. He is so proud of himself.", -22, true),
                        ("keyworker", AppConstants.keyworkerDisplayName,
                         "Wonderful — he should be! We will keep you updated on how he gets on here.", -21, true)
                    ]
                ),
                ExtendedThread(
                    childIndex: 7, subject: "Amy — SALT appointment early collection",
                    initiator: "parent",
                    messages: [
                        ("parent", "Farah Khan",
                         "Hi, Amy has her speech and language therapy appointment tomorrow at 2pm. We will need to collect her at 1:45pm please.", -5, false)
                    ]
                ),
                ExtendedThread(
                    childIndex: 8, subject: "Theo — learning journal feedback",
                    initiator: "parent",
                    messages: [
                        ("parent", "Chloe Bennett",
                         "We just saw the learning journal update — Theo has been so excited about the obstacle course at nursery! Thank you for capturing that.", -3, false)
                    ]
                ),
                ExtendedThread(
                    childIndex: 9, subject: "Mina — EpiPen care plan review",
                    initiator: "manager",
                    messages: [
                        ("manager", AppConstants.settingManagerDisplayName,
                         "Reminder: Mina's EpiPen and emergency care plan are due for their annual review in July 2026. Please arrange this with the family.", -72, true),
                        ("keyworker", AppConstants.keyworkerDisplayName,
                         "Understood — I will contact Priya this week to arrange the review appointment and update the plan.", -70, true)
                    ]
                ),
            ]

            for thread in threads {
                guard thread.childIndex < children.count else { continue }
                let child = children[thread.childIndex]
                guard let childID = child.id else { continue }

                let threadCheck: NSFetchRequest<MessageThread> = MessageThread.fetchRequest()
                threadCheck.fetchLimit = 1
                threadCheck.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [
                    NSPredicate(format: "childID == %@", childID as CVarArg),
                    NSPredicate(format: "subject == %@", thread.subject)
                ])
                guard try context.count(for: threadCheck) == 0 else { continue }

                let firstHoursAgo = thread.messages.first?.hoursAgo ?? -1
                let createdAt = calendar.date(byAdding: .second, value: Int(firstHoursAgo * 3600), to: now) ?? now
                let initiatorRole = MessageInitiatorRole(rawValue: thread.initiator)?.persistenceValue
                    ?? MessageInitiatorRole.parent.persistenceValue

                let newThread = insertThread(
                    childID: childID,
                    initiatorRole: initiatorRole,
                    subject: thread.subject,
                    createdAt: createdAt,
                    in: context
                )

                for msg in thread.messages {
                    let sentAt = calendar.date(byAdding: .second, value: Int(msg.hoursAgo * 3600), to: now) ?? now
                    let senderRole = MessageSenderRole(rawValue: msg.role)?.persistenceValue
                        ?? MessageSenderRole.keyworker.persistenceValue
                    insertMessage(
                        threadID: newThread.id ?? UUID(),
                        senderRole: senderRole,
                        senderDisplayName: msg.name,
                        body: msg.body,
                        sentAt: sentAt,
                        isRead: msg.isRead,
                        messageType: MessageType.message.persistenceValue,
                        in: context
                    )
                }
            }

            if context.hasChanges {
                try context.save()
            }
        } catch {
            assertionFailure("Extended messages seeding failed: \(error.localizedDescription)")
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
