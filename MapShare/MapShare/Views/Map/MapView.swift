import SwiftUI
import MapKit
import CoreData

struct MapView: View {
    let document: Document
    @Binding var selectedPlace: Place?
    @Binding var centerOnPlace: Place?
    let filter: FilterSettings

    var body: some View {
        MapViewRepresentable(document: document, selectedPlace: $selectedPlace, centerOnPlace: $centerOnPlace, filter: filter)
    }
}

struct MapViewRepresentable: UIViewRepresentable {
    let document: Document
    @Binding var selectedPlace: Place?
    @Binding var centerOnPlace: Place?
    let filter: FilterSettings

    func makeUIView(context: Context) -> MKMapView {
        let mapView = MKMapView()
        mapView.delegate = context.coordinator
        mapView.register(PlaceAnnotationView.self, forAnnotationViewWithReuseIdentifier: "place")
        return mapView
    }

    func updateUIView(_ uiView: MKMapView, context: Context) {
        uiView.removeAnnotations(uiView.annotations)

        var annotations: [MKAnnotation] = []
        if filter.showPlaces {
            annotations.append(contentsOf: document.placesArray as [MKAnnotation])
        }

        uiView.addAnnotations(annotations)

        // Center on specific place if requested (from list tap)
        // Offset the center so the place appears in the top third of the map (above the sheet)
        if let place = centerOnPlace {
            let latitudinalMeters: Double = 1000
            let region = MKCoordinateRegion(
                center: place.coordinate,
                latitudinalMeters: latitudinalMeters,
                longitudinalMeters: 1000
            )
            // Offset center southward so place appears in top third
            let offsetCenter = CLLocationCoordinate2D(
                latitude: place.coordinate.latitude - region.span.latitudeDelta * 0.35,
                longitude: place.coordinate.longitude
            )
            let offsetRegion = MKCoordinateRegion(center: offsetCenter, span: region.span)
            uiView.setRegion(offsetRegion, animated: true)
            DispatchQueue.main.async {
                self.centerOnPlace = nil
            }
        } else if !annotations.isEmpty && !context.coordinator.hasInitiallyZoomed {
            centerMap(on: uiView)
            context.coordinator.hasInitiallyZoomed = true
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
        var hasInitiallyZoomed = false

        init(_ parent: MapViewRepresentable) {
            self.parent = parent
        }

        func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
            if let place = annotation as? Place {
                let view = mapView.dequeueReusableAnnotationView(withIdentifier: "place", for: annotation) as! PlaceAnnotationView
                view.place = place
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

// MARK: - Custom Annotation Views

class PlaceAnnotationView: MKAnnotationView {
    var place: Place? {
        didSet {
            updateView()
        }
    }

    private let containerView = UIView()
    private let pinView = UIView()
    private let iconImageView = UIImageView()
    private let nameLabel = UILabel()

    override init(annotation: MKAnnotation?, reuseIdentifier: String?) {
        super.init(annotation: annotation, reuseIdentifier: reuseIdentifier)
        setupViews()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupViews() {
        // Pin circle
        pinView.frame = CGRect(x: 0, y: 0, width: 30, height: 30)
        pinView.layer.cornerRadius = 15

        // Icon
        iconImageView.tintColor = .white
        iconImageView.contentMode = .scaleAspectFit
        iconImageView.frame = pinView.bounds.insetBy(dx: 7, dy: 7)

        // Name label
        nameLabel.font = .systemFont(ofSize: 12, weight: .medium)
        nameLabel.textColor = .label
        nameLabel.textAlignment = .center
        nameLabel.backgroundColor = UIColor.systemBackground.withAlphaComponent(0.85)
        nameLabel.layer.cornerRadius = 4
        nameLabel.layer.masksToBounds = true

        pinView.addSubview(iconImageView)
        addSubview(pinView)
        addSubview(nameLabel)
    }

    private func updateView() {
        guard let place = place else { return }

        // Update pin color
        pinView.backgroundColor = UIColor(Color(hex: place.iconColor ?? "#FF3B30"))

        // Update icon
        iconImageView.image = UIImage(systemName: place.iconName ?? "mappin")

        // Update label
        nameLabel.text = "  \(place.name ?? "")  "
        nameLabel.sizeToFit()

        // Layout: pin on top, label below
        let labelWidth = nameLabel.frame.width
        let totalWidth = max(30, labelWidth)
        let totalHeight: CGFloat = 30 + 4 + nameLabel.frame.height

        frame = CGRect(x: 0, y: 0, width: totalWidth, height: totalHeight)
        centerOffset = CGPoint(x: 0, y: -totalHeight / 2)

        pinView.frame = CGRect(x: (totalWidth - 30) / 2, y: 0, width: 30, height: 30)
        iconImageView.frame = pinView.bounds.insetBy(dx: 7, dy: 7)
        nameLabel.frame = CGRect(x: (totalWidth - labelWidth) / 2, y: 34, width: labelWidth, height: nameLabel.frame.height)
    }
}

#Preview {
    let context = PersistenceController.preview.container.viewContext
    let document = Document(name: "Sample Document", context: context)

    return MapView(document: document, selectedPlace: .constant(nil), centerOnPlace: .constant(nil), filter: FilterSettings())
        .environment(\.managedObjectContext, context)
}
