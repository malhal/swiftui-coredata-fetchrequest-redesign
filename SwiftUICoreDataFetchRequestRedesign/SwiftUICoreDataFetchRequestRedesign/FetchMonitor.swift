//
//  FetchChangeTracker.swift
//  SwiftUICoreDataFetchRequestRedesign
//
//  Created by Malcolm Hall on 20/12/2023.
//

import SwiftUI
import CoreData

struct FetchMonitor<ResultType, Content, NSSortDescriptorsIDType, PredicateIDType>: View where ResultType: NSManagedObject, Content: View, NSSortDescriptorsIDType: Equatable, PredicateIDType: Equatable {
    @Environment(\.managedObjectContext) private var viewContext
    
    @StateObject private var fetchedResultsDelegate = FetchedResultsDelegate<ResultType>()
    
    let nsSortDescriptorsID: NSSortDescriptorsIDType
    let predicateID: PredicateIDType
    @ViewBuilder let content: (FetchPhase<ResultType>) -> Content
    let nsSortDescriptors: () -> ([NSSortDescriptor])
    let predicate: (() -> NSPredicate)?
    
    init(nsSortDescriptorsID: NSSortDescriptorsIDType, predicateID: PredicateIDType, @ViewBuilder content: @escaping (FetchPhase<ResultType>) -> Content, nsSortDescriptors: @escaping () -> [NSSortDescriptor], predicate: (() -> (NSPredicate))? = nil) {
        self.nsSortDescriptorsID = nsSortDescriptorsID
        self.nsSortDescriptors = nsSortDescriptors
        self.predicateID = predicateID
        self.predicate = predicate
        self.content = content
    }
    
    init(nsSortDescriptorsID: NSSortDescriptorsIDType, @ViewBuilder content: @escaping (FetchPhase<ResultType>) -> Content, nsSortDescriptors: @escaping () -> [NSSortDescriptor], predicate: (() -> (NSPredicate))? = nil) where PredicateIDType == Int {
        self.init(nsSortDescriptorsID: nsSortDescriptorsID, predicateID: 0, content: content, nsSortDescriptors: nsSortDescriptors, predicate: predicate)
    }
    
    init(@ViewBuilder content: @escaping (FetchPhase<ResultType>) -> Content, nsSortDescriptors: @escaping () -> [NSSortDescriptor], predicate: (() -> (NSPredicate))? = nil) where PredicateIDType == Int, NSSortDescriptorsIDType == Int {
        self.init(nsSortDescriptorsID: 0, predicateID: 0, content: content, nsSortDescriptors: nsSortDescriptors, predicate: predicate)
    }
    
    
    // Swift SortDescriptor support
    init(sortDescriptors: [SortDescriptor<ResultType>], predicateID: PredicateIDType, @ViewBuilder content: @escaping (FetchPhase<ResultType>) -> Content, predicate: (() -> (NSPredicate))? = nil) where NSSortDescriptorsIDType == [SortDescriptor<ResultType>] {
        let nsSortDescriptors = {
            sortDescriptors.map { sd in
                NSSortDescriptor(sd)
            }
        }
        self.init(nsSortDescriptorsID: sortDescriptors, predicateID: predicateID, content: content, nsSortDescriptors: nsSortDescriptors, predicate: predicate)
    }
    
    init(sortDescriptors: [SortDescriptor<ResultType>], @ViewBuilder content: @escaping (FetchPhase<ResultType>) -> Content, predicate: (() -> (NSPredicate))? = nil) where PredicateIDType == Int, NSSortDescriptorsIDType == [SortDescriptor<ResultType>] {
        self.init(sortDescriptors: sortDescriptors, predicateID: 0, content: content, predicate: predicate)
    }
    
    func newfetchedResultsController() -> NSFetchedResultsController<ResultType>? {
        let fr = NSFetchRequest<ResultType>(entityName: "\(ResultType.self)")
        fr.sortDescriptors = nsSortDescriptors()
        fr.predicate = predicate?()
        let frc = NSFetchedResultsController<ResultType>(fetchRequest:fr, managedObjectContext: viewContext, sectionNameKeyPath: nil, cacheName: nil)
        return frc
    }
    
    var body: some View {
        content(fetchedResultsDelegate.fetchPhase)
            .onChange(of: viewContext, initial: true) {
                fetchedResultsDelegate.fetchedResultsController = newfetchedResultsController()
            }
            .onChange(of: nsSortDescriptorsID) {
                fetchedResultsDelegate.fetchedResultsController?.fetchRequest.sortDescriptors = nsSortDescriptors()
                fetchedResultsDelegate.refetch()
            }
            .onChange(of: predicateID) {
                fetchedResultsDelegate.fetchedResultsController?.fetchRequest.predicate = predicate?()
                fetchedResultsDelegate.refetch()
            }
    }
}

private class FetchedResultsDelegate<ResultType>: NSObject, NSFetchedResultsControllerDelegate, ObservableObject where ResultType : NSManagedObject {
    @Published var fetchPhase: FetchPhase<ResultType> = FetchPhase.empty
    
    var fetchedResultsController: NSFetchedResultsController<ResultType>? {
        didSet {
            oldValue?.delegate = nil
            fetchedResultsController?.delegate = self
            refetch()
        }
    }
    
    func refetch(){
        var fetchPhase = FetchPhase<ResultType>.empty
        if let frc = fetchedResultsController {
            do {
                try frc.performFetch()
                fetchPhase = .updated(frc.fetchedObjects ?? [])
            }
            catch {
                fetchPhase = .failure(error)
            }
        }
        withAnimation {
            self.fetchPhase = fetchPhase
        }
    }
    
    public func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        withAnimation {
            fetchPhase = .updated(fetchedResultsController?.fetchedObjects ?? [])
        }
    }
}

enum FetchPhase<ResultType> where ResultType : NSManagedObject {
    case empty
    case failure(Error)
    case updated([ResultType])
    
    var results: [ResultType]? {
        switch self {
            case .updated(let results):
                return results
            default:
                return nil
        }
    }
    
    var error: Error? {
        switch self {
            case .failure(let error):
                return error
            default:
                return nil
        }
    }
}
