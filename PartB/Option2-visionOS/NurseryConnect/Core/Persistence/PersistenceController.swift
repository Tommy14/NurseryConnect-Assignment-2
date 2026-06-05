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
        let model = Self.loadManagedObjectModel()
        container = NSPersistentContainer(name: "NurseryConnect", managedObjectModel: model)
        for description in container.persistentStoreDescriptions {
            description.setOption(true as NSNumber, forKey: NSMigratePersistentStoresAutomaticallyOption)
            description.setOption(true as NSNumber, forKey: NSInferMappingModelAutomaticallyOption)
            if inMemory {
                // Use the dedicated Core Data in-memory store type so each test stack is isolated
                // and does not contend on a shared SQLite path under parallel test execution.
                description.type = NSInMemoryStoreType
                description.url = nil
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

    // MARK: - Private Methods

    /// - Description: Loads a single, explicit Core Data model to avoid duplicate entity resolution in tests.
    private static func loadManagedObjectModel() -> NSManagedObjectModel {
        let modelName = "NurseryConnect"
        let candidateBundles: [Bundle] = [
            Bundle(for: PersistenceController.self),
            Bundle.main
        ]

        for bundle in candidateBundles {
            if let modelURL = bundle.url(forResource: modelName, withExtension: "momd"),
               let model = NSManagedObjectModel(contentsOf: modelURL) {
                return model
            }
        }

        fatalError("Unable to locate \(modelName).momd in known bundles.")
    }
}
