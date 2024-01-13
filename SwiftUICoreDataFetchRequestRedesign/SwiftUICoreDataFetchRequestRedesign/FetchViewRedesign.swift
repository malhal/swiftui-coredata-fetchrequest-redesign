//
//  FetchViewRedesign.swift
//  SwiftUICoreDataFetchRequestRedesign
//
//  Created by Malcolm Hall on 20/12/2023.
//

import SwiftUI

struct FetchViewRedesign: View {
    @State private var ascending = false
    
    // source of truth for the sort can easily be persisted
    //@AppStorage("Config") private var ascending = false
    
    @FetchRequest2(
//        makeFetchRequest: {
//            let fr = Item.fetchRequest()
//            fr.sortDescriptors = [NSSortDescriptor(keyPath: \Item.timestamp, ascending: true)]
//            return fr
//        }
//        makeFetchedResultsController: { fr, context in
//            let frc = NSFetchedResultsController(fetchRequest: fr, managedObjectContext: context, sectionNameKeyPath: nil, cacheName: nil)
//            return frc
//        }
    //    sortDescriptors: [], // might not need
    //    animation: .default // todo
    )
    private var result: FetchResult2<Item>
    
    // for testing body recomputation
    let counter: Int
    
    // creates a binding for the table using the ascending as source of truth.
    var sortOrder: Binding<[SortDescriptor<Item>]> {
        Binding {
            [SortDescriptor(\.timestamp, order: ascending ? .forward : .reverse)]
        } set: { v in
            ascending = v.first?.order == .forward
        }
    }
    
    var body: some View {
        Group {
            if let error = result.lastError {
                Text(error.localizedDescription)
            }
            else {
                Table(result.fetchedObjects, sortOrder: sortOrder) {
                    TableColumn("timestamp", value: \.timestamp) { item in
                        Text(item.timestamp!, format: Date.FormatStyle(date: .numeric, time: .standard))
                    }
                }
            }
        }
        .onChange(of: ascending, initial: true) {
            result.sortDescriptors = [NSSortDescriptor(keyPath: \Item.timestamp, ascending: ascending)]
            result.refetch()
        }
    }
}

#Preview {
    FetchViewRedesign(counter: 0)
}
