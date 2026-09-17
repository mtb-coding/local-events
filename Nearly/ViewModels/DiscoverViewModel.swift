import Foundation
import CoreLocation
import Observation

@Observable
@MainActor
final class DiscoverViewModel {
    private let eventService: any EventService

    var events: [Event] = []
    var isLoading = false
    var errorMessage: String?
    var searchText = ""
    var selectedCategory: EventCategory?
    var showingLocationDeniedBanner = false

    init(eventService: any EventService = MockEventService()) {
        self.eventService = eventService
    }

    var filteredEvents: [Event] {
        events.filter { event in
            let matchesCategory = selectedCategory.map { event.category == $0 } ?? true
            let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
            let matchesSearch = query.isEmpty
                || event.title.localizedCaseInsensitiveContains(query)
                || event.neighborhood.localizedCaseInsensitiveContains(query)
                || event.venueName.localizedCaseInsensitiveContains(query)
                || event.category.rawValue.localizedCaseInsensitiveContains(query)
            return matchesCategory && matchesSearch
        }
    }

    func loadEvents(near coordinate: CLLocationCoordinate2D, usingDefaultLocation: Bool) async {
        isLoading = true
        errorMessage = nil
        showingLocationDeniedBanner = usingDefaultLocation
        defer { isLoading = false }

        do {
            events = try await eventService.fetchNearbyEvents(
                near: coordinate,
                radiusMeters: 25_000
            )
        } catch {
            errorMessage = "Couldn't load events. Pull to refresh."
        }
    }
}
