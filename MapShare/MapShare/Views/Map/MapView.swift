import SwiftUI
import MapKit
import CoreData

import SwiftUI
import MapKit
import CoreData

struct MapView: View {
    let document: Document
    @Binding var selectedPlace: Place?
    @Binding var selectedNote: Note?
    @Binding var selectedShape: Shape?
    let filter: FilterSettings
    @Binding var centerOnCoordinate: CLLocationCoordinate2D?
    @State private var cloudKitService = CloudKitService.shared

    var body: some View {
        MapViewRepresentable(
            document: document,
            selectedPlace: $selectedPlace,
            selectedNote: $selectedNote,
            selectedShape: $selectedShape,
            filter: filter,
            centerOnCoordinate: $centerOnCoordinate,
            userPresences: cloudKitService.userPresences
        )
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
    @Binding var selectedShape: Shape?
    let filter: FilterSettings
    @Binding var centerOnCoordinate: CLLocationCoordinate2D?
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

        // Update selection state on annotation views
        for annotation in uiView.annotations {
            if let view = uiView.view(for: annotation) {
                if let placeView = view as? PlaceAnnotationView, let place = annotation as? Place {
                    placeView.isItemSelected = selectedPlace?.id == place.id
                } else if let noteView = view as? NoteAnnotationView, let note = annotation as? Note {
                    noteView.isItemSelected = selectedNote?.id == note.id
                } else if let shapeView = view as? ShapeAnnotationView, let shape = annotation as? Shape {
                    shapeView.isItemSelected = selectedShape?.id == shape.id
                }
            }
        }

        var overlays: [MKOverlay] = []
        if filter.showRoutes {
            overlays.append(contentsOf: document.routesArray.map { $0.polyline })
        }
        if filter.showAreas {
            overlays.append(contentsOf: document.areasArray.map { $0.polygon })
        }
        uiView.addOverlays(overlays)

        // Center on specific coordinate if requested
        if let coordinate = centerOnCoordinate {
            let region = MKCoordinateRegion(
                center: coordinate,
                latitudinalMeters: 500,
                longitudinalMeters: 500
            )
            uiView.setRegion(region, animated: true)
            DispatchQueue.main.async {
                self.centerOnCoordinate = nil
            }
        } else if !annotations.isEmpty || !overlays.isEmpty {
            // Only auto-center on first load
            if !context.coordinator.hasInitializedRegion {
                centerMap(on: uiView)
                context.coordinator.hasInitializedRegion = true
            }
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
        var hasInitializedRegion = false

        init(_ parent: MapViewRepresentable) {
            self.parent = parent
        }

        func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
            if let place = annotation as? Place {
                let view = mapView.dequeueReusableAnnotationView(withIdentifier: "place", for: annotation) as! PlaceAnnotationView
                view.place = place
                return view
            } else if let note = annotation as? Note {
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
                parent.selectedNote = nil
                parent.selectedShape = nil
            } else if let noteAnnotation = view.annotation as? Note {
                parent.selectedNote = noteAnnotation
                parent.selectedPlace = nil
                parent.selectedShape = nil
            } else if let shapeAnnotation = view.annotation as? Shape {
                parent.selectedShape = shapeAnnotation
                parent.selectedPlace = nil
                parent.selectedNote = nil
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

    var isItemSelected: Bool = false {
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

        let size: CGFloat = isItemSelected ? 44 : 30
        frame = CGRect(x: 0, y: 0, width: size, height: size)
        centerOffset = CGPoint(x: 0, y: -frame.size.height / 2)

        let circle = UIView(frame: bounds)
        circle.backgroundColor = UIColor(Color(hex: place.iconColor ?? "#FF3B30"))
        circle.layer.cornerRadius = size / 2

        if isItemSelected {
            circle.layer.borderWidth = 3
            circle.layer.borderColor = UIColor.white.cgColor
            circle.layer.shadowColor = UIColor.black.cgColor
            circle.layer.shadowOffset = CGSize(width: 0, height: 2)
            circle.layer.shadowRadius = 4
            circle.layer.shadowOpacity = 0.3
        }

        let image = UIImage(systemName: place.iconName ?? "mappin")
        let imageView = UIImageView(image: image)
        imageView.tintColor = .white
        let inset: CGFloat = isItemSelected ? 10 : 7
        imageView.frame = bounds.insetBy(dx: inset, dy: inset)

        addSubview(circle)
        addSubview(imageView)
    }
}

class NoteAnnotationView: MKAnnotationView {
    var isItemSelected: Bool = false {
        didSet {
            updateView()
        }
    }

    override init(annotation: MKAnnotation?, reuseIdentifier: String?) {
        super.init(annotation: annotation, reuseIdentifier: reuseIdentifier)
        updateView()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func updateView() {
        subviews.forEach { $0.removeFromSuperview() }

        let size: CGFloat = isItemSelected ? 44 : 30
        frame = CGRect(x: 0, y: 0, width: size, height: size)

        let image = UIImage(systemName: "note.text")
        let imgView = UIImageView(image: image)
        imgView.tintColor = .yellow
        let iconSize: CGFloat = isItemSelected ? 32 : 24
        imgView.frame = CGRect(x: 0, y: 0, width: iconSize, height: iconSize)

        let cont = UIView(frame: CGRect(x: -size/2, y: -size/2, width: size, height: size))
        cont.backgroundColor = .black.withAlphaComponent(0.6)
        cont.layer.cornerRadius = size / 2

        if isItemSelected {
            cont.layer.borderWidth = 3
            cont.layer.borderColor = UIColor.white.cgColor
            cont.layer.shadowColor = UIColor.black.cgColor
            cont.layer.shadowOffset = CGSize(width: 0, height: 2)
            cont.layer.shadowRadius = 4
            cont.layer.shadowOpacity = 0.3
        }

        imgView.center = CGPoint(x: size/2, y: size/2)
        cont.addSubview(imgView)

        addSubview(cont)
    }
}

class ShapeAnnotationView: MKAnnotationView {
    var shape: Shape? {
        didSet {
            updateView()
        }
    }

    var isItemSelected: Bool = false {
        didSet {
            updateView()
        }
    }

    private let label = UILabel()
    private let backgroundView = UIView()

    override init(annotation: MKAnnotation?, reuseIdentifier: String?) {
        super.init(annotation: annotation, reuseIdentifier: reuseIdentifier)
        updateView()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func updateView() {
        subviews.forEach { $0.removeFromSuperview() }

        let size: CGFloat = isItemSelected ? 56 : 40
        frame = CGRect(x: 0, y: 0, width: size, height: size)

        if isItemSelected {
            let bg = UIView(frame: bounds)
            bg.backgroundColor = UIColor.white.withAlphaComponent(0.9)
            bg.layer.cornerRadius = size / 2
            bg.layer.shadowColor = UIColor.black.cgColor
            bg.layer.shadowOffset = CGSize(width: 0, height: 2)
            bg.layer.shadowRadius = 4
            bg.layer.shadowOpacity = 0.3
            addSubview(bg)
        }

        let lbl = UILabel(frame: bounds)
        lbl.font = .systemFont(ofSize: isItemSelected ? 44 : 36)
        lbl.textAlignment = .center
        lbl.text = shape?.emoji ?? "❓"
        addSubview(lbl)
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

    return MapView(
        document: document,
        selectedPlace: .constant(nil),
        selectedNote: .constant(nil),
        selectedShape: .constant(nil),
        filter: FilterSettings(),
        centerOnCoordinate: .constant(nil)
    )
    .environment(\.managedObjectContext, context)
}