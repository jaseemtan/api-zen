//
//  CoreDataManager.swift
//  AZData
//
//  Created by Jaseem V V on 10/12/25.
//

import CoreData

/// A Core Data data manager backed by `NSFetchedResultsController` which performs the fetch. Needs to initialize with a `NSFetchRequest`.
/// The `onChange` will be triggered with the array containg the resulting entity `T`.
public class CoreDataManager<T: NSManagedObject>: NSObject, NSFetchedResultsControllerDelegate {
    private let frc: NSFetchedResultsController<T>
    private let onChange: ([T]) -> Void
    
    /// - Parameters:
    ///   - fetchRequest:
    ///     The `NSFetchRequest` for Core Data entity of type `T`, with predicates, sort descriptors, and batch size.
    ///
    ///   - ctx:
    ///     The `NSManagedObjectContext` to pick the right container.
    ///
    ///   - sectionNameKeyPath:
    ///     An optional key path used to group the fetched objects into sections. Pass `nil` if no sectioning is required.
    ///
    ///   - cacheName:
    ///     The name of the cache used by the fetched results controller to improve performance. Pass `nil` to disable caching (recommended when data changes frequently).
    ///
    ///   - onChange:
    ///     A closure that is invoked whenever the fetched results controller detects changes. The closure receives the updated array of fetched objects of type `T`.
    public init(fetchRequest: NSFetchRequest<T>, ctx: NSManagedObjectContext, sectionNameKeyPath: String? = nil, cacheName: String? = nil, onChange: @escaping ([T]) -> Void) {
        self.frc = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: ctx, sectionNameKeyPath: sectionNameKeyPath, cacheName: cacheName)
        self.onChange = onChange
        super.init()
        self.frc.delegate = self
        self.performFetch()
    }
    
    /// Update the predicate and sort descriptors and perform a fetch
    public func update(predicate: NSPredicate?, sortDescriptors: [NSSortDescriptor]) {
        let fr = frc.fetchRequest
        fr.predicate = predicate
        fr.sortDescriptors = sortDescriptors
        self.clearCache()
        self.performFetch()
    }
    
    // MARK: - Helpers
    
    /// Returns the object at the given index path.
    public func object(at indexPath: IndexPath) -> T {
        return frc.object(at: indexPath)
    }
    
    /// Returns the index path if present for the object.
    public func indexPath(for object: T) -> IndexPath? {
        return frc.indexPath(forObject: object)
    }
    
    /// Clear cache if present.
    public func clearCache() {
        if let cache = frc.cacheName {
            NSFetchedResultsController<T>.deleteCache(withName: cache)
        }
    }
    
    // MARK: - Delegates
    
    /// Delegate method which will be invoked if any data changed in the Core Data store.
    public func controllerDidChangeContent(_ controller: NSFetchedResultsController<any NSFetchRequestResult>) {
        DispatchQueue.main.async {
            self.onChange(controller.fetchedObjects as? [T] ?? [])
        }
    }
    
    // MARK: - Internal methods
    
    private func performFetch() {
        try? self.frc.performFetch()
        DispatchQueue.main.async {
            self.onChange(self.frc.fetchedObjects ?? [])
        }
    }
}
