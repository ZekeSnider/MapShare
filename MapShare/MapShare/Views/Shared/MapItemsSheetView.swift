import SwiftUI
import CoreLocation

struct MapItemsListView: View {
    let document: Document
    @Binding var selectedPlace: Place?
    @Binding var selectedNote: Note?

    var body: some View {
        VStack(spacing: 0) {
            // Drag handle
            Capsule()
                .fill(Color.secondary.opacity(0.5))
                .frame(width: 36, height: 5)
                .padding(.top, 8)
                .padding(.bottom, 4)

            // Header
            HStack {
                Text("Map Items")
                    .font(.headline)
                Spacer()
            }
            .padding(.horizontal)
            .padding(.bottom, 8)

            Divider()

            // Items list
            ScrollView {
                LazyVStack(spacing: 0) {
                    // Places
                    if !document.placesArray.isEmpty {
                        SectionHeader(title: "Places", count: document.placesArray.count)

                        ForEach(document.placesArray, id: \.id) { place in
                            PlaceRowView(
                                place: place,
                                isSelected: selectedPlace?.id == place.id,
                                onTap: {
                                    selectedPlace = place
                                    selectedNote = nil
                                }
                            )
                        }
                    }

                    // Notes
                    if !document.notesArray.isEmpty {
                        SectionHeader(title: "Notes", count: document.notesArray.count)

                        ForEach(document.notesArray, id: \.id) { note in
                            NoteRowView(
                                note: note,
                                isSelected: selectedNote?.id == note.id,
                                onTap: {
                                    selectedNote = note
                                    selectedPlace = nil
                                }
                            )
                        }
                    }

                    // Shapes
                    if !document.shapesArray.isEmpty {
                        SectionHeader(title: "Emojis", count: document.shapesArray.count)

                        ForEach(document.shapesArray, id: \.id) { shape in
                            ShapeRowView(shape: shape)
                        }
                    }

                    // Empty state
                    if document.placesArray.isEmpty && document.notesArray.isEmpty && document.shapesArray.isEmpty {
                        VStack(spacing: 12) {
                            Image(systemName: "map")
                                .font(.system(size: 40))
                                .foregroundColor(.secondary)
                            Text("No items yet")
                                .font(.headline)
                                .foregroundColor(.secondary)
                            Text("Tap + to add places, notes, or emojis")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 40)
                    }
                }
                .padding(.bottom, 20)
            }
        }
        .frame(maxWidth: .infinity)
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .shadow(color: .black.opacity(0.15), radius: 8, y: -2)
    }
}

// MARK: - Section Header

struct SectionHeader: View {
    let title: String
    let count: Int

    var body: some View {
        HStack {
            Text(title)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(.secondary)

            Text("\(count)")
                .font(.caption)
                .foregroundColor(.secondary)
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(Color.secondary.opacity(0.2))
                .clipShape(Capsule())

            Spacer()
        }
        .padding(.horizontal)
        .padding(.top, 16)
        .padding(.bottom, 8)
    }
}

// MARK: - Row Views

struct PlaceRowView: View {
    let place: Place
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(Color(hex: place.iconColor ?? "#FF3B30"))
                        .frame(width: 36, height: 36)

                    Image(systemName: place.iconName ?? "mappin")
                        .font(.system(size: 16))
                        .foregroundColor(.white)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(place.name ?? "Unnamed Place")
                        .font(.body)
                        .foregroundColor(.primary)

                    if let description = place.descriptionText, !description.isEmpty {
                        Text(description)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                    }
                }

                Spacer()

                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.blue)
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 10)
            .background(isSelected ? Color.blue.opacity(0.1) : Color.clear)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

struct NoteRowView: View {
    let note: Note
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(Color.black.opacity(0.6))
                        .frame(width: 36, height: 36)

                    Image(systemName: "note.text")
                        .font(.system(size: 16))
                        .foregroundColor(.yellow)
                }

                Text(note.content ?? "Empty note")
                    .font(.body)
                    .foregroundColor(.primary)
                    .lineLimit(2)

                Spacer()

                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.blue)
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 10)
            .background(isSelected ? Color.blue.opacity(0.1) : Color.clear)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

struct ShapeRowView: View {
    let shape: Shape

    var body: some View {
        HStack(spacing: 12) {
            Text(shape.emoji ?? "❓")
                .font(.system(size: 28))
                .frame(width: 36, height: 36)

            Text("Emoji")
                .font(.body)
                .foregroundColor(.primary)

            Spacer()
        }
        .padding(.horizontal)
        .padding(.vertical, 10)
        .contentShape(Rectangle())
    }
}
