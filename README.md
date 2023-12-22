# SwiftUI CoreData @FetchRequest Redesign

SwiftUI's `@FetchRequest` has an unfortunate flaw: its sort descriptors are lost if the View containing the `@FetchRequest` is re-initialized. This redesign attempts to resolve that flaw by re-implemeting it as a `View` rather than a property wrapper, similar to other data-only `View` like `ForEach`. This allows for the sort descriptors to be a `@State` source of truth in a parent `View` and passed into the fetch request to prevent them from being lost.

This repository contains a sample project that shows the original fetch request and redesign side by side and demonstrates the flaw and how it is prevented. Simply launch the project on macOS or iPad landscap (so table sort headers appear), modify the sort of both tables by clicking the headers, then click the counter increment button to cause both Views to be re-initialized.

The redesign invoves a `FetchMonitor` `View` that contains a closure that returns a `phase` similar to `AsyncImage`. It either contains the updated fetch results or an error. Internally, it has a `@StateObject` acting as the `NSFetchedResultsController` delegate. The usage of `FetchMonitor` looks like this:
```
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
```
As you can see the `sortDescriptors` are a `@State` which is not lost when this `FetchViewRedesign` is re-initialized. They are passed into the monitor and a binding is supplied to the `Table` that it sets when the user clicks on the table headers.

![Screenshot](/Screenshots/Screenshot%202023-12-20%20at%2011.17.09.png)

What if you would prefer your source of truth for the sort to be a simple boolean instead of a `SortDescriptor`? That can be done with a couple of computed properties as follows:

```
    @State var ascending = false

    var sortDescriptors: [SortDescriptor<Item>] {
        [SortDescriptor(\Item.timestamp, order: ascending ? .forward : .reverse)]
    }
    
    var sortOrder: Binding<[SortDescriptor<Item>]> {
        Binding {
            sortDescriptors
        } set: { value in
            ascending = value.first?.order == .forward
        }
    }
	...
    Button("Toggle sort") {
        ascending.toggle()
    }
	...
	FetchMonitor(sortDescriptors: sortDescriptors) { phase in
        if let results = phase.results {
            Table(results, sortOrder: sortOrder) {

```
Now you can easily change the boolean to be `@SceneStorage` or `@AppStorage` if you would like it to be persisted.