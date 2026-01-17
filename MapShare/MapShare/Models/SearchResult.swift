import Foundation
import CoreLocation
import MapKit

struct SearchResult: Identifiable, Hashable {
    let id = UUID()
    let name: String
    let address: String
    let coordinate: CLLocationCoordinate2D
    let category: String?
    let phoneNumber: String?
    let url: URL?
    let mapItemIdentifier: String?

    init(mapItem: MKMapItem) {
        self.name = mapItem.name ?? "Unknown"
        self.category = mapItem.pointOfInterestCategory?.rawValue
        self.phoneNumber = mapItem.phoneNumber
        self.url = mapItem.url
        self.mapItemIdentifier = mapItem.identifier?.rawValue

        let placemark = mapItem.placemark
        var components: [String] = []

        if let street = placemark.thoroughfare {
            if let number = placemark.subThoroughfare {
                components.append("\(number) \(street)")
            } else {
                components.append(street)
            }
        }
        if let city = placemark.locality {
            components.append(city)
        }
        if let state = placemark.administrativeArea {
            components.append(state)
        }

        self.address = components.joined(separator: ", ")
        self.coordinate = mapItem.placemark.coordinate
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    static func == (lhs: SearchResult, rhs: SearchResult) -> Bool {
        lhs.id == rhs.id
    }
}
