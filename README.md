# SwiftUI CoreData @FetchRequest Redesign

SwiftUI's `@FetchRequest` has an unfortunate flaw: its sort descriptors are lost if the View containing the `@FetchRequest` is re-initialized. This redesign attempts to resolve that flaw by re-implemeting it as a `View` rather than a property wrapper, similar to other data-only `View` like `ForEach`. This allows for the sort descriptors to be a `@State` source of truth in a parent `View` and passed into the fetch request to prevent them from being lost.

This repository contains a sample project that shows the original fetch request and redesign side by side and demonstrates the flaw and how it is prevented. Simply launch the project on macOS or iPad landscap (so table sort headers appear), modify the sort of both tables by clicking the headers, then click the counter increment button to cause both Views to be re-initialized.

The redesign invoves a `FetchMonitor` `View` that contains a closure that returns a `phase` similar to `AsyncImage`. It either contains the updated fetch results or an error. Internally, it has a `@StateObject` acting as the `NSFetchedResultsController` delegate. 

![Screenshot](/Screenshots/Screenshot%202023-12-20%20at%2011.17.09.png)