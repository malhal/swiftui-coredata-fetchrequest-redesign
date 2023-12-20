//
//  FetchChangeTracker.swift
//  SwiftUICoreDataFetchRequestRedesign
//
//  Created by Malcolm Hall on 20/12/2023.
//

import SwiftUI

struct FetchMonitor<ResultType, Content>: View where ResultType : NSManagedObject, Content: View {
    @Environment(\.managedObjectContext) private var viewContext
    
    @StateObject private var fetchedResultsDelegate = FetchedResultsDelegate<ResultType>()
    let sortDescriptors: [SortDescriptor<ResultType>]
    let content: (FetchPhase<ResultType>) -> Content
    
    init(sortDescriptors: [SortDescriptor<ResultType>], @ViewBuilder content: @escaping (FetchPhase<ResultType>) -> Content) {
        self.sortDescriptors = sortDescriptors
        self.content = content
    }
    
    func newfetchedResultsController() -> NSFetchedResultsController<ResultType>? {
        let fr = NSFetchRequest<ResultType>(entityName: "\(ResultType.self)")
        fr.sortDescriptors = nsSortDescriptors
        let frc = NSFetchedResultsController<ResultType>(fetchRequest:fr, managedObjectContext: viewContext, sectionNameKeyPath: nil, cacheName: nil)
        return frc
    }
    
    var nsSortDescriptors: [NSSortDescriptor] {
        sortDescriptors.map { sd in
            NSSortDescriptor(sd)
        }
    }
    
    var body: some View {
        content(fetchedResultsDelegate.fetchPhase)
            .onChange(of: viewContext, initial: true) {
                fetchedResultsDelegate.fetchedResultsController = newfetchedResultsController()
            }
            .onChange(of: sortDescriptors) {
                fetchedResultsDelegate.fetchedResultsController?.fetchRequest.sortDescriptors = nsSortDescriptors
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
        if let frc = fetchedResultsController {
            let fetchPhase: FetchPhase<ResultType>
            do {
                try frc.performFetch()
                fetchPhase = .updated(frc.fetchedObjects ?? [])
            }
            catch {
                fetchPhase = .failure(error)
            }
            withAnimation {
                self.fetchPhase = fetchPhase
            }
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
