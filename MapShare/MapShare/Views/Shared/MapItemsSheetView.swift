import SwiftUI
import CoreLocation

struct MapItemsListView: View {
    let document: Document
    @Binding var selectedPlace: Place?
    @Binding var centerOnPlace: Place?
    @State private var navigationPath = NavigationPath()

    var body: some View {
        NavigationStack(path: $navigationPath) {
            List {
                if document.placesArray.isEmpty {
                    ContentUnavailableView {
                        Label("No Places", systemImage: "map")
                    } description: {
                        Text("Tap + to add places to this map")
                    }
                } else {
                    ForEach(document.placesArray, id: \.id) { place in
                        PlaceRowView(
                            place: place,
                            isSelected: selectedPlace?.id == place.id,
                            onTap: {
                                selectedPlace = place
                                centerOnPlace = place
                                navigationPath.append(place)
                            }
                        )
                        .listRowInsets(EdgeInsets())
                    }
                }
            }
            .listStyle(.plain)
            .navigationTitle("Map Items")
            .navigationBarTitleDisplayMode(.inline)
            .navigationDestination(for: Place.self) { place in
                PlaceDetailContent(place: place)
            }
        }
        .onChange(of: selectedPlace) { oldValue, newValue in
            // When map pin is tapped (selectedPlace changes externally), navigate to it
            if let place = newValue, navigationPath.isEmpty {
                navigationPath.append(place)
            }
        }
        .onChange(of: navigationPath) { oldValue, newValue in
            // Clear selection when navigating back to the list
            if newValue.isEmpty && selectedPlace != nil {
                selectedPlace = nil
            }
        }
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

                    if let addedBy = place.addedBy {
                        HStack(spacing: 4) {
                            ProfileAvatarView(participant: addedBy, size: 16)
                            Text(addedBy.displayName)
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .lineLimit(1)
                        }
                    } else if let description = place.descriptionText, !description.isEmpty {
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
