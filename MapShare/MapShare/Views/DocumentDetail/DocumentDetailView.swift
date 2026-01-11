import SwiftUI
import CoreData
import CoreLocation

struct FilterSettings {
    var showPlaces = true
}

struct DocumentDetailView: View {
    var document: Document
    @State private var showingAddPlace = false
    @State private var selectedPlace: Place?
    @State private var showingShareDocument = false
    @State private var filterSettings = FilterSettings()
    @State private var panelExpanded = false
    @State private var refreshID = UUID()
    @Environment(\.managedObjectContext) private var viewContext

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .bottom) {
                // Map
                MapView(document: document, selectedPlace: $selectedPlace, filter: filterSettings)
                    .ignoresSafeArea(edges: .bottom)

                // Sharing info overlay
                VStack {
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

                // Bottom panel
                MapItemsListView(
                    document: document,
                    selectedPlace: $selectedPlace
                )
                .frame(height: (panelExpanded ? geometry.size.height * 0.6 : 200) + geometry.safeAreaInsets.bottom)
                .animation(.spring(response: 0.3, dampingFraction: 0.8), value: panelExpanded)
                .gesture(
                    DragGesture()
                        .onEnded { value in
                            if value.translation.height < -50 {
                                panelExpanded = true
                            } else if value.translation.height > 50 {
                                panelExpanded = false
                            }
                        }
                )
            }
            .ignoresSafeArea(edges: .bottom)
        }
        .navigationTitle(document.name ?? "Untitled")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                HStack {
                    // Add menu with plus button
                    Menu {
                        Button(action: { showingAddPlace = true }) {
                            Label("Add Place", systemImage: "mappin.circle.fill")
                        }
                    } label: {
                        Image(systemName: "plus")
                    }

                    // More options menu
                    Menu {
                        Button(action: { showingShareDocument = true }) {
                            Label("Share Document", systemImage: "square.and.arrow.up")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }

                    // Filter menu
                    Menu {
                        Toggle(isOn: $filterSettings.showPlaces) {
                            Label("Places", systemImage: "mappin")
                        }
                    } label: {
                        Image(systemName: "line.3.horizontal.decrease.circle")
                    }
                }
            }
        }
        .sheet(isPresented: $showingAddPlace) {
            PlaceSearchView(document: document, isPresented: $showingAddPlace)
        }
        .sheet(item: $selectedPlace) { place in
            PlaceDetailView(place: place)
        }
        .sheet(isPresented: $showingShareDocument) {
            DocumentShareView(document: document, isPresented: $showingShareDocument)
        }
        .onReceive(NotificationCenter.default.publisher(for: .NSManagedObjectContextDidSave)) { _ in
            refreshID = UUID()
        }
        .id(refreshID)
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
