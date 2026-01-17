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
        mode = .browse
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
            }
        } catch {
            await MainActor.run {
                searchResults = []
            }
        }
    }

}
