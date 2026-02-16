import SwiftUI
import CoreLocation

struct MapItemsListView: View {
    let document: Document
    @Binding var selectedPlace: Place?
    @Binding var centerOnPlace: Place?
    @Bindable var searchState: SearchState
    @State private var navigationPath = NavigationPath()
    @FocusState private var isSearchFieldFocused: Bool
    @Environment(\.managedObjectContext) private var viewContext

    var body: some View {
        NavigationStack(path: $navigationPath) {
            VStack(spacing: 0) {
                // Search bar - only visible in search mode
                if searchState.mode == .search {
                    SearchBarView(
                        searchText: $searchState.searchText,
                        isFocused: $isSearchFieldFocused,
                        onSubmit: {
                            Task {
                                await searchState.performSearch()
                            }
                        },
                        onCancel: {
                            searchState.clearSearch()
                        }
                    )
                    .padding(.horizontal)
                    .padding(.vertical, 8)
                }

                // Content based on mode
                if searchState.mode == .search {
                    searchContent
                } else {
                    browseContent
                }
            }
            .navigationTitle(searchState.mode == .search ? "Search" : "Places")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                if searchState.mode == .browse {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button {
                            searchState.startSearch()
                            isSearchFieldFocused = true
                        } label: {
                            Image(systemName: "plus")
                        }
                    }
                }
            }
            .navigationDestination(for: Place.self) { place in
                PlaceDetailContent(place: place)
            }
            .navigationDestination(for: SearchResult.self) { result in
                AddPlaceViewEmbedded(
                    document: document,
                    isPresented: .constant(true),
                    prefilledName: result.name,
                    prefilledCoordinate: result.coordinate,
                    prefilledAddress: result.address,
                    prefilledPhoneNumber: result.phoneNumber,
                    prefilledWebsiteURL: result.url,
                    prefilledMapItemIdentifier: result.mapItemIdentifier,
                    prefilledIcon: iconForCategory(result.category),
                    onSave: {
                        searchState.clearSearch()
                        navigationPath.removeLast()
                    }
                )
            }
            .navigationDestination(for: String.self) { _ in
                AddPlaceViewEmbedded(
                    document: document,
                    isPresented: .constant(true),
                    prefilledName: nil,
                    prefilledCoordinate: nil,
                    prefilledAddress: nil,
                    prefilledPhoneNumber: nil,
                    prefilledWebsiteURL: nil,
                    prefilledMapItemIdentifier: nil,
                    onSave: {
                        searchState.clearSearch()
                        navigationPath.removeLast()
                    }
                )
            }
        }
        .onChange(of: selectedPlace) { oldValue, newValue in
            if let place = newValue, searchState.mode == .browse {
                if navigationPath.isEmpty {
                    navigationPath.append(place)
                } else {
                    // Replace current detail with the newly selected place
                    var newPath = NavigationPath()
                    newPath.append(place)
                    navigationPath = newPath
                }
            }
        }
        .onChange(of: navigationPath) { oldValue, newValue in
            if newValue.isEmpty && selectedPlace != nil {
                selectedPlace = nil
            }
            // Clear highlight when navigating back to search results
            if newValue.isEmpty && searchState.highlightedResult != nil {
                searchState.highlightedResult = nil
            }
        }
        .onChange(of: searchState.mode) { oldValue, newValue in
            if newValue == .search {
                isSearchFieldFocused = true
            }
        }
        .onChange(of: searchState.resultToNavigate) { oldValue, newValue in
            // Navigate when a search result is tapped on the map
            if let result = newValue {
                searchState.highlightedResult = result
                navigationPath.append(result)
                searchState.resultToNavigate = nil
            }
        }
    }

    @ViewBuilder
    private var browseContent: some View {
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
    }

    @ViewBuilder
    private var searchContent: some View {
        ZStack {
            if searchState.isLoading {
                VStack {
                    ProgressView("Searching...")
                    Spacer()
                }
                .padding(.top, 40)
            } else if searchState.searchResults.isEmpty && !searchState.searchText.isEmpty {
                ContentUnavailableView("No Results",
                    systemImage: "magnifyingglass",
                    description: Text("Try a different search term"))
            } else if searchState.searchResults.isEmpty {
                VStack(spacing: 16) {
                    ContentUnavailableView("Search for Places",
                        systemImage: "map",
                        description: Text("Find restaurants, shops, landmarks, and more"))

                    Button {
                        navigationPath.append("custom")
                    } label: {
                        Label("Add Custom Place", systemImage: "plus.circle")
                    }
                    .buttonStyle(.bordered)
                }
            } else {
                List(searchState.searchResults) { result in
                    SearchResultRowView(
                        result: result,
                        onTap: {
                            searchState.centerOnResult = result
                            searchState.highlightedResult = result
                            navigationPath.append(result)
                        }
                    )
                    .listRowInsets(EdgeInsets())
                }
                .listStyle(.plain)
            }
        }
    }
}

// MARK: - Search Bar

struct SearchBarView: View {
    @Binding var searchText: String
    var isFocused: FocusState<Bool>.Binding
    let onSubmit: () -> Void
    let onCancel: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)

                TextField("Search for a place...", text: $searchText)
                    .textFieldStyle(.plain)
                    .autocorrectionDisabled()
                    .focused(isFocused)
                    .onSubmit(onSubmit)

                if !searchText.isEmpty {
                    Button {
                        searchText = ""
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.secondary)
                    }
                }
            }
            .padding(10)
            .background(Color(.systemGray6))
            .cornerRadius(10)

            Button("Cancel", action: onCancel)
                .foregroundColor(.blue)
        }
    }
}

// MARK: - Search Result Row

struct SearchResultRowView: View {
    let result: SearchResult
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(Color.blue.opacity(0.1))
                        .frame(width: 40, height: 40)

                    Image(systemName: iconForCategory(result.category))
                        .foregroundColor(.blue)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(result.name)
                        .font(.body)
                        .foregroundColor(.primary)

                    if !result.address.isEmpty {
                        Text(result.address)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                    }
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .foregroundColor(.secondary)
                    .font(.caption)
            }
            .padding(.horizontal)
            .padding(.vertical, 10)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

}

// MARK: - Place Row View

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
