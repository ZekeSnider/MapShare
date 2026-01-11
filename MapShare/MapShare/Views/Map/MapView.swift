import SwiftUI
import MapKit
import CoreData

struct MapView: View {
    let document: Document
    @Binding var selectedPlace: Place?
    let filter: FilterSettings
    @State private var cloudKitService = CloudKitService.shared

    var body: some View {
        MapViewRepresentable(document: document, selectedPlace: $selectedPlace, filter: filter, userPresences: cloudKitService.userPresences)
            .onAppear {
                Task {
                    await cloudKitService.observeUserPresence(for: document)
                }
            }
    }
}

struct MapViewRepresentable: UIViewRepresentable {
    let document: Document
    @Binding var selectedPlace: Place?
    let filter: FilterSettings
    let userPresences: [String: UserPresence]

    func makeUIView(context: Context) -> MKMapView {
        let mapView = MKMapView()
        mapView.delegate = context.coordinator
        mapView.register(PlaceAnnotationView.self, forAnnotationViewWithReuseIdentifier: "place")
        mapView.register(UserPresenceAnnotationView.self, forAnnotationViewWithReuseIdentifier: "user")
        return mapView
    }

    func updateUIView(_ uiView: MKMapView, context: Context) {
        uiView.removeAnnotations(uiView.annotations)

        var annotations: [MKAnnotation] = []
        if filter.showPlaces {
            annotations.append(contentsOf: document.placesArray as [MKAnnotation])
        }

        // Add user presences
        for presence in userPresences {
            if let location = presence.value.location {
                let annotation = UserPresenceAnnotation(userID: presence.key, coordinate: location)
                annotations.append(annotation)
            }
        }

        uiView.addAnnotations(annotations)

        if !annotations.isEmpty {
            centerMap(on: uiView)
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    private func centerMap(on mapView: MKMapView) {
        let annotations = mapView.annotations

        guard !annotations.isEmpty else { return }

        var mapRect = MKMapRect.null

        annotations.forEach { annotation in
            let point = MKMapPoint(annotation.coordinate)
            mapRect = mapRect.union(MKMapRect(x: point.x, y: point.y, width: 0, height: 0))
        }

        mapView.setVisibleMapRect(mapRect, edgePadding: UIEdgeInsets(top: 50, left: 50, bottom: 50, right: 50), animated: true)
    }

    class Coordinator: NSObject, MKMapViewDelegate {
        var parent: MapViewRepresentable

        init(_ parent: MapViewRepresentable) {
            self.parent = parent
        }

        func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
            if let place = annotation as? Place {
                let view = mapView.dequeueReusableAnnotationView(withIdentifier: "place", for: annotation) as! PlaceAnnotationView
                view.place = place
                return view
            } else if let user = annotation as? UserPresenceAnnotation {
                let view = mapView.dequeueReusableAnnotationView(withIdentifier: "user", for: annotation) as! UserPresenceAnnotationView
                view.user = user
                return view
            }
            return nil
        }

        func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
            if let placeAnnotation = view.annotation as? Place {
                parent.selectedPlace = placeAnnotation
            }
        }
    }
}

// MARK: - User Presence Annotation

class UserPresenceAnnotation: NSObject, MKAnnotation {
    let userID: String
    let coordinate: CLLocationCoordinate2D

    init(userID: String, coordinate: CLLocationCoordinate2D) {
        self.userID = userID
        self.coordinate = coordinate
    }
}

class UserPresenceAnnotationView: MKAnnotationView {
    var user: UserPresenceAnnotation?

    override init(annotation: MKAnnotation?, reuseIdentifier: String?) {
        super.init(annotation: annotation, reuseIdentifier: reuseIdentifier)

        backgroundColor = .blue
        frame = CGRect(x: 0, y: 0, width: 20, height: 20)
        layer.cornerRadius = 10
        layer.borderWidth = 2
        layer.borderColor = UIColor.white.cgColor
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

// MARK: - Custom Annotation Views

class PlaceAnnotationView: MKAnnotationView {
    var place: Place? {
        didSet {
            updateView()
        }
    }

    override init(annotation: MKAnnotation?, reuseIdentifier: String?) {
        super.init(annotation: annotation, reuseIdentifier: reuseIdentifier)
        frame = CGRect(x: 0, y: 0, width: 30, height: 30)
        centerOffset = CGPoint(x: 0, y: -frame.size.height / 2)
        updateView()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func updateView() {
        subviews.forEach { $0.removeFromSuperview() }
        guard let place = place else { return }
        let circle = UIView(frame: bounds)
        circle.backgroundColor = UIColor(Color(hex: place.iconColor ?? "#FF3B30"))
        circle.layer.cornerRadius = 15

        let image = UIImage(systemName: place.iconName ?? "mappin")
        let imageView = UIImageView(image: image)
        imageView.tintColor = .white
        imageView.frame = bounds.insetBy(dx: 7, dy: 7)

        addSubview(circle)
        addSubview(imageView)
    }
}

#Preview {
    let context = PersistenceController.preview.container.viewContext
    let document = Document(name: "Sample Document", context: context)

    return MapView(document: document, selectedPlace: .constant(nil), filter: FilterSettings())
        .environment(\.managedObjectContext, context)
}
