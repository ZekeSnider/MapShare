import Foundation
import CoreData
import CoreLocation
import MapKit

extension Place: MKAnnotation {
    public var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
    
    public var title: String? {
        name
    }
    
    convenience init(name: String, coordinate: CLLocationCoordinate2D, context: NSManagedObjectContext) {
        self.init(context: context)
        self.id = UUID()
        self.name = name
        self.latitude = coordinate.latitude
        self.longitude = coordinate.longitude
        self.createdDate = Date()
        self.modifiedDate = Date()
        self.iconName = "mappin"
        self.iconColor = "#FF3B30"
    }
    
    var commentsArray: [Comment] {
        let set = comments as? Set<Comment> ?? []
        return set.sorted { $0.createdDate ?? Date() > $1.createdDate ?? Date() }
    }
    
    var reactionsArray: [Reaction] {
        let set = reactions as? Set<Reaction> ?? []
        return set.sorted { $0.type ?? "" < $1.type ?? "" }
    }
    
    var thumbsUpCount: Int {
        reactionsArray.filter { $0.type == "thumbsUp" }.count
    }
    
    var thumbsDownCount: Int {
        reactionsArray.filter { $0.type == "thumbsDown" }.count
    }
}