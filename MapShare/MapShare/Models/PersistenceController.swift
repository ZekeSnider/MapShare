import CoreData
internal import CloudKit

enum CloudKitConfig {
    static let containerIdentifier = "iCloud.com.zekesnider.mapshare"
}

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
            // Get the default store description
            guard let privateStoreDescription = container.persistentStoreDescriptions.first else {
                fatalError("No store descriptions found")
            }

            // Configure the private store for CloudKit
            privateStoreDescription.setOption(true as NSNumber, forKey: NSPersistentHistoryTrackingKey)
            privateStoreDescription.setOption(true as NSNumber, forKey: NSPersistentStoreRemoteChangeNotificationPostOptionKey)

            let cloudKitContainerIdentifier = CloudKitConfig.containerIdentifier
            privateStoreDescription.cloudKitContainerOptions = NSPersistentCloudKitContainerOptions(containerIdentifier: cloudKitContainerIdentifier)

            // Create a shared store description for shared data
            let sharedStoreURL = privateStoreDescription.url!.deletingLastPathComponent().appendingPathComponent("MapShare-shared.sqlite")
            let sharedStoreDescription = NSPersistentStoreDescription(url: sharedStoreURL)
            sharedStoreDescription.setOption(true as NSNumber, forKey: NSPersistentHistoryTrackingKey)
            sharedStoreDescription.setOption(true as NSNumber, forKey: NSPersistentStoreRemoteChangeNotificationPostOptionKey)

            let sharedCloudKitOptions = NSPersistentCloudKitContainerOptions(containerIdentifier: cloudKitContainerIdentifier)
            sharedCloudKitOptions.databaseScope = .shared
            sharedStoreDescription.cloudKitContainerOptions = sharedCloudKitOptions

            container.persistentStoreDescriptions = [privateStoreDescription, sharedStoreDescription]
        }

        container.loadPersistentStores { storeDescription, error in
            if let error = error as NSError? {
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
            print("Loaded store: \(storeDescription.url?.lastPathComponent ?? "unknown")")
        }

        container.viewContext.automaticallyMergesChangesFromParent = true
        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
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
