import SwiftUI
import CoreData

@main
struct MapShareApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            DocumentListView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}