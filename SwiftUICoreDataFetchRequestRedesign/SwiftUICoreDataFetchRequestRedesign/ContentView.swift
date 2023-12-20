//
//  ContentView.swift
//  SwiftUICoreDataFetchRequestRedesign
//
//  Created by Malcolm Hall on 20/12/2023.
//

import SwiftUI
import CoreData

struct ContentView: View {
    @Environment(\.managedObjectContext) private var viewContext

    @State var counter = 0
    
    var body: some View {
        HStack {
            VStack {
                Text("Launch on macOS or iPad landscape so sortable table headers appear. First click both headers to change the sort order of both tables, then click increment button. Notice Original loses the modified sort order but Redesign does not.").padding()
                    
                Button("Increment \(counter)") {
                    counter += 1
                }
                Text("Increment counter causes FetchViewOriginal and FetchViewRedesign to be re-init.").padding()
                    
            }
            
            VStack {
                Text("FetchViewOriginal")
                FetchViewOriginal()
            }
            VStack {
                Text("FetchViewRedesign")
                FetchViewRedesign()
            }
        }
            .toolbar {
#if os(iOS)
                ToolbarItem(placement: .navigationBarTrailing) {
                    EditButton()
                }
#endif
                ToolbarItem {
                    Button(action: addItem) {
                        Label("Add Item", systemImage: "plus")
                    }
                }
            }
    }

    private func addItem() {
        withAnimation {
            let newItem = Item(context: viewContext)
            newItem.timestamp = Date()

            do {
                try viewContext.save()
            } catch {
                // Replace this implementation with code to handle the error appropriately.
                // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                let nsError = error as NSError
                fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
            }
        }
    }
}

#Preview {
    ContentView().environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
