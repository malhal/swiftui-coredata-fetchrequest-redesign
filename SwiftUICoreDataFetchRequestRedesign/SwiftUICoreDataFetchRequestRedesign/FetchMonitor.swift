//
//  FetchChangeTracker.swift
//  SwiftUICoreDataFetchRequestRedesign
//
//  Created by Malcolm Hall on 20/12/2023.
//

import SwiftUI
import CoreData
import Combine

struct FetchMonitor<ResultType, Content>: View where ResultType: NSManagedObject, Content: View {
    @Environment(\.managedObjectContext) private var viewContext
    @StateObject private var fetchedResultsDelegate = FetchedResultsDelegate<ResultType>()
    @ViewBuilder let content: (Result<[ResultType], Error>) -> Content
    let fetchRequest: NSFetchRequest<ResultType>
    
    init(fetchRequest: NSFetchRequest<ResultType>, @ViewBuilder content: @escaping (Result<[ResultType], Error>) -> Content) {
        self.content = content
        self.fetchRequest = fetchRequest
    }
    
    func updateFetchedResultsController() {
        if fetchedResultsDelegate.fetchedResultsController?.managedObjectContext != viewContext || fetchedResultsDelegate.fetchedResultsController?.fetchRequest != fetchRequest {
            fetchedResultsDelegate.fetchedResultsController = NSFetchedResultsController<ResultType>(fetchRequest:fetchRequest, managedObjectContext: viewContext, sectionNameKeyPath: nil, cacheName: nil)
        }
    }
    
    var body: some View {
        let _ = updateFetchedResultsController()
        content(fetchedResultsDelegate.result)
    }
}

private class FetchedResultsDelegate<ResultType>: NSObject, NSFetchedResultsControllerDelegate, ObservableObject where ResultType : NSManagedObject {

    var result: Result<[ResultType], Error> = Result.failure(CocoaError.error(.validationMultipleErrors))
    var managedObjectContext: NSManagedObjectContext?
    var cancellable: Cancellable?

    static func getResult(frc: NSFetchedResultsController<ResultType>?) -> Result<[ResultType], Error> {
        var result: Result<[ResultType], Error> = .failure(CocoaError.error(.validationMultipleErrors))
        if let frc {
            do {
                try frc.performFetch()
                result = .success(frc.fetchedObjects ?? [])
            }
            catch {
                result = .failure(error)
            }
        }
        return result
    }
    
    var fetchedResultsController: NSFetchedResultsController<ResultType>? {
        didSet {
            oldValue?.delegate = nil
            fetchedResultsController?.delegate = self
            
            // set inital result
            result = Self.getResult(frc: fetchedResultsController)
            
            // setup pipeline for future results when sort or predicate are changed
            if let frc = fetchedResultsController {
                let predicateDidChange = frc.publisher(for: \.fetchRequest.predicate)
                let sortDescriptorsDidChange = frc.publisher(for: \.fetchRequest.sortDescriptors)
 
                cancellable = Publishers.CombineLatest(predicateDidChange, sortDescriptorsDidChange)
                    .dropFirst()
                    .map { a, b in
                        Self.getResult(frc: frc)
                    }
                    .sink { [weak self] r  in
                        self?.result = r
                        self?.objectWillChange.send()
                    }
            }
        }
    }

    public func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        if let frc = fetchedResultsController {
            withAnimation {
                result = .success(frc.fetchedObjects ?? [])
                objectWillChange.send()
            }
        }
    }
}
