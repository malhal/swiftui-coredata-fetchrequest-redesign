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
            fetchResult.fetchIfNecessary()
            return fetchResult
        }
    }
    
    var fetchRequest: NSFetchRequest<ResultType> {
        let r = fetchedResultsController.fetchRequest
        return r
    }
    
    var fetchedResultsController: NSFetchedResultsController<ResultType> {
        fetchResult.fetchedResultsController!
    }
    
    func update() {
        // if first time or if context has changed
        if fetchResult.fetchedResultsController?.managedObjectContext != viewContext {
            // either nil when first time or get previously updated fetch request
            let fetchRequest: NSFetchRequest<ResultType>
            if let fr = fetchResult.fetchedResultsController?.fetchRequest {
                fetchRequest = fr
            }
            else if let fr = makeFetchRequest?() {
                fetchRequest = fr
            }
            else {
                // create default fetch request
                fetchRequest = NSFetchRequest<ResultType>(entityName: "\(ResultType.self)")
                fetchRequest.sortDescriptors = []
            }
            //                }
            //            }
            // allow caller to configure a frc with custom section or cache
            var frc = makeFetchedResultsController?(fetchRequest, viewContext)
            // could check here if its delegate is non-nil and warn it will be lost.
            if frc == nil {
                // create default frc with most common options
                frc = NSFetchedResultsController<ResultType>(fetchRequest:fetchRequest, managedObjectContext: viewContext, sectionNameKeyPath: nil, cacheName: nil)
            }
            fetchResult.fetchedResultsController = frc
        }
    }
}

class FetchResult2<ResultType>: NSObject, NSFetchedResultsControllerDelegate, ObservableObject where ResultType : NSManagedObject {

    var lastError: Error?

    // a new fetch will be performed the next time this wrapped value is accessed.
    func invalidate(){
        fetchedResultsController?.delegate = nil // this is used as the invalidation flag.
        objectWillChange.send()
    }
    
    func fetchIfNecessary() {
        guard let frc = fetchedResultsController else {
            return
        }
        if frc.delegate != nil {
            return
        }
        frc.delegate = self
        do {
            lastError = nil
            try frc.performFetch()
        }
        catch {
            lastError = error
        }
    }
    
    var fetchedResultsController: NSFetchedResultsController<ResultType>? {
        didSet {
            oldValue?.delegate = nil
            fetchedResultsController?.delegate = nil // safety
        }
    }

    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        withAnimation {
            objectWillChange.send()
        }
    }
}
