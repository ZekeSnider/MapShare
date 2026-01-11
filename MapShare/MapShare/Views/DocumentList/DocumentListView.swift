import SwiftUI
import CoreData

struct DocumentListView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Document.modifiedDate, ascending: false)],
        animation: .default
    ) private var documents: FetchedResults<Document>
    
    @State private var showingAddDocument = false
    @State private var newDocumentName = ""
    
    var body: some View {
        NavigationView {
            List {
                ForEach(documents) { document in
                    NavigationLink(destination: DocumentDetailView(document: document)) {
                        DocumentRowView(document: document)
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
                AddDocumentView(isPresented: $showingAddDocument)
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

struct DocumentRowView: View {
    let document: Document
    
    var body: some View {
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
}

struct AddDocumentView: View {
    @Binding var isPresented: Bool
    @Environment(\.managedObjectContext) private var viewContext
    @State private var documentName = ""
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Document Details")) {
                    TextField("Name", text: $documentName)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                }
            }
            .navigationTitle("New Map")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        isPresented = false
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        addDocument()
                    }
                    .disabled(documentName.isEmpty)
                }
            }
        }
    }
    
    private func addDocument() {
        withAnimation {
            let newDocument = Document(name: documentName, context: viewContext)
            
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
    DocumentListView()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}