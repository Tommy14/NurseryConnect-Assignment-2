//
//  MessagingViewModelTests.swift
//  NurseryConnectTests
//
//  Feature: Messages
//  Role: Keyworker
//  Created: 29 May 2026
//  Description: Unit tests for secure messaging GDPR scope and reply rules.
//

import CoreData
import XCTest
@testable import NurseryConnect

@MainActor
final class MessagingViewModelTests: XCTestCase {
    func testCanReply_parentInitiatedThread() throws {
        let stack = PersistenceController(inMemory: true)
        let context = stack.container.viewContext
        DataSeeder.seedPreviewData(in: context)

        let thread = MessageThread(context: context)
        thread.id = UUID()
        thread.childID = try MessagingGDPRScope.assignedChildIDs(in: context).first
        thread.initiatorRole = MessageInitiatorRole.parent.persistenceValue
        thread.subject = "Test"
        thread.createdAt = Date()
        thread.isArchived = false
        try context.save()

        let vm = MessagingViewModel(context: context)
        XCTAssertTrue(vm.canReply(to: thread))
    }

    func testCanReply_broadcastThreadDenied() throws {
        let stack = PersistenceController(inMemory: true)
        let context = stack.container.viewContext

        let thread = MessageThread(context: context)
        thread.id = UUID()
        thread.childID = UUID()
        thread.initiatorRole = MessageInitiatorRole.broadcast.persistenceValue
        thread.subject = "Broadcast"
        thread.createdAt = Date()
        thread.isArchived = false

        let vm = MessagingViewModel(context: context)
        XCTAssertFalse(vm.canReply(to: thread))
    }

    func testSendReply_setsSentAt() async throws {
        let stack = PersistenceController(inMemory: true)
        let context = stack.container.viewContext
        DataSeeder.seedPreviewData(in: context)

        let childID = try MessagingGDPRScope.assignedChildIDs(in: context).first!
        let thread = MessageThread(context: context)
        let threadID = UUID()
        thread.id = threadID
        thread.childID = childID
        thread.initiatorRole = MessageInitiatorRole.parent.persistenceValue
        thread.subject = "Reply test"
        thread.createdAt = Date()
        thread.isArchived = false
        try context.save()

        let vm = MessagingViewModel(context: context)
        let before = Date()
        try vm.sendReply(threadID: threadID, body: "Hello parent")
        let after = Date()

        let request: NSFetchRequest<Message> = Message.fetchRequest()
        request.predicate = NSPredicate(format: "threadID == %@", threadID as CVarArg)
        let messages = try context.fetch(request)
        XCTAssertEqual(messages.count, 1)
        let sentAt = try XCTUnwrap(messages.first?.sentAt)
        XCTAssertGreaterThanOrEqual(sentAt, before)
        XCTAssertLessThanOrEqual(sentAt, after)
    }

    func testEndOfDaySummary_notSentBeforeThreePM() {
        var components = Calendar.current.dateComponents([.year, .month, .day], from: Date())
        components.hour = 14
        let afternoon = Calendar.current.date(from: components) ?? Date()
        XCTAssertFalse(EndOfDaySummaryAvailability.isAfterThreePM(at: afternoon))
    }

    func testEndOfDaySummary_hasSentTodayBlocksSecondSend() throws {
        let stack = PersistenceController(inMemory: true)
        let context = stack.container.viewContext
        DataSeeder.seedPreviewData(in: context)
        let childID = try MessagingGDPRScope.assignedChildIDs(in: context).first!

        let thread = MessageThread(context: context)
        thread.id = UUID()
        thread.childID = childID
        thread.initiatorRole = MessageInitiatorRole.parent.persistenceValue
        thread.subject = "EOD"
        thread.createdAt = Date()
        thread.isArchived = false

        let message = Message(context: context)
        message.id = UUID()
        message.threadID = thread.id
        message.senderRole = MessageSenderRole.keyworker.persistenceValue
        message.senderDisplayName = AppConstants.keyworkerDisplayName
        message.body = "Summary"
        message.sentAt = Date()
        message.isRead = true
        message.messageType = MessageType.endOfDaySummary.persistenceValue
        try context.save()

        XCTAssertTrue(EndOfDaySummaryAvailability.hasSentToday(childID: childID, in: context))
    }
}
