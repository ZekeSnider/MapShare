import SwiftUI
import MapKit
import CoreData

struct MapView: View {
    let document: Document
    @Binding var selectedPlace: Place?
    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194),
        span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
    )
    
    var body: some View {
        Map(coordinateRegion: $region, annotationItems: document.placesArray) { place in
            MapAnnotation(coordinate: place.coordinate) {
                PlaceAnnotationView(place: place) {
                    selectedPlace = place
                }
            }
        }
        .onAppear {
            centerMapOnPlaces()
        }
    }
    
    private func centerMapOnPlaces() {
        let places = document.placesArray
        guard !places.isEmpty else { return }
        
        let coordinates = places.map { $0.coordinate }
        let centerLatitude = coordinates.reduce(0) { $0 + $1.latitude } / Double(coordinates.count)
        let centerLongitude = coordinates.reduce(0) { $0 + $1.longitude } / Double(coordinates.count)
        
        let minLat = coordinates.map { $0.latitude }.min() ?? centerLatitude
        let maxLat = coordinates.map { $0.latitude }.max() ?? centerLatitude
        let minLon = coordinates.map { $0.longitude }.min() ?? centerLongitude
        let maxLon = coordinates.map { $0.longitude }.max() ?? centerLongitude
        
        let latDelta = max(0.01, (maxLat - minLat) * 1.5)
        let lonDelta = max(0.01, (maxLon - minLon) * 1.5)
        
        region = MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: centerLatitude, longitude: centerLongitude),
            span: MKCoordinateSpan(latitudeDelta: latDelta, longitudeDelta: lonDelta)
        )
    }
}

struct PlaceAnnotationView: View {
    let place: Place
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack {
                ZStack {
                    Circle()
                        .fill(Color(hex: place.iconColor ?? "#FF3B30"))
                        .frame(width: 30, height: 30)
                    
                    Image(systemName: place.iconName ?? "mappin")
                        .foregroundColor(.white)
                        .font(.system(size: 16, weight: .medium))
                }
                
                Text(place.name ?? "")
                    .font(.caption)
                    .padding(4)
                    .background(Color.white.opacity(0.8))
                    .cornerRadius(4)
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
}

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3:
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6:
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

#Preview {
    MapView(document: PersistenceController.preview.container.viewContext.registeredObjects.compactMap { $0 as? Document }.first!, selectedPlace: .constant(nil))
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}