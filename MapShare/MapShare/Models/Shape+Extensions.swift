import Foundation
import CoreData
import CoreLocation
import MapKit

extension Shape: MKAnnotation {
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
        emoji
    }
    
    convenience init(emoji: String, coordinate: CLLocationCoordinate2D, context: NSManagedObjectContext) {
        self.init(context: context)
        self.id = UUID()
        self.emoji = emoji
        self.latitude = coordinate.latitude
        self.longitude = coordinate.longitude
        self.createdDate = Date()
    }
}

extension Shape: MapAnnotationItem {}
