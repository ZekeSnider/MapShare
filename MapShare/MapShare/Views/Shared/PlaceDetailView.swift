import SwiftUI
import MapKit
import CoreData
import CloudKit

// MARK: - PlaceDetailContent (for NavigationStack push)
struct PlaceDetailContent: View {
    let place: Place
    @State private var refreshID = UUID()
    @Environment(\.managedObjectContext) private var viewContext
    @State private var authorName: String = ""
    @State private var newCommentContent: String = ""
    @State private var isLoadingUser = true

    var body: some View {
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

                    VStack(alignment: .leading, spacing: 4) {
                        Text(place.name ?? "Untitled Place")
                            .font(.title2)
                            .bold()

                        if let addedBy = place.addedBy {
                            HStack(spacing: 6) {
                                ProfileAvatarView(participant: addedBy, size: 20)
                                Text("Added by \(addedBy.displayName)")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }

                        Text("\(place.createdDate ?? Date(), style: .relative) ago")
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

                // Address and Actions
                VStack(alignment: .leading, spacing: 12) {
                    if let address = place.address, !address.isEmpty {
                        HStack(alignment: .top, spacing: 12) {
                            Image(systemName: "location.fill")
                                .foregroundColor(.secondary)
                            Text(address)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                    }

                    if let phoneNumber = place.phoneNumber, !phoneNumber.isEmpty {
                        HStack(spacing: 12) {
                            Image(systemName: "phone.fill")
                                .foregroundColor(.secondary)
                            Link(phoneNumber, destination: URL(string: "tel:\(phoneNumber.replacingOccurrences(of: " ", with: ""))")!)
                                .font(.subheadline)
                        }
                    }

                    if let websiteURL = place.websiteURL {
                        Link(destination: websiteURL) {
                            HStack(spacing: 12) {
                                Image(systemName: "globe")
                                    .foregroundColor(.secondary)
                                Text(websiteURL.host ?? "Website")
                                    .font(.subheadline)
                                    .foregroundColor(.blue)
                                Spacer()
                                Image(systemName: "arrow.up.right")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }

                    Button {
                        openInAppleMaps()
                    } label: {
                        HStack {
                            Image(systemName: "map.fill")
                            Text("Open in Apple Maps")
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                    }
                }
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
                VStack(alignment: .leading, spacing: 12) {
                    Text("Reactions")
                        .font(.headline)

                    HStack(alignment: .top, spacing: 16) {
                        // Thumbs Up
                        ReactionButton(
                            icon: "hand.thumbsup",
                            filledIcon: "hand.thumbsup.fill",
                            count: place.thumbsUpCount,
                            reactions: place.thumbsUpReactions,
                            isSelected: !authorName.isEmpty && place.hasUserReacted(authorName, type: "thumbsUp"),
                            color: .green,
                            reactionType: "Likes"
                        ) {
                            toggleReaction("thumbsUp")
                        }
                        .disabled(isLoadingUser || authorName.isEmpty)

                        // Thumbs Down
                        ReactionButton(
                            icon: "hand.thumbsdown",
                            filledIcon: "hand.thumbsdown.fill",
                            count: place.thumbsDownCount,
                            reactions: place.thumbsDownReactions,
                            isSelected: !authorName.isEmpty && place.hasUserReacted(authorName, type: "thumbsDown"),
                            color: .red,
                            reactionType: "Dislikes"
                        ) {
                            toggleReaction("thumbsDown")
                        }
                        .disabled(isLoadingUser || authorName.isEmpty)

                        Spacer()
                    }
                }
                .padding(.horizontal)
                .id(refreshID)

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
                        .disabled(newCommentContent.isEmpty || isLoadingUser || authorName.isEmpty)
                    }
                    .padding(.vertical)

                }
                .padding(.horizontal)

                Spacer(minLength: 50)
            }
            .task {
                await fetchUserName()
            }
        }
        .navigationTitle("Place Details")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                NavigationLink("Edit") {
                    EditPlaceContentView(place: place)
                }
            }
        }
    }

