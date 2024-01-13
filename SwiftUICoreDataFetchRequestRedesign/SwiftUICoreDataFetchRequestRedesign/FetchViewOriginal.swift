//
//  TableView.swift
//  SwiftUICoreDataFetchRequestRedesign
//
//  Created by Malcolm Hall on 20/12/2023.
//

import SwiftUI

struct FetchViewOriginal: View {
    @FetchRequest(
        sortDescriptors: [],
        animation: .default)
    private var items: FetchedResults<Item>
    
    // source of truth for the sort
    @State var ascending = false
    
    // for testing body recomputation
    let counter: Int
    
    var sortOrder: Binding<[SortDescriptor<Item>]> {
        Binding {
            [SortDescriptor(\.timestamp, order: ascending ? .forward : .reverse)]
        } set: { v in
            ascending = v.first?.order == .forward
        }
    }
    
    var body: some View {
        Table(items, sortOrder: sortOrder) {
            TableColumn("timestamp", value: \.timestamp) { item in
                Text(item.timestamp!, format: Date.FormatStyle(date: .numeric, time: .standard))
            }
        }
        .onChange(of: ascending, initial: true) {
            items.nsSortDescriptors = [NSSortDescriptor(keyPath: \Item.timestamp, ascending: ascending)]
        }
    }
}

#Preview {
    FetchViewOriginal(counter: 0)
}
