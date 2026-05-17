//
//  KeyworkerGDPRScope.swift
//  NurseryConnect
//
//  Feature: Core
//  Role: Keyworker
//  Created: 29 May 2026
//  Description: GDPR cohort scoping for keyworker-assigned children.
//

import CoreData
import Foundation

/// - Description: Resolves which children the logged-in keyworker may access in analytics and lists.
enum KeyworkerGDPRScope {
    /// - Description: Fetches children assigned to the demo keyworker account.
    static func assignedChildren(in context: NSManagedObjectContext) throws -> [Child] {
        let request: NSFetchRequest<Child> = Child.fetchRequest()
        request.predicate = NSPredicate(format: "keyworkerName == %@", AppConstants.keyworkerDisplayName)
        request.sortDescriptors = [NSSortDescriptor(keyPath: \Child.firstName, ascending: true)]
        return try context.fetch(request)
    }

    /// - Description: UUIDs for children assigned to the keyworker.
    static func assignedChildIDs(in context: NSManagedObjectContext) throws -> [UUID] {
        try assignedChildren(in: context).compactMap(\.id)
    }

    /// - Description: Whether the child belongs to the keyworker's assigned cohort.
    static func childBelongsToKeyworker(childID: UUID, in context: NSManagedObjectContext) throws -> Bool {
        let request: NSFetchRequest<Child> = Child.fetchRequest()
        request.fetchLimit = 1
        request.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [
            NSPredicate(format: "id == %@", childID as CVarArg),
            NSPredicate(format: "keyworkerName == %@", AppConstants.keyworkerDisplayName)
        ])
        return try context.count(for: request) > 0
    }
}
