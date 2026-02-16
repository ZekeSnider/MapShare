import SwiftUI
import CoreData

struct DocumentListView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(AppState.self) private var appState
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Document.modifiedDate, ascending: false)],
        animation: .default
    ) private var documents: FetchedResults<Document>

    @State private var showingAddDocument = false
    @State private var selectedDocument: Document?
    @State private var showingShareDocument = false
    @State private var newDocumentName = ""
    @State private var navigationPath = NavigationPath()

    var body: some View {
        NavigationStack(path: $navigationPath) {
            List {
                ForEach(documents) { document in
                    NavigationLink(value: document) {
                        HStack {
                            Text(document.name ?? "Untitled")
                                .fontWeight(.bold)
                            Spacer()
                            Text("\(document.placesArray.count) places")
                                .foregroundStyle(.secondary)
                        }
                    }
                    .contextMenu {
                        Button(action: { shareDocument(document) }) {
                            Label("Share", systemImage: "square.and.arrow.up")
                        }

                        Button(action: { duplicateDocument(document) }) {
                            Label("Duplicate", systemImage: "doc.on.doc")
                        }

                        Divider()

                        Button(role: .destructive, action: { deleteDocument(document) }) {
                            Label("Delete", systemImage: "trash")
                        }
                    }
                }
                .onDelete(perform: deleteDocuments)
            }
            .navigationDestination(for: Document.self) { document in
                DocumentDetailView(document: document)
            }
            .navigationTitle("My Maps")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingAddDocument = true }) {
                        Image(systemName: "plus")
                    }
                }
                ToolbarItem(placement: .navigationBarLeading) {
                    EditButton()
                }
            }
            .sheet(isPresented: $showingAddDocument) {
                NavigationView {
                    Form {
                        Section(header: Text("Document Details")) {
                            TextField("Name", text: $newDocumentName)
                        }
                    }
                    .navigationTitle("New Map")
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .navigationBarLeading) {
                            Button("Cancel") {
                                newDocumentName = ""
                                showingAddDocument = false
                            }
                        }
                        ToolbarItem(placement: .navigationBarTrailing) {
                            Button("Save") {
                                addDocument()
                            }
                            .disabled(newDocumentName.isEmpty)
                        }
                    }
                }
            }
            .sheet(isPresented: $showingShareDocument) {
                if let document = selectedDocument {
                    DocumentShareView(document: document, isPresented: $showingShareDocument)
                }
            }
            .onChange(of: appState.documentIDToOpen) { _, objectID in
                print("🔄 onChange triggered, objectID: \(String(describing: objectID))")
                if let objectID = objectID {
                    print("📍 Fetching document for objectID...")
                    if let document = try? viewContext.existingObject(with: objectID) as? Document {
                        print("✅ Found document: \(document.name ?? "unnamed"), navigating...")
                        navigationPath = NavigationPath()
                        navigationPath.append(document)
                        appState.clearPendingNavigation()
                    } else {
                        print("❌ Could not fetch document for objectID")
                    }
                }
            }
            .onAppear {
                // Handle any pending navigation when view appears
                print("👀 onAppear, documentIDToOpen: \(String(describing: appState.documentIDToOpen))")
                if let objectID = appState.documentIDToOpen {
                    if let document = try? viewContext.existingObject(with: objectID) as? Document {
                        print("✅ Found pending document on appear: \(document.name ?? "unnamed")")
                        navigationPath = NavigationPath()
                        navigationPath.append(document)
                        appState.clearPendingNavigation()
                    }
                }
            }
        }
    }
    
    private func addDocument() {
        withAnimation {
            let newDocument = Document(name: newDocumentName, context: viewContext)

            do {
                try viewContext.save()
                newDocumentName = ""
                showingAddDocument = false
            } catch {
                let nsError = error as NSError
                print("Failed to create document: \(nsError), \(nsError.userInfo)")
            }
        }
    }

    private func shareDocument(_ document: Document) {
        selectedDocument = document
        showingShareDocument = true
    }
    
    private func duplicateDocument(_ document: Document) {
        withAnimation {
            let newDocument = Document(name: "\(document.name ?? "Untitled") Copy", context: viewContext)
            
            // Copy all places from the original document
            for place in document.placesArray {
                let newPlace = Place(
                    name: place.name ?? "",
                    coordinate: place.coordinate,
                    context: viewContext
                )
                newPlace.descriptionText = place.descriptionText
                newPlace.iconName = place.iconName
                newPlace.iconColor = place.iconColor
                newPlace.document = newDocument
            }
            
            do {
                try viewContext.save()
            } catch {
                let nsError = error as NSError
                fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
            }
        }
    }
    
    private func deleteDocument(_ document: Document) {
        withAnimation {
            viewContext.delete(document)
            
            do {
                try viewContext.save()
            } catch {
                let nsError = error as NSError
                fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
            }
        }
    }
    
    private func deleteDocuments(offsets: IndexSet) {
        withAnimation {
            offsets.map { documents[$0] }.forEach(viewContext.delete)
            
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
    DocumentListView()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
        .environment(AppState.shared)
}
