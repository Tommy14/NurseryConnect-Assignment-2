//
//  PersistenceController.swift
//  NurseryConnect
//
//  Feature: Core
//  Role: Keyworker
//  Created: 30 March 2026
//  Description: Owns the Core Data stack and exposes the shared managed object context.
//
// -----------------------------------------------------------------
// Date       Name        What has done
// -----------------------------------------------------------------
// 300326     Tommy1914   Created the file with shared container and in-memory preview support.
// -----------------------------------------------------------------

import CoreData
import Foundation

/// - Description: Application-wide Core Data container lifecycle for NurseryConnect.
final class PersistenceController {
    // MARK: - Shared

    /// - Description: Singleton used by the live app target.
    static let shared = PersistenceController()

    /// - Description: In-memory stack for SwiftUI previews and unit tests.
    static let preview: PersistenceController = {
        let controller = PersistenceController(inMemory: true)
        DataSeeder.seedPreviewData(in: controller.container.viewContext)
        return controller
    }()

    // MARK: - Properties

    /// - Description: Core Data persistent container for the NurseryConnect model.
    let container: NSPersistentContainer

    // MARK: - Lifecycle

    /// - Description: Creates a persistent container, optionally using an in-memory store.
    /// - Parameters:
    ///   - inMemory: When `true`, stores data only in RAM (no disk file).
    init(inMemory: Bool = false) {
        container = NSPersistentContainer(name: "NurseryConnect")
        for description in container.persistentStoreDescriptions {
            description.setOption(true as NSNumber, forKey: NSMigratePersistentStoresAutomaticallyOption)
            description.setOption(true as NSNumber, forKey: NSInferMappingModelAutomaticallyOption)
            if inMemory {
                description.url = URL(fileURLWithPath: "/dev/null")
            }
        }
        container.loadPersistentStores { _, error in
            if let error {
                // Errors are fatal in production only when the store cannot load; surfaced for debugging.
                assertionFailure("Unresolved Core Data error: \(error.localizedDescription)")
            }
        }
        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        container.viewContext.automaticallyMergesChangesFromParent = true
    }

    // MARK: - Public Methods

    /// - Description: Persists unsaved changes on the view context, mapping errors for callers.
    /// - Parameters:
    ///   - context: Context to save (typically `viewContext`).
    func save(context: NSManagedObjectContext) throws {
        guard context.hasChanges else { return }
        do {
            try context.save()
        } catch {
            throw error
        }
    }
}
