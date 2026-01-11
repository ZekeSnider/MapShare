import SwiftUI
import CoreData
import CoreLocation

struct FilterSettings {
    var showPlaces = true
    var showNotes = true
    var showShapes = true
    var showRoutes = true
    var showAreas = true
}

struct DocumentDetailView: View {
    let document: Document
    @State private var showingAddPlace = false
    @State private var showingAddNote = false
    @State private var showingAddShape = false
    @State private var selectedPlace: Place?
    @State private var selectedNote: Note?
    @State private var selectedShape: Shape?
    @State private var showingShareDocument = false
    @State private var filterSettings = FilterSettings()
    @State private var centerOnCoordinate: CLLocationCoordinate2D?
    @State private var panelHeight: PanelHeight = .small
    @Environment(\.managedObjectContext) private var viewContext

    var body: some View {
        ZStack {
            MapView(
                document: document,
                selectedPlace: $selectedPlace,
                selectedNote: $selectedNote,
                selectedShape: $selectedShape,
                filter: filterSettings,
                centerOnCoordinate: $centerOnCoordinate
            )

            VStack {
                // Top toolbar with sharing info
                HStack {
                    Spacer()

                    if document.isShared {
                        HStack(spacing: 8) {
                            Image(systemName: "person.2.fill")
                                .foregroundColor(.blue)

                            Text("Shared")
                                .font(.caption)
                                .foregroundColor(.secondary)

                            Button("Manage") {
                                showingShareDocument = true
                            }
                            .font(.caption)
                            .buttonStyle(.bordered)
                            .controlSize(.small)
                        }
                        .padding()
                        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
                        .shadow(radius: 2)
                        .padding(.trailing)
                    }
                }

                Spacer()
            }

            // Bottom panel with items list
            BottomPanelView(currentHeight: $panelHeight) {
                MapItemsListView(
                    document: document,
                    selectedPlace: $selectedPlace,
                    selectedNote: $selectedNote,
                    selectedShape: $selectedShape,
                    showingAddPlace: $showingAddPlace,
                    showingAddNote: $showingAddNote,
                    showingAddShape: $showingAddShape,
                    onCenterOnItem: { coordinate in
                        centerOnCoordinate = coordinate
                    }
                )
            }
        }
        .navigationTitle(document.name ?? "Untitled")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                HStack {
                    Menu {
                        Button(action: { addSampleRoute() }) {
                            Label("Add Sample Route", systemImage: "road.lanes")
                        }

                        Button(action: { addSampleArea() }) {
                            Label("Add Sample Area", systemImage: "square.dashed")
                        }

                        Divider()

                        Button(action: { showingShareDocument = true }) {
                            Label("Share Document", systemImage: "square.and.arrow.up")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }

                    Menu {
                        Toggle(isOn: $filterSettings.showPlaces) {
                            Label("Places", systemImage: "mappin")
                        }
                        Toggle(isOn: $filterSettings.showNotes) {
                            Label("Notes", systemImage: "note.text")
                        }
                        Toggle(isOn: $filterSettings.showShapes) {
                            Label("Shapes", systemImage: "face.smiling")
                        }
                        Toggle(isOn: $filterSettings.showRoutes) {
                            Label("Routes", systemImage: "road.lanes")
                        }
                        Toggle(isOn: $filterSettings.showAreas) {
                            Label("Areas", systemImage: "square.dashed")
                        }
                    } label: {
                        Image(systemName: "line.3.horizontal.decrease.circle")
                    }
                }
            }
        }
        .sheet(isPresented: $showingAddPlace) {
            AddPlaceView(document: document, isPresented: $showingAddPlace)
        }
        .sheet(isPresented: $showingAddNote) {
            AddNoteView(document: document, isPresented: $showingAddNote, coordinate: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194))
        }
        .sheet(isPresented: $showingAddShape) {
            AddShapeView(document: document, isPresented: $showingAddShape, coordinate: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194))
        }
        .sheet(item: $selectedPlace) { place in
            PlaceDetailView(place: place)
        }
        .sheet(item: $selectedNote) { note in
            NoteDetailView(note: note)
        }
        .sheet(isPresented: $showingShareDocument) {
            DocumentShareView(document: document, isPresented: $showingShareDocument)
        }
    }

    private func addSampleRoute() {
        withAnimation {
            let coordinates = [
                CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194),
                CLLocationCoordinate2D(latitude: 37.773, longitude: -122.421),
                CLLocationCoordinate2D(latitude: 37.775, longitude: -122.425),
                CLLocationCoordinate2D(latitude: 37.778, longitude: -122.420)
            ]
            let newRoute = Route(name: "Sample Route", coordinates: coordinates, context: viewContext)
            document.addToRoutes(newRoute)

            do {
                try viewContext.save()
            } catch {
                let nsError = error as NSError
                fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
            }
        }
    }

    private func addSampleArea() {
        withAnimation {
            let coordinates = [
                CLLocationCoordinate2D(latitude: 37.78, longitude: -122.43),
                CLLocationCoordinate2D(latitude: 37.78, longitude: -122.42),
                CLLocationCoordinate2D(latitude: 37.77, longitude: -122.42),
                CLLocationCoordinate2D(latitude: 37.77, longitude: -122.43)
            ]
            let newArea = Area(name: "Sample Area", coordinates: coordinates, context: viewContext)
            document.addToAreas(newArea)

            do {
                try viewContext.save()
            } catch {
                let nsError = error as NSError
                fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
            }
        }
    }
}

#Preview {
    let context = PersistenceController.preview.container.viewContext
    let document = Document(name: "Sample Document", context: context)

    return NavigationView {
        DocumentDetailView(document: document)
    }
    .environment(\.managedObjectContext, context)
}
