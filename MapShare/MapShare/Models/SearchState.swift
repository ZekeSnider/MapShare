import Foundation
import CoreLocation
import MapKit

@Observable
class SearchState {
    enum Mode {
        case browse
        case search
    }

    var mode: Mode = .browse
    var searchText: String = ""
    var searchResults: [SearchResult] = []
    var isLoading: Bool = false
    var centerOnResult: SearchResult? = nil  // Set to center map on this result
    var resultToNavigate: SearchResult? = nil  // Set when map annotation is tapped to trigger navigation
    var highlightedResult: SearchResult? = nil  // The result currently being viewed (pin should be highlighted)
    var showSearchHereButton: Bool = false
    var lastSearchRegion: MKCoordinateRegion?
    var searchGeneration: Int = 0
    var mapRegion: MKCoordinateRegion = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194),
        span: MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)
    )

    func startSearch() {
        mode = .search
        centerOnResult = nil
        resultToNavigate = nil
    }

    func clearSearch() {
        searchText = ""
        searchResults = []
        centerOnResult = nil
        resultToNavigate = nil
        highlightedResult = nil
        showSearchHereButton = false
        lastSearchRegion = nil
        mode = .browse
    }

    func mapRegionDidChange(_ newRegion: MKCoordinateRegion) {
        mapRegion = newRegion
        guard mode == .search, !searchResults.isEmpty, let lastRegion = lastSearchRegion else { return }

        let centerDelta = abs(newRegion.center.latitude - lastRegion.center.latitude) + abs(newRegion.center.longitude - lastRegion.center.longitude)
        let spanDelta = abs(newRegion.span.latitudeDelta - lastRegion.span.latitudeDelta) + abs(newRegion.span.longitudeDelta - lastRegion.span.longitudeDelta)

        if centerDelta > 0.01 || spanDelta > 0.05 {
            showSearchHereButton = true
        }
    }

    func performSearch() async {
        guard !searchText.isEmpty else {
            searchResults = []
            return
        }

        isLoading = true
        defer { isLoading = false }

        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = searchText
        request.region = mapRegion

        do {
            let search = MKLocalSearch(request: request)
            let response = try await search.start()
            await MainActor.run {
                searchResults = response.mapItems.map { SearchResult(mapItem: $0) }
                lastSearchRegion = mapRegion
                showSearchHereButton = false
                searchGeneration += 1
            }
        } catch {
            await MainActor.run {
                searchResults = []
            }
        }
    }

}