    private func toggleReaction(_ type: String) {
        withAnimation {
            if let existingReaction = place.userReaction(for: authorName) {
                if existingReaction.type == type {
                    viewContext.delete(existingReaction)
                } else {
                    existingReaction.type = type
                }
            } else {
                let reaction = Reaction(context: viewContext)
                reaction.id = UUID()
                reaction.type = type
                reaction.authorName = authorName
                reaction.place = place
            }

            do {
                try viewContext.save()
                refreshID = UUID()
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

    private func fetchUserName() async {
        defer { isLoadingUser = false }

        if let participant = await CloudKitService.shared.getCurrentUserAsParticipant(in: viewContext) {
            self.authorName = participant.displayName
            return
        }

        if let displayName = await CloudKitService.shared.getCurrentUserDisplayName() {
            self.authorName = displayName
        } else if let recordID = await CloudKitService.shared.getCurrentUserRecordID() {
            self.authorName = String(recordID.recordName.prefix(8))
        } else {
            self.authorName = "You"
        }
    }

    private func openInAppleMaps() {
        guard let identifierString = place.mapItemIdentifier,
              let identifier = MKMapItem.Identifier(rawValue: identifierString) else {
            openWithCoordinates()
            return
        }

        Task {
            do {
                let request = MKMapItemRequest(mapItemIdentifier: identifier)
                let mapItem = try await request.mapItem
                await MainActor.run {
                    mapItem.openInMaps()
                }
            } catch {
                await MainActor.run {
                    openWithCoordinates()
                }
            }
        }
    }

    private func openWithCoordinates() {
        let mapItem = MKMapItem(placemark: MKPlacemark(coordinate: place.coordinate))
        mapItem.name = place.name
        mapItem.openInMaps()
    }
}

// MARK: - PlaceDetailView (for sheet presentation)
struct PlaceDetailView: View {
    let place: Place
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationView {
            PlaceDetailContent(place: place)
                .toolbar {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button("Close") {
                            dismiss()
                        }
                    }
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

struct ReactionButton: View {
    let icon: String
    let filledIcon: String
    let count: Int
    let reactions: [Reaction]
    let isSelected: Bool
    let color: Color
    let reactionType: String
    let action: () -> Void

    @State private var showingReactorsList = false

    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                HStack(spacing: 4) {
                    Image(systemName: isSelected ? filledIcon : icon)
                        .font(.system(size: 20))
                    Text("\(count)")
                        .font(.subheadline)
                        .fontWeight(.medium)
                }
                .foregroundColor(isSelected ? color : .secondary)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(isSelected ? color.opacity(0.15) : Color.secondary.opacity(0.1))
                )

                // Stacked avatars of people who reacted (always reserve space)
                StackedAvatarsView(reactions: reactions)
            }
        }
        .buttonStyle(PlainButtonStyle())
        .contextMenu {
            if !reactions.isEmpty {
                Button {
                    showingReactorsList = true
                } label: {
                    Label("See who reacted", systemImage: "person.2")
                }
            }
        }
        .sheet(isPresented: $showingReactorsList) {
            ReactorsListView(reactions: reactions, reactionType: reactionType, color: color)
        }
    }
}

struct StackedAvatarsView: View {
    let reactions: [Reaction]
    private let maxVisibleAvatars = 3
    private let avatarSize: CGFloat = 20
    private let overlapOffset: CGFloat = 12

    var body: some View {
        HStack(spacing: 0) {
            ZStack {
                // Invisible placeholder to always reserve height
                Circle()
                    .fill(Color.clear)
                    .frame(width: avatarSize, height: avatarSize)

                ForEach(Array(reactions.prefix(maxVisibleAvatars).enumerated()), id: \.element.id) { index, reaction in
                    ReactionAvatarView(authorName: reaction.authorName ?? "?", size: avatarSize)
                        .offset(x: CGFloat(index) * overlapOffset)
                }

                // Show overflow count if more than max visible
                if reactions.count > maxVisibleAvatars {
                    Circle()
                        .fill(Color.secondary.opacity(0.3))
                        .frame(width: avatarSize, height: avatarSize)
                        .overlay(
                            Text("+\(reactions.count - maxVisibleAvatars)")
                                .font(.system(size: 9, weight: .medium))
                                .foregroundColor(.primary)
                        )
                        .offset(x: CGFloat(maxVisibleAvatars) * overlapOffset)
                }
            }
            .frame(width: stackWidth, alignment: .leading)
        }
    }

