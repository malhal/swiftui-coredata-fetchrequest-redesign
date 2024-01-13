//
//  FetchChangeTracker.swift
//  SwiftUICoreDataFetchRequestRedesign
//
//  Created by Malcolm Hall on 20/12/2023.
//

import SwiftUI
import CoreData
import Combine

@propertyWrapper struct FetchRequest2<ResultType>: DynamicProperty where ResultType: NSManagedObject {
    @Environment(\.managedObjectContext) private var viewContext
    @StateObject private var fetchResult = FetchResult2<ResultType>()
    
    public typealias MakeFetchRequestClosure = () -> NSFetchRequest<ResultType>
    public typealias MakeFetchedResultsControllerClosure = (NSFetchRequest<ResultType>, NSManagedObjectContext) -> NSFetchedResultsController<ResultType>
    
    // For making an initial custom fetch request, this will be reused if the frc is re-init because of context change.
    private let makeFetchRequest: MakeFetchRequestClosure?
    
    // For making a fetch controller, this will be called again if context changes. The fetch request supplied is the previous one which might have been updated after it was created.
    private let makeFetchedResultsController: MakeFetchedResultsControllerClosure?
    
    init(makeFetchRequest: MakeFetchRequestClosure? = nil, makeFetchedResultsController: MakeFetchedResultsControllerClosure? = nil) {
        self.makeFetchRequest = makeFetchRequest
        self.makeFetchedResultsController = makeFetchedResultsController
    }
    
    public var wrappedValue: FetchResult2<ResultType> {
        get {
            fetchResult
        }
    }
    
    func update() {
        // if first time or if context has changed
        if fetchResult.fetchedResultsController?.managedObjectContext != viewContext {
            // either nil when first time or get previously updated fetch request
            var fetchRequest = fetchResult.fetchedResultsController?.fetchRequest
            if fetchRequest == nil {
                // allow caller to configure initial fetch request
                fetchRequest = makeFetchRequest?()
                if fetchRequest == nil {
                    // create default fetch request
                    fetchRequest = NSFetchRequest<ResultType>(entityName: "\(ResultType.self)")
                    fetchRequest?.sortDescriptors = []
                }
            }
            // allow caller to configure a frc with custom section or cache
            var frc = makeFetchedResultsController?(fetchRequest!, viewContext)
            if frc == nil {
                // create default frc with most common options
                frc = NSFetchedResultsController<ResultType>(fetchRequest:fetchRequest!, managedObjectContext: viewContext, sectionNameKeyPath: nil, cacheName: nil)
            }
            fetchResult.fetchedResultsController = frc
        }
    }
}

class FetchResult2<ResultType>: NSObject, NSFetchedResultsControllerDelegate, ObservableObject where ResultType : NSManagedObject {

    var lastError: Error?
    fileprivate var managedObjectContext: NSManagedObjectContext?
    
    // convience for accessing the fetched objects and removing the optional
    var fetchedObjects: [ResultType] {
        fetchedResultsController?.fetchedObjects ?? []
    }
    
    // convience for accessing the sort descriptors
    var sortDescriptors: [NSSortDescriptor]? {
        get {
            fetchedResultsController?.fetchRequest.sortDescriptors
        }
        set {
            fetchedResultsController?.fetchRequest.sortDescriptors = newValue
        }
    }
    
    // convience for accessing the predicate
    var predicate: NSPredicate? {
        get {
            fetchedResultsController?.fetchRequest.predicate
        }
        set {
            fetchedResultsController?.fetchRequest.predicate = newValue
        }
    }
    
    func refetch(notify: Bool = true) {
        if let frc = fetchedResultsController {
            do {
                lastError = nil
                try frc.performFetch()
            }
            catch {
                lastError = error
            }
            if notify {
                objectWillChange.send()
            }
        }
    }
    
    var fetchedResultsController: NSFetchedResultsController<ResultType>? {
        didSet {
            oldValue?.delegate = nil
            fetchedResultsController?.delegate = self
            refetch(notify: false)
        }
    }

    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        withAnimation {
            objectWillChange.send()
        }
    }
}
