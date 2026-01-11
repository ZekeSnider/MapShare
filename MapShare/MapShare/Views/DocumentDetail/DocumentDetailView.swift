import SwiftUI
import CoreData

struct DocumentDetailView: View {
    let document: Document
    @State private var showingAddPlace = false
    @State private var selectedPlace: Place?
    @State private var showingShareDocument = false
    
    var body: some View {
        ZStack {
            MapView(document: document, selectedPlace: $selectedPlace)
            
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
                
                // Bottom action bar
                HStack(spacing: 20) {
                    Button(action: { showingAddPlace = true }) {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 50))
                            .foregroundColor(.blue)
                            .background(Color.white, in: Circle())
                    }
                }
                .padding()
                .padding(.bottom)
            }
        }
        .navigationTitle(document.name ?? "Untitled")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Menu {
                    Button(action: { showingAddPlace = true }) {
                        Label("Add Place", systemImage: "plus")
                    }
                    
                    Button(action: { showingShareDocument = true }) {
                        Label("Share Document", systemImage: "square.and.arrow.up")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
        .sheet(isPresented: $showingAddPlace) {
            AddPlaceView(document: document, isPresented: $showingAddPlace)
        }
        .sheet(item: $selectedPlace) { place in
            PlaceDetailView(place: place)
        }
        .sheet(isPresented: $showingShareDocument) {
            DocumentShareView(document: document, isPresented: $showingShareDocument)
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
