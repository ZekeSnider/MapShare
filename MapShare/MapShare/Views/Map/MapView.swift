import SwiftUI
import MapKit
import CoreData

struct MapView: View {
    let document: Document
    @Binding var selectedPlace: Place?
    @Binding var selectedNote: Note?
    let filter: FilterSettings
    @State private var cloudKitService = CloudKitService.shared

    var body: some View {
        MapViewRepresentable(document: document, selectedPlace: $selectedPlace, selectedNote: $selectedNote, filter: filter, userPresences: cloudKitService.userPresences)
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
    @Binding var selectedNote: Note?
    let filter: FilterSettings
    let userPresences: [String: UserPresence]

    func makeUIView(context: Context) -> MKMapView {
        let mapView = MKMapView()
        mapView.delegate = context.coordinator
        mapView.register(PlaceAnnotationView.self, forAnnotationViewWithReuseIdentifier: "place")
        mapView.register(NoteAnnotationView.self, forAnnotationViewWithReuseIdentifier: "note")
        mapView.register(ShapeAnnotationView.self, forAnnotationViewWithReuseIdentifier: "shape")
        mapView.register(UserPresenceAnnotationView.self, forAnnotationViewWithReuseIdentifier: "user")
        return mapView
    }

    func updateUIView(_ uiView: MKMapView, context: Context) {
        uiView.removeAnnotations(uiView.annotations)
        uiView.removeOverlays(uiView.overlays)

        var annotations: [MKAnnotation] = []
        if filter.showPlaces {
            annotations.append(contentsOf: document.placesArray as [MKAnnotation])
        }
        if filter.showNotes {
            annotations.append(contentsOf: document.notesArray as [MKAnnotation])
        }
        if filter.showShapes {
            annotations.append(contentsOf: document.shapesArray as [MKAnnotation])
        }

        // Add user presences
        for presence in userPresences {
            if let location = presence.value.location {
                let annotation = UserPresenceAnnotation(userID: presence.key, coordinate: location)
                annotations.append(annotation)
            }
        }

        uiView.addAnnotations(annotations)

        var overlays: [MKOverlay] = []
        if filter.showRoutes {
            overlays.append(contentsOf: document.routesArray.map { $0.polyline })
        }
        if filter.showAreas {
            overlays.append(contentsOf: document.areasArray.map { $0.polygon })
        }
        uiView.addOverlays(overlays)

        if !annotations.isEmpty || !overlays.isEmpty {
            centerMap(on: uiView)
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    private func centerMap(on mapView: MKMapView) {
        let annotations = mapView.annotations
        let overlays = mapView.overlays

        guard !annotations.isEmpty || !overlays.isEmpty else { return }

        var mapRect = MKMapRect.null

        annotations.forEach { annotation in
            let point = MKMapPoint(annotation.coordinate)
            mapRect = mapRect.union(MKMapRect(x: point.x, y: point.y, width: 0, height: 0))
        }

        overlays.forEach { overlay in
            mapRect = mapRect.union(overlay.boundingMapRect)
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
            } else if annotation is Note {
                let view = mapView.dequeueReusableAnnotationView(withIdentifier: "note", for: annotation) as! NoteAnnotationView
                return view
            } else if let shape = annotation as? Shape {
                let view = mapView.dequeueReusableAnnotationView(withIdentifier: "shape", for: annotation) as! ShapeAnnotationView
                view.shape = shape
                return view
            } else if let user = annotation as? UserPresenceAnnotation {
                let view = mapView.dequeueReusableAnnotationView(withIdentifier: "user", for: annotation) as! UserPresenceAnnotationView
                view.user = user
                return view
            }
            return nil
        }

        func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
            if let polyline = overlay as? MKPolyline {
                let renderer = MKPolylineRenderer(polyline: polyline)
                if let route = parent.document.routesArray.first(where: { $0.polyline == polyline }) {
                    renderer.strokeColor = UIColor(Color(hex: route.strokeColor ?? "#FF3B30"))
                    renderer.lineWidth = CGFloat(route.strokeWidth)
                }
                return renderer
            } else if let polygon = overlay as? MKPolygon {
                let renderer = MKPolygonRenderer(polygon: polygon)
                if let area = parent.document.areasArray.first(where: { $0.polygon == polygon }) {
                    renderer.fillColor = UIColor(Color(hex: area.fillColor ?? "#FF3B30")).withAlphaComponent(0.4)
                    renderer.strokeColor = UIColor(Color(hex: area.strokeColor ?? "#FF9500"))
                    renderer.lineWidth = 1
                }
                return renderer
            }
            return MKOverlayRenderer()
        }

        func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
            if let placeAnnotation = view.annotation as? Place {
                parent.selectedPlace = placeAnnotation
            } else if let noteAnnotation = view.annotation as? Note {
                parent.selectedNote = noteAnnotation
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

class NoteAnnotationView: MKAnnotationView {
    override init(annotation: MKAnnotation?, reuseIdentifier: String?) {
        super.init(annotation: annotation, reuseIdentifier: reuseIdentifier)
        let image = UIImage(systemName: "note.text")
        let imageView = UIImageView(image: image)
        imageView.tintColor = .yellow
        imageView.frame = CGRect(x: 0, y: 0, width: 24, height: 24)

        let container = UIView(frame: CGRect(x: -15, y: -15, width: 30, height: 30))
        container.backgroundColor = .black.withAlphaComponent(0.6)
        container.layer.cornerRadius = 15

        imageView.center = CGPoint(x: 15, y: 15)
        container.addSubview(imageView)

        addSubview(container)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

class ShapeAnnotationView: MKAnnotationView {
    var shape: Shape? {
        didSet {
            updateView()
        }
    }

    private let label = UILabel()

    override init(annotation: MKAnnotation?, reuseIdentifier: String?) {
        super.init(annotation: annotation, reuseIdentifier: reuseIdentifier)
        frame = CGRect(x: 0, y: 0, width: 40, height: 40)
        label.font = .systemFont(ofSize: 36)
        label.textAlignment = .center
        addSubview(label)
        label.frame = bounds
        updateView()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func updateView() {
        label.text = shape?.emoji ?? "❓"
    }
}


struct NoteDetailView: View {
    let note: Note

    var body: some View {
        NavigationView {
            VStack {
                Text(note.content ?? "Empty note")
                    .padding()

                Spacer()
            }
            .navigationTitle("Note")
        }
    }
}

#Preview {
    let context = PersistenceController.preview.container.viewContext
    let document = Document(name: "Sample Document", context: context)

    return MapView(document: document, selectedPlace: .constant(nil), selectedNote: .constant(nil), filter: FilterSettings())
        .environment(\.managedObjectContext, context)
}
