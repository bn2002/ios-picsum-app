//
//  CoreDataStack.swift
//  PicsumApp
//
//  Created by Doanh on 19/5/25.
//
import Foundation
import CoreData

final class CoreDataStack {
    static let shared = CoreDataStack()
    
    private let modelName = "Model"
    
    // MARK: - Core Data stack
    private(set) lazy var persistentContainer: NSPersistentContainer = {
        let container = NSPersistentContainer(name: modelName)
        container.loadPersistentStores { _, error in
            if let error = error {
                fatalError("Failed to load Core Data stack: \(error)")
            }
        }
        return container
    }()
    
    var mainContext: NSManagedObjectContext {
        return self.persistentContainer.viewContext
    }
    
    func newBackgroundContext() -> NSManagedObjectContext {
        return self.persistentContainer.newBackgroundContext()
    }
}
