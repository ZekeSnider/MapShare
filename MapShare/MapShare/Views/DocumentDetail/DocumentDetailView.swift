import SwiftUI
import CoreData
import CoreLocation

struct FilterSettings {
    var showPlaces = true
}

struct DocumentDetailView: View {
    var document: Document
    @State private var selectedPlace: Place?
    @State private var centerOnPlace: Place?
    @State private var showingShareDocument = false
    @State private var filterSettings = FilterSettings()
    @State private var selectedDetent: PresentationDetent = .fraction(0.15)
    @State private var showingItemsList = false
    @State private var refreshID = UUID()
    @State private var searchState = SearchState()
    @Environment(\.managedObjectContext) private var viewContext

    var body: some View {
        MapView(document: document, selectedPlace: $selectedPlace, centerOnPlace: $centerOnPlace, filter: filterSettings, searchState: searchState)
            .id(refreshID)
            .ignoresSafeArea()
            .overlay(alignment: .top) {
                if document.isShared {
                    HStack {
                        Spacer()
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
                    .padding(.top, 8)
                }
            }
            .navigationTitle(document.name ?? "Untitled")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    HStack {
                        Button(action: {
                            searchState.startSearch()
                            if selectedDetent == .fraction(0.15) {
                                withAnimation {
                                    selectedDetent = .medium
                                }
                            }
                        }) {
                            Image(systemName: "plus")
                        }
                        Menu {
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
                        } label: {
                            Image(systemName: "line.3.horizontal.decrease.circle")
                        }
                    }
                }
            }
            .sheet(isPresented: $showingShareDocument) {
                DocumentShareView(document: document, isPresented: $showingShareDocument)
            }
            .sheet(isPresented: $showingItemsList) {
                MapItemsListView(document: document, selectedPlace: $selectedPlace, centerOnPlace: $centerOnPlace, searchState: searchState)
                    .presentationDetents([.fraction(0.15), .medium, .large], selection: $selectedDetent)
                    .presentationDragIndicator(.visible)
                    .presentationBackgroundInteraction(.enabled(upThrough: .large))
                    .interactiveDismissDisabled()
            }
            .onAppear {
                showingItemsList = true
            }
            .onChange(of: selectedPlace) { oldValue, newValue in
                // Expand sheet to medium if a place is selected and sheet is at smallest detent
                if newValue != nil && selectedDetent == .fraction(0.15) {
                    withAnimation {
                        selectedDetent = .medium
                    }
                }
            }
            .onReceive(NotificationCenter.default.publisher(for: .NSManagedObjectContextDidSave)) { _ in
                refreshID = UUID()
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