    private var stackWidth: CGFloat {
        let visibleCount = min(reactions.count, maxVisibleAvatars)
        let hasOverflow = reactions.count > maxVisibleAvatars
        let totalItems = visibleCount + (hasOverflow ? 1 : 0)
        return avatarSize + CGFloat(max(0, totalItems - 1)) * overlapOffset
    }
}

struct ReactionAvatarView: View {
    let authorName: String
    let size: CGFloat

    var body: some View {
        Circle()
            .fill(avatarColor)
            .frame(width: size, height: size)
            .overlay(
                Text(initials)
                    .font(.system(size: size * 0.4, weight: .medium))
                    .foregroundColor(.white)
            )
            .overlay(
                Circle()
                    .stroke(Color(UIColor.systemBackground), lineWidth: 1.5)
            )
    }

    private var initials: String {
        let components = authorName.components(separatedBy: " ")
        if components.count >= 2 {
            let first = components[0].first.map { String($0).uppercased() } ?? ""
            let last = components[1].first.map { String($0).uppercased() } ?? ""
            return "\(first)\(last)"
        } else if let first = authorName.first {
            return String(first).uppercased()
        }
        return "?"
    }

    private var avatarColor: Color {
        let hash = authorName.hashValue
        let colors: [Color] = [
            Color(red: 255/255, green: 59/255, blue: 48/255),
            Color(red: 255/255, green: 149/255, blue: 0/255),
            Color(red: 52/255, green: 199/255, blue: 89/255),
            Color(red: 0/255, green: 122/255, blue: 255/255),
            Color(red: 88/255, green: 86/255, blue: 214/255),
            Color(red: 175/255, green: 82/255, blue: 222/255),
            Color(red: 255/255, green: 45/255, blue: 146/255),
            Color(red: 90/255, green: 200/255, blue: 250/255),
        ]
        return colors[abs(hash) % colors.count]
    }
}

struct ReactorsListView: View {
    let reactions: [Reaction]
    let reactionType: String
    let color: Color
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationView {
            List {
                ForEach(reactions, id: \.id) { reaction in
                    HStack(spacing: 12) {
                        ReactionAvatarView(authorName: reaction.authorName ?? "Unknown", size: 40)

                        Text(reaction.authorName ?? "Unknown")
                            .font(.body)

                        Spacer()
                    }
                    .padding(.vertical, 4)
                }
            }
            .navigationTitle(reactionType)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - EditPlaceContentView (for NavigationStack push)
struct EditPlaceContentView: View {
    let place: Place
    @Environment(\.dismiss) private var dismiss
    @Environment(\.managedObjectContext) private var viewContext

    @State private var placeName: String
    @State private var placeDescription: String
    @State private var selectedIcon: String
    @State private var selectedColor: String

    private let iconOptions = ["mappin", "house", "building.2", "car", "fork.knife", "cup.and.saucer", "cart", "bag", "heart", "star"]
    private let colorOptions = ["#FF3B30", "#FF9500", "#FFCC02", "#34C759", "#007AFF", "#5856D6", "#AF52DE", "#FF2D92"]

    init(place: Place) {
        self.place = place
        self._placeName = State(initialValue: place.name ?? "")
        self._placeDescription = State(initialValue: place.descriptionText ?? "")
        self._selectedIcon = State(initialValue: place.iconName ?? "mappin")
        self._selectedColor = State(initialValue: place.iconColor ?? "#FF3B30")
    }

    var body: some View {
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
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Save") {
                    saveChanges()
                }
                .disabled(placeName.isEmpty)
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
                dismiss()
            } catch {
                let nsError = error as NSError
                print("Failed to save place: \(nsError), \(nsError.userInfo)")
            }
        }
    }
}

// MARK: - EditPlaceView (for sheet presentation)
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
