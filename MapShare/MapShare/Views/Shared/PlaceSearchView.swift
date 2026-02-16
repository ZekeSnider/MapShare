import SwiftUI
import MapKit
import CoreData
import CoreLocation

func iconForCategory(_ category: String?) -> String {
    guard let category = category else { return "mappin" }

    switch category {
    case "MKPOICategoryRestaurant", "MKPOICategoryCafe":
        return "fork.knife"
    case "MKPOICategoryStore", "MKPOICategoryShoppingCenter":
        return "bag"
    case "MKPOICategoryGasStation":
        return "car"
    case "MKPOICategoryHotel":
        return "bed.double"
    case "MKPOICategoryHospital", "MKPOICategoryPharmacy":
        return "cross.case"
    case "MKPOICategorySchool", "MKPOICategoryUniversity":
        return "graduationcap"
    case "MKPOICategoryPark":
        return "leaf"
    case "MKPOICategoryMuseum":
        return "building.columns"
    case "MKPOICategoryTheater":
        return "theatermasks"
    case "MKPOICategoryNightlife", "MKPOICategoryBar":
        return "wineglass"
    case "MKPOICategoryGym", "MKPOICategoryFitnessCenter":
        return "dumbbell"
    case "MKPOICategoryAirport":
        return "airplane"
    case "MKPOICategoryBank", "MKPOICategoryATM":
        return "banknote"
    default:
        return "mappin"
    }
}

struct PlaceSearchView: View {
    let document: Document
    @Binding var isPresented: Bool

    @State private var searchText = ""
    @State private var searchResults: [SearchResult] = []
    @State private var isSearching = false
    @State private var navigationPath = NavigationPath()
    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194),
        span: MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)
    )

    var body: some View {
        NavigationStack(path: $navigationPath) {
            VStack(spacing: 0) {
                // Search bar
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.secondary)

                    TextField("Search for a place...", text: $searchText)
                        .textFieldStyle(.plain)
                        .autocorrectionDisabled()
                        .onSubmit {
                            performSearch()
                        }

                    if !searchText.isEmpty {
                        Button {
                            searchText = ""
                            searchResults = []
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(10)
                .padding()

                if isSearching {
                    ProgressView("Searching...")
                        .padding()
                    Spacer()
                } else if searchResults.isEmpty && !searchText.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 40))
                            .foregroundColor(.secondary)
                        Text("No results found")
                            .font(.headline)
                            .foregroundColor(.secondary)
                        Text("Try a different search term")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding(.top, 60)
                    Spacer()
                } else if searchResults.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "map")
                            .font(.system(size: 40))
                            .foregroundColor(.secondary)
                        Text("Search for a place")
                            .font(.headline)
                            .foregroundColor(.secondary)
                        Text("Find restaurants, shops, landmarks, and more")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top, 60)
                    .padding(.horizontal)
                    Spacer()
                } else {
                    List(searchResults) { result in
                        Button {
                            navigationPath.append(result)
                        } label: {
                            HStack(spacing: 12) {
                                ZStack {
                                    Circle()
                                        .fill(Color.blue.opacity(0.1))
                                        .frame(width: 44, height: 44)

                                    Image(systemName: iconForCategory(result.category))
                                        .foregroundColor(.blue)
                                        .font(.system(size: 18))
                                }

                                VStack(alignment: .leading, spacing: 4) {
                                    Text(result.name)
                                        .font(.body)
                                        .foregroundColor(.primary)

                                    if !result.address.isEmpty {
                                        Text(result.address)
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                            .lineLimit(1)
                                    }
                                }

                                Spacer()

                                Image(systemName: "chevron.right")
                                    .foregroundColor(.secondary)
                                    .font(.caption)
                            }
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                    }
                    .listStyle(.plain)
                }
            }
            .navigationTitle("Search Places")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        isPresented = false
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Custom") {
                        navigationPath.append("custom")
                    }
                }
            }
            .navigationDestination(for: SearchResult.self) { result in
                AddPlaceViewEmbedded(
                    document: document,
                    isPresented: $isPresented,
                    prefilledName: result.name,
                    prefilledCoordinate: result.coordinate,
                    prefilledAddress: result.address,
                    prefilledPhoneNumber: result.phoneNumber,
                    prefilledWebsiteURL: result.url,
                    prefilledMapItemIdentifier: result.mapItemIdentifier,
                    prefilledIcon: iconForCategory(result.category)
                )
            }
            .navigationDestination(for: String.self) { _ in
                AddPlaceViewEmbedded(
                    document: document,
                    isPresented: $isPresented,
                    prefilledName: nil,
                    prefilledCoordinate: nil,
                    prefilledAddress: nil,
                    prefilledPhoneNumber: nil,
                    prefilledWebsiteURL: nil,
                    prefilledMapItemIdentifier: nil
                )
            }
        }
    }

    private func performSearch() {
        guard !searchText.isEmpty else { return }

        isSearching = true

        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = searchText
        request.region = region

        let search = MKLocalSearch(request: request)
        search.start { response, error in
            isSearching = false

            if let response = response {
                searchResults = response.mapItems.map { SearchResult(mapItem: $0) }
            } else {
                searchResults = []
            }
        }
    }

}

// Embedded version without its own NavigationView
struct AddPlaceViewEmbedded: View {
    let document: Document
    @Binding var isPresented: Bool
    var prefilledName: String?
    var prefilledCoordinate: CLLocationCoordinate2D?
    var prefilledAddress: String?
    var prefilledPhoneNumber: String?
    var prefilledWebsiteURL: URL?
    var prefilledMapItemIdentifier: String?
    var prefilledIcon: String?
    var onSave: (() -> Void)?

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
    @State private var currentUserParticipant: Participant?

    private let iconOptions = ["mappin", "house", "building.2", "car", "fork.knife", "cup.and.saucer", "cart", "bag", "heart", "star"]
    private let colorOptions = ["#FF3B30", "#FF9500", "#FFCC02", "#34C759", "#007AFF", "#5856D6", "#AF52DE", "#FF2D92"]

    var body: some View {
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
            if let icon = prefilledIcon {
                selectedIcon = icon
            }
            if let coordinate = prefilledCoordinate {
                selectedLocation = coordinate
                region = MKCoordinateRegion(
                    center: coordinate,
                    span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
                )
            }
        }
        .task {
            currentUserParticipant = await CloudKitService.shared.getCurrentUserAsParticipant(in: viewContext)
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
            newPlace.address = prefilledAddress
            newPlace.phoneNumber = prefilledPhoneNumber
            newPlace.websiteURL = prefilledWebsiteURL
            newPlace.mapItemIdentifier = prefilledMapItemIdentifier
            newPlace.addedBy = currentUserParticipant

            do {
                try viewContext.save()
                onSave?()
                isPresented = false
            } catch {
                let nsError = error as NSError
                fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
            }
        }
    }
}
