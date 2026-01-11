import SwiftUI
import CoreData

struct DocumentListView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Document.modifiedDate, ascending: false)],
        animation: .default
    ) private var documents: FetchedResults<Document>
    
    @State private var showingAddDocument = false
    @State private var selectedDocument: Document?
    @State private var showingShareDocument = false
    
    var body: some View {
        NavigationView {
            List {
                ForEach(documents) { document in
                    NavigationLink(destination: DocumentDetailView(document: document)) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(document.name ?? "Untitled")
                                .font(.headline)
                            
                            HStack {
                                Label("\(document.placesArray.count) places", systemImage: "mappin")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                
                                if document.isShared {
                                    Label("Shared", systemImage: "person.2")
                                        .font(.caption)
                                        .foregroundColor(.blue)
                                }
                                
                                Spacer()
                                
                                Text(document.modifiedDate ?? Date(), style: .relative)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .padding(.vertical, 2)
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
                            TextField("Name", text: Binding(
                                get: { "" },
                                set: { _ in }
                            ))
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                        }
                    }
                    .navigationTitle("New Map")
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .navigationBarLeading) {
                            Button("Cancel") {
                                showingAddDocument = false
                            }
                        }
                        ToolbarItem(placement: .navigationBarTrailing) {
                            Button("Save") {
                                // Add document logic here
                                showingAddDocument = false
                            }
                        }
                    }
                }
            }
            .sheet(isPresented: $showingShareDocument) {
                if let document = selectedDocument {
                    DocumentShareView(document: document, isPresented: $showingShareDocument)
                }
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
}
