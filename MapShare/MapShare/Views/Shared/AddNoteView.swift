import SwiftUI
import CoreLocation
import CoreData

struct AddNoteView: View {
    let document: Document
    @Binding var isPresented: Bool
    @State private var noteContent = ""
    
    // This would be passed from the map view
    let coordinate: CLLocationCoordinate2D

    @Environment(\.managedObjectContext) private var viewContext

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Note Content")) {
                    TextEditor(text: $noteContent)
                        .frame(minHeight: 150)
                }
            }
            .navigationTitle("Add Note")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        isPresented = false
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        addNote()
                    }
                    .disabled(noteContent.isEmpty)
                }
            }
        }
    }

    private func addNote() {
        withAnimation {
            let newNote = Note(content: noteContent, coordinate: coordinate, context: viewContext)
            document.addToNotes(newNote)

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
    AddNoteView(
        document: Document(context: PersistenceController.preview.container.viewContext),
        isPresented: .constant(true),
        coordinate: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194)
    )
    .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
