//
//  ChildViewModel.swift
//  NurseryConnect
//
//  Feature: Children
//  Role: Keyworker
//  Created: 9 April 2026
//  Description: Fetches a single child profile for safeguarding-sensitive detail screens.
//
// -----------------------------------------------------------------
// Date       Name        What has done
// -----------------------------------------------------------------
// 090426     Tommy1914   Created the file with targeted fetch by UUID.
// -----------------------------------------------------------------

import CoreData
import Foundation

/// - Description: Loads `Child` records for profile views while keeping queries scoped.
@MainActor
final class ChildViewModel: ObservableObject {
    @Published private(set) var child: Child?
    @Published var errorMessage: String?

    private let context: NSManagedObjectContext

    /// - Description: Creates a view model for the supplied Core Data context.
    /// - Parameters:
    ///   - context: Main-queue managed object context.
    init(context: NSManagedObjectContext) {
        self.context = context
    }

    /// - Description: Fetches a child by identifier for profile presentation.
    /// - Parameters:
    ///   - id: Stable UUID primary key.
    func loadChild(id: UUID) async {
        let request: NSFetchRequest<Child> = Child.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
        request.fetchLimit = 1
        do {
            child = try context.fetch(request).first
        } catch {
            errorMessage = "Unable to load child profile."
        }
    }
}
