import CoreData
import CloudKit

struct PersistenceController {
    static let shared = PersistenceController()

    static var preview: PersistenceController = {
        let result = PersistenceController(inMemory: true)
        let viewContext = result.container.viewContext
        
        // Create sample data for previews
        let sampleDocument = Document(context: viewContext)
        sampleDocument.id = UUID()
        sampleDocument.name = "Sample Places"
        sampleDocument.createdDate = Date()
        sampleDocument.modifiedDate = Date()
        sampleDocument.isShared = false
        
        let samplePlace = Place(context: viewContext)
        samplePlace.id = UUID()
        samplePlace.name = "Apple Park"
        samplePlace.latitude = 37.3349
        samplePlace.longitude = -122.0090
        samplePlace.iconName = "building.2"
        samplePlace.iconColor = "#007AFF"
        samplePlace.descriptionText = "Apple's headquarters"
        samplePlace.createdDate = Date()
        samplePlace.modifiedDate = Date()
        samplePlace.document = sampleDocument

        do {
            try viewContext.save()
        } catch {
            let nsError = error as NSError
            fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
        }
        return result
    }()

    let container: NSPersistentCloudKitContainer

    init(inMemory: Bool = false) {
        container = NSPersistentCloudKitContainer(name: "MapShare")
        
        if inMemory {
            container.persistentStoreDescriptions.first!.url = URL(fileURLWithPath: "/dev/null")
        } else {
            // Configure CloudKit
            let storeDescription = container.persistentStoreDescriptions.first!
            storeDescription.setOption(true as NSNumber, forKey: NSPersistentHistoryTrackingKey)
            storeDescription.setOption(true as NSNumber, forKey: NSPersistentStoreRemoteChangeNotificationPostOptionKey)
            
            // CloudKit configuration
            storeDescription.cloudKitContainerOptions = NSPersistentCloudKitContainerOptions(containerIdentifier: "iCloud.com.mapshare.app")
        }
        
        container.loadPersistentStores { _, error in
            if let error = error as NSError? {
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        }
        
        container.viewContext.automaticallyMergesChangesFromParent = true
    }
}

extension PersistenceController {
    func save() {
        let context = container.viewContext
        
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                let nsError = error as NSError
                fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
            }
        }
    }
}