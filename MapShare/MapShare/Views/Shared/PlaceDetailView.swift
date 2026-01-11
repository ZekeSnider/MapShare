import SwiftUI
import MapKit
import CoreData
internal import CloudKit

struct PlaceDetailView: View {
    let place: Place
    @Environment(\.dismiss) private var dismiss
    @Environment(\.managedObjectContext) private var viewContext
    @State private var showingEditView = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    // Header with icon and name
                    HStack {
                        ZStack {
                            Circle()
                                .fill(Color(hex: place.iconColor ?? "#FF3B30"))
                                .frame(width: 50, height: 50)
                            
                            Image(systemName: place.iconName ?? "mappin")
                                .foregroundColor(.white)
                                .font(.system(size: 24, weight: .medium))
                        }
                        
                        VStack(alignment: .leading) {
                            Text(place.name ?? "Untitled Place")
                                .font(.title2)
                                .bold()
                            
                            Text("Added \(place.createdDate ?? Date(), style: .relative) ago")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                    }
                    .padding(.horizontal)
                    
                    // Map preview
                    Map(coordinateRegion: .constant(MKCoordinateRegion(
                        center: place.coordinate,
                        span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
                    )), annotationItems: [place]) { place in
                        MapAnnotation(coordinate: place.coordinate) {
                            ZStack {
                                Circle()
                                    .fill(Color(hex: place.iconColor ?? "#FF3B30"))
                                    .frame(width: 30, height: 30)
                                
                                Image(systemName: place.iconName ?? "mappin")
                                    .foregroundColor(.white)
                                    .font(.system(size: 16, weight: .medium))
                            }
                        }
                    }
                    .frame(height: 200)
                    .cornerRadius(12)
                    .padding(.horizontal)
                    
                    // Description
                    if let description = place.descriptionText, !description.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Description")
                                .font(.headline)
                            
                            Text(description)
                                .font(.body)
                        }
                        .padding(.horizontal)
                    }
                    
                    // Reactions
                    VStack(alignment: .leading) {
                        Text("Reactions")
                            .font(.headline)
                        
                        HStack {
                            Spacer()
                            
                            HStack {
                                Button(action: { addReaction("thumbsUp") }) {
                                    HStack {
                                        Image(systemName: "hand.thumbsup")
                                        Text("\(place.thumbsUpCount)")
                                    }
                                    .foregroundColor(.green)
                                }
                                
                                Button(action: { addReaction("thumbsDown") }) {
                                    HStack {
                                        Image(systemName: "hand.thumbsdown")
                                        Text("\(place.thumbsDownCount)")
                                    }
                                    .foregroundColor(.red)
                                }
                            }
                        }
                    }
                    .padding(.horizontal)
                    
                    // Comments section
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Comments")
                            .font(.headline)
                        
                        ForEach(place.commentsArray, id: \.id) { comment in
                            CommentRowView(comment: comment)
                        }
                        
                        if place.commentsArray.isEmpty {
                            Text("No comments yet")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .italic()
                        }
                        
                        // Add comment form
                        VStack {
                            TextEditor(text: $newCommentContent)
                                .frame(height: 80)
                                .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.gray.opacity(0.5), lineWidth: 1))
                            
                            Button(action: addComment) {
                                Text("Add Comment")
                            }
                            .buttonStyle(.borderedProminent)
                            .disabled(newCommentContent.isEmpty)
                        }
                        .padding(.vertical)
                        
                    }
                    .padding(.horizontal)
                    
                    Spacer(minLength: 50)
                }
                .onAppear(perform: fetchUserName)
            }
            .navigationTitle("Place Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Edit") {
                        showingEditView = true
                    }
                }
            }
            .sheet(isPresented: $showingEditView) {
                EditPlaceView(place: place, isPresented: $showingEditView)
            }
        }
    }
    
    @State private var authorName: String = "Anonymous"
    @State private var newCommentContent: String = ""

    private func addReaction(_ type: String) {
        withAnimation {
            let reaction = Reaction(context: viewContext)
            reaction.id = UUID()
            reaction.type = type
            reaction.authorName = authorName
            reaction.place = place
            
            do {
                try viewContext.save()
            } catch {
                let nsError = error as NSError
                print("Failed to save reaction: \(nsError), \(nsError.userInfo)")
            }
        }
    }
    
    private func addComment() {
        guard !newCommentContent.isEmpty else { return }
        withAnimation {
            let comment = Comment(context: viewContext)
            comment.id = UUID()
            comment.authorName = authorName
            comment.content = newCommentContent
            comment.createdDate = Date()
            comment.place = place
            
            do {
                try viewContext.save()
                newCommentContent = ""
            } catch {
                let nsError = error as NSError
                print("Failed to save comment: \(nsError), \(nsError.userInfo)")
            }
        }
    }
    
    private func fetchUserName() {
        Task {
            if let recordID = await CloudKitService.shared.getCurrentUserRecordID() {
                // For this example, we're just using the record name.
                // In a real app, you might fetch the user's actual name from their contacts.
                self.authorName = recordID.recordName
            }
        }
    }
}

