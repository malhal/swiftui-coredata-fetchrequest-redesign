//
//  FetchViewRedesign.swift
//  SwiftUICoreDataFetchRequestRedesign
//
//  Created by Malcolm Hall on 20/12/2023.
//

import SwiftUI

struct FetchViewRedesign: View {
    
    // fetch request is the source of truth and its properties are monitored
    @State private var fetchRequest: NSFetchRequest<Item>?
    
    var body: some View {
        if let fetchRequest {
            
            let sortOrder: Binding<[SortDescriptor<Item>]> = {
                Binding {
                    fetchRequest.sortDescriptors?.compactMap { nsSortDescriptor in
                        SortDescriptor(nsSortDescriptor, comparing: Item.self)
                    } ?? []
                } set: { v in
                    fetchRequest.sortDescriptors = v.map { sd in
                        NSSortDescriptor(sd)
                    }
                }
            }()
            
            
            FetchMonitor(fetchRequest: fetchRequest) { result in
                switch(result) {
                    case .success(let items):
                        Table(items, sortOrder: sortOrder) {
                            TableColumn("timestamp", value: \.timestamp) { item in
                                Text(item.timestamp!, format: Date.FormatStyle(date: .numeric, time: .standard))
                            }
                        }
                    case .failure(let error):
                        Text(error.localizedDescription)
                }
            }
        }
        else {
            Text("Loading")
                .onAppear {
                    let fr = Item.fetchRequest()
                    fr.sortDescriptors = [NSSortDescriptor(keyPath: \Item.timestamp, ascending: true)]
                    fetchRequest = fr
                }
        }
    }
}

#Preview {
    FetchViewRedesign()
}
