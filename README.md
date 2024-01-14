# SwiftUI CoreData @FetchRequest Redesign

SwiftUI's `@FetchRequest` has an unfortunate flaw: its sort descriptors are lost if the `View` containing the `@FetchRequest` is re-init. This redesign attempts to resolve that flaw by maintaining the state of the `NSFetchRequest` between `View` inits. This allows for the sort to be a `@State` source of truth in a parent `View` and used to update the fetch request. Another great feature is if the `NSManagedObjectContext` in the environment is replaced, results are updated from the new context whilst the original fetch request is maintained. The fetch error is exposed to allow to detect invalid fetches, although the use may be rather limited as core data appears to crash hard if for example an invalid predicate is supplied. Finally, the fetch request can be re-configured by multiple `onChange` modifiers without needless inbetween fetches. This is possible because the configuration can be done via the request rather than through the wrapped value which causes a fetch. To signal a new fetch is required, use the `invalidate` func on the wrapped value.

This repository contains a sample project that shows the original fetch request and redesign side by side and demonstrates the flaw and how it is prevented. Simply launch the project on macOS or iPad landscap (so table sort headers appear), modify the sort of both tables by clicking the headers, then click the counter increment button to cause both Views to be re-initialized.

The redesign invoves a `FetchRequest2` property wrapper and a `FetchResult2` wrapped value. Two closures `makeFetchRequest` and `makeFetchedResultsController` closures can be optionally supplied to the property wrapper that allow for inital configuration. `makeFetchRequest` is only ever called once and `makeFetchedResultsController` is called every time a change in the managed object context is detected. When the closures are not supplied, suitable defaults are created.  After initial configuration, the `fetchRequest` can be configured dynamically using the `.onChange` `View` modifier. The sample project does not currently use either closure and instead uses `.onChange(of:ascending initial: true)` to configure sort descriptors and refetch. This allows for the sort descriptors to only need to be configured in one place using the ascending state as the source of truth.
```
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
```

![Screenshot](/Screenshots/Screenshot%202023-12-20%20at%2011.17.09.png)