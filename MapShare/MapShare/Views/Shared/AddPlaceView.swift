import SwiftUI
import CoreLocation
import MapKit
import CoreData

struct MapPoint: Identifiable {
    let id = UUID()
    let coordinate: CLLocationCoordinate2D
}

struct AddPlaceView: View {
    let document: Document
    @Binding var isPresented: Bool
    var prefilledName: String?
    var prefilledCoordinate: CLLocationCoordinate2D?
    var prefilledAddress: String?

    @Environment(\.managedObjectContext) private var viewContext

    @State private var placeName = ""
    @State private var placeDescription = ""
    @State private var selectedLocation: CLLocationCoordinate2D?
    @State private var selectedIcon = "mappin"
    @State private var selectedColor = "#FF3B30"
    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194),
        span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
    )

    private let iconOptions = ["mappin", "house", "building.2", "car", "fork.knife", "cup.and.saucer", "cart", "bag", "heart", "star"]
    private let colorOptions = ["#FF3B30", "#FF9500", "#FFCC02", "#34C759", "#007AFF", "#5856D6", "#AF52DE", "#FF2D92"]

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Place Details")) {
                    TextField("Name", text: $placeName)
                    TextField("Description", text: $placeDescription, axis: .vertical)
                        .lineLimit(3)

                    if let address = prefilledAddress, !address.isEmpty {
                        HStack {
                            Image(systemName: "location")
                                .foregroundColor(.secondary)
                            Text(address)
                                .foregroundColor(.secondary)
                                .font(.subheadline)
                        }
                    }
                }

                Section(header: Text("Icon")) {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 5)) {
                        ForEach(iconOptions, id: \.self) { icon in
                            Button(action: { selectedIcon = icon }) {
                                ZStack {
                                    Circle()
                                        .fill(selectedIcon == icon ? Color.blue.opacity(0.2) : Color.clear)
                                        .frame(width: 40, height: 40)

                                    Image(systemName: icon)
                                        .foregroundColor(selectedIcon == icon ? .blue : .primary)
                                        .font(.system(size: 18))
                                }
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                }

                Section(header: Text("Color")) {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 4)) {
                        ForEach(colorOptions, id: \.self) { color in
                            Button(action: { selectedColor = color }) {
                                ZStack {
                                    Circle()
                                        .fill(Color(hex: color))
                                        .frame(width: 30, height: 30)

                                    if selectedColor == color {
                                        Circle()
                                            .stroke(Color.primary, lineWidth: 2)
                                            .frame(width: 35, height: 35)
                                    }
                                }
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                }

                Section(header: Text("Location")) {
                    Map(coordinateRegion: $region, interactionModes: .all, annotationItems: selectedLocation != nil ? [MapPoint(coordinate: selectedLocation!)] : []) { point in
                        MapAnnotation(coordinate: point.coordinate) {
                            ZStack {
                                Circle()
                                    .fill(Color(hex: selectedColor))
                                    .frame(width: 30, height: 30)

                                Image(systemName: selectedIcon)
                                    .foregroundColor(.white)
                                    .font(.system(size: 16, weight: .medium))
                            }
                        }
                    }
                    .frame(height: 200)
                    .onTapGesture {
                        let coordinate = region.center
                        selectedLocation = coordinate
                    }

                    if selectedLocation != nil {
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                            Text("Location selected")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    } else {
                        Text("Tap on the map to select a location")
                            .foregroundColor(.secondary)
                            .font(.caption)
                    }
                }
            }
            .navigationTitle(prefilledName != nil ? "Add Place" : "New Place")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        isPresented = false
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        addPlace()
                    }
                    .disabled(placeName.isEmpty || selectedLocation == nil)
                }
            }
            .onAppear {
                // Prefill data if provided
                if let name = prefilledName {
                    placeName = name
                }
                if let coordinate = prefilledCoordinate {
                    selectedLocation = coordinate
                    region = MKCoordinateRegion(
                        center: coordinate,
                        span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
                    )
                }
            }
        }
    }

    private func addPlace() {
        guard let location = selectedLocation else { return }

        withAnimation {
            let newPlace = Place(name: placeName, coordinate: location, context: viewContext)
            newPlace.descriptionText = placeDescription.isEmpty ? nil : placeDescription
            newPlace.iconName = selectedIcon
            newPlace.iconColor = selectedColor
            newPlace.document = document

            do {
                try viewContext.save()
                isPresented = false
            } catch {
                let nsError = error as NSError
                fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
            }
        }
    }
}

#Preview {
    AddPlaceView(
        document: PersistenceController.preview.container.viewContext.registeredObjects.compactMap { $0 as? Document }.first!,
        isPresented: .constant(true)
    )
    .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
