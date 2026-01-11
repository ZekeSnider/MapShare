import SwiftUI
import CoreData

struct DocumentDetailView: View {
    let document: Document
    @State private var showingAddPlace = false
    @State private var selectedPlace: Place?
    
    var body: some View {
        MapView(document: document, selectedPlace: $selectedPlace)
            .navigationTitle(document.name ?? "Untitled")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingAddPlace = true }) {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAddPlace) {
                AddPlaceView(document: document, isPresented: $showingAddPlace)
            }
            .sheet(item: $selectedPlace) { place in
                PlaceDetailView(place: place)
            }
    }
}

#Preview {
    NavigationView {
        DocumentDetailView(document: PersistenceController.preview.container.viewContext.registeredObjects.compactMap { $0 as? Document }.first!)
    }
    .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
