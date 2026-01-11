import Foundation
import CoreData
import CoreLocation
import MapKit

extension Area {
    convenience init(name: String, coordinates: [CLLocationCoordinate2D], context: NSManagedObjectContext) {
        self.init(context: context)
        self.id = UUID()
        self.name = name
        self.fillColor = "#FF3B30"
        self.strokeColor = "#FF9500"
        
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
    
    var polygon: MKPolygon {
        let coords = coordinatesArray
        return MKPolygon(coordinates: coords, count: coords.count)
    }
}
