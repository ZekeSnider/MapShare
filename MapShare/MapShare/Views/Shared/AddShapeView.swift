import SwiftUI
import CoreLocation
import CoreData

struct AddShapeView: View {
    let document: Document
    @Binding var isPresented: Bool
    
    // This would be passed from the map view
    let coordinate: CLLocationCoordinate2D

    @State private var selectedEmoji = "😀"
    private let emojis = ["😀", "❤️", "⭐️", "🔥", "👍", "👎"]

    @Environment(\.managedObjectContext) private var viewContext

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Select Emoji")) {
                    Picker("Emoji", selection: $selectedEmoji) {
                        ForEach(emojis, id: \.self) { emoji in
                            Text(emoji).font(.largeTitle)
                        }
                    }
                    .pickerStyle(.segmented)
                }
            }
            .navigationTitle("Add Emoji")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        isPresented = false
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        addShape()
                    }
                }
            }
        }
    }

    private func addShape() {
        withAnimation {
            let newShape = Shape(emoji: selectedEmoji, coordinate: coordinate, context: viewContext)
            document.addToShapes(newShape)

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
    let context = PersistenceController.preview.container.viewContext
    return AddShapeView(
        document: Document(context: context),
        isPresented: .constant(true),
        coordinate: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194)
    )
    .environment(\.managedObjectContext, context)
}