struct CommentRowView: View {
    let comment: Comment
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(comment.authorName ?? "Unknown")
                    .font(.caption)
                    .bold()
                
                Spacer()
                
                Text(comment.createdDate ?? Date(), style: .relative)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Text(comment.content ?? "")
                .font(.body)
        }
        .padding(.vertical, 4)
    }
}

struct EditPlaceView: View {
    let place: Place
    @Binding var isPresented: Bool
    @Environment(\.managedObjectContext) private var viewContext
    
    @State private var placeName: String
    @State private var placeDescription: String
    @State private var selectedIcon: String
    @State private var selectedColor: String
    
    private let iconOptions = ["mappin", "house", "building.2", "car", "fork.knife", "cup.and.saucer", "cart", "bag", "heart", "star"]
    private let colorOptions = ["#FF3B30", "#FF9500", "#FFCC02", "#34C759", "#007AFF", "#5856D6", "#AF52DE", "#FF2D92"]
    
    init(place: Place, isPresented: Binding<Bool>) {
        self.place = place
        self._isPresented = isPresented
        self._placeName = State(initialValue: place.name ?? "")
        self._placeDescription = State(initialValue: place.descriptionText ?? "")
        self._selectedIcon = State(initialValue: place.iconName ?? "mappin")
        self._selectedColor = State(initialValue: place.iconColor ?? "#FF3B30")
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Place Details")) {
                    TextField("Name", text: $placeName)
                    TextField("Description", text: $placeDescription, axis: .vertical)
                        .lineLimit(3)
                }
                
                Section(header: Text("Icon")) {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 5)) {
                        ForEach(iconOptions, id: \.self) { icon in
                            Button(action: { selectedIcon = icon }) {
                                ZStack {
                                    Circle()
                                        .fill(selectedIcon == icon ? Color.blue.opacity(0.2) : Color.clear)
                                        .frame(width: 40, height: 40)
                                    
                                    Image(systemName: icon)
                                        .foregroundColor(selectedIcon == icon ? .blue : .primary)
                                        .font(.system(size: 18))
                                }
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                }
                
                Section(header: Text("Color")) {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 4)) {
                        ForEach(colorOptions, id: \.self) { color in
                            Button(action: { selectedColor = color }) {
                                ZStack {
                                    Circle()
                                        .fill(Color(hex: color))
                                        .frame(width: 30, height: 30)
                                    
                                    if selectedColor == color {
                                        Circle()
                                            .stroke(Color.primary, lineWidth: 2)
                                            .frame(width: 35, height: 35)
                                    }
                                }
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                }
            }
            .navigationTitle("Edit Place")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        isPresented = false
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveChanges()
                    }
                    .disabled(placeName.isEmpty)
                }
            }
        }
    }
    
    private func saveChanges() {
        withAnimation {
            place.name = placeName
            place.descriptionText = placeDescription.isEmpty ? nil : placeDescription
            place.iconName = selectedIcon
            place.iconColor = selectedColor
            place.modifiedDate = Date()
            
            do {
                try viewContext.save()
                isPresented = false
            } catch {
                let nsError = error as NSError
                print("Failed to save place: \(nsError), \(nsError.userInfo)")
            }
        }
    }
}

#Preview {
    let context = PersistenceController.preview.container.viewContext
    let place = Place(name: "Preview Place", coordinate: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194), context: context)
    return PlaceDetailView(place: place)
        .environment(\.managedObjectContext, context)
}
