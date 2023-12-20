//
//  TableView.swift
//  SwiftUICoreDataFetchRequestRedesign
//
//  Created by Malcolm Hall on 20/12/2023.
//

import SwiftUI

struct FetchViewOriginal: View {
    @Environment(\.managedObjectContext) private var viewContext
    
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Item.timestamp, ascending: true)],
        animation: .default)
    private var items: FetchedResults<Item>
    
    var body: some View {
        Table(items, sortOrder: $items.sortDescriptors) {
            TableColumn("timestamp", value: \.timestamp) { item in
                Text(item.timestamp!, format: Date.FormatStyle(date: .numeric, time: .standard))
            }
        }
    }
}

#Preview {
    FetchViewOriginal()
}
