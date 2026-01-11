import Foundation
import CoreLocation
import MapKit

protocol MapAnnotationItem: Identifiable {
    var id: UUID? { get }
    var coordinate: CLLocationCoordinate2D { get }
}

extension Place: MapAnnotationItem {}
extension Note: MapAnnotationItem {}
