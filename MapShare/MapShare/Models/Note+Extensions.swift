import Foundation
import CoreData
import CoreLocation
import MapKit

extension Note: MKAnnotation {
    public var coordinate: CLLocationCoordinate2D {
        get {
            CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
        }
        set {
            self.latitude = newValue.latitude
            self.longitude = newValue.longitude
        }
    }

    public var title: String? {
        "Note"
    }
    
    convenience init(content: String, coordinate: CLLocationCoordinate2D, context: NSManagedObjectContext) {
        self.init(context: context)
        self.id = UUID()
        self.content = content
        self.latitude = coordinate.latitude
        self.longitude = coordinate.longitude
        self.createdDate = Date()
        self.modifiedDate = Date()
    }
}
