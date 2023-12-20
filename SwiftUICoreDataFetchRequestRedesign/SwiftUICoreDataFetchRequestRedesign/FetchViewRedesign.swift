//
//  FetchViewRedesign.swift
//  SwiftUICoreDataFetchRequestRedesign
//
//  Created by Malcolm Hall on 20/12/2023.
//

import SwiftUI

struct FetchViewRedesign: View {
    @State private var sortDescriptors = [SortDescriptor(\Item.timestamp, order: .forward)]
    
    var body: some View {
        FetchMonitor(sortDescriptors: sortDescriptors) { phase in
            if let items = phase.results {
                Table(items, sortOrder: $sortDescriptors) {
                    TableColumn("timestamp", value: \.timestamp) { item in
                        Text(item.timestamp!, format: Date.FormatStyle(date: .numeric, time: .standard))
                    }
                }
            }
            else if let error = phase.error {
                Text(error.localizedDescription)
            }
            else {
                Text("Empty")
            }
        }
    }
}





#Preview {
    FetchViewRedesign()
}
