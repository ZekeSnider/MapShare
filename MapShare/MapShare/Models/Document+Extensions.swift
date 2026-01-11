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
    
    var notesArray: [Note] {
        let set = notes as? Set<Note> ?? []
        return set.sorted { $0.createdDate ?? Date() > $1.createdDate ?? Date() }
    }
    
    var shapesArray: [Shape] {
        let set = shapes as? Set<Shape> ?? []
        return set.sorted { $0.createdDate ?? Date() > $1.createdDate ?? Date() }
    }
    
    var areasArray: [Area] {
        let set = areas as? Set<Area> ?? []
        return set.sorted { $0.name ?? "" < $1.name ?? "" }
    }
    
    var routesArray: [Route] {
        let set = routes as? Set<Route> ?? []
        return set.sorted { $0.name ?? "" < $1.name ?? "" }
    }
}