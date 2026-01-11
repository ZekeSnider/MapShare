import Foundation
import CoreData
import CoreLocation
import MapKit

extension Route {
    convenience init(name: String, coordinates: [CLLocationCoordinate2D], context: NSManagedObjectContext) {
        self.init(context: context)
        self.id = UUID()
        self.name = name
        self.strokeColor = "#FF3B30"
        self.strokeWidth = 3.0
        
        let locations = coordinates.map { CLLocation(latitude: $0.latitude, longitude: $0.longitude) }
        do {
            self.coordinates = try NSKeyedArchiver.archivedData(withRootObject: locations, requiringSecureCoding: true)
        } catch {
            print("Failed to archive coordinates: \(error)")
        }
    }

    var locations: [CLLocation] {
        guard let data = coordinates else { return [] }
        do {
            return try NSKeyedUnarchiver.unarchivedObject(ofClass: NSArray.self, from: data) as? [CLLocation] ?? []
        } catch {
            print("Failed to unarchive coordinates: \(error)")
            return []
        }
    }
    
    var coordinatesArray: [CLLocationCoordinate2D] {
        locations.map { $0.coordinate }
    }
    
    var polyline: MKPolyline {
        let coords = coordinatesArray
        return MKPolyline(coordinates: coords, count: coords.count)
    }
}
