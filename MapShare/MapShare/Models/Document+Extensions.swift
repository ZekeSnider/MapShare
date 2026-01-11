import Foundation
import CoreData

extension Document {
    convenience init(name: String, context: NSManagedObjectContext) {
        self.init(context: context)
        self.id = UUID()
        self.name = name
        self.createdDate = Date()
        self.modifiedDate = Date()
        self.isShared = false
    }
    
    var placesArray: [Place] {
        let set = places as? Set<Place> ?? []
        return set.sorted { $0.name ?? "" < $1.name ?? "" }
    }
}