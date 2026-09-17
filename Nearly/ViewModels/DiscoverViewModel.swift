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

    /// Bumps on every `loadEvents` so stale responses are ignored.
    private var loadGeneration = 0
    private var loadTask: Task<Void, Never>?

    init(eventService: any EventService) {
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

    /// In-memory cache hit for a loaded event.
    func cachedEvent(id: String) -> Event? {
        events.first { $0.id == id }
    }

    /// Resolve detail: in-memory → live `event(id:)` → SavedEvent hydrate.
    func resolveEvent(id: String, savedStore: SavedStore?) async -> Event? {
        if let cached = cachedEvent(id: id) {
            return cached
        }
        do {
            if let live = try await eventService.event(id: id) {
                return live
            }
        } catch {
            // Fall through to Saved hydrate (offline / API miss).
        }
        return savedStore?.event(id: id)
    }

    func loadEvents(near coordinate: CLLocationCoordinate2D, usingDefaultLocation: Bool) async {
        loadTask?.cancel()
        loadGeneration += 1
        let token = loadGeneration

        let task = Task { [eventService] in
            await self.performLoad(
                token: token,
                coordinate: coordinate,
                usingDefaultLocation: usingDefaultLocation,
                eventService: eventService
            )
        }
        loadTask = task
        await task.value
    }

    private func performLoad(
        token: Int,
        coordinate: CLLocationCoordinate2D,
        usingDefaultLocation: Bool,
        eventService: any EventService
    ) async {
        isLoading = true
        errorMessage = nil
        showingLocationDeniedBanner = usingDefaultLocation

        let query = EventQuery(
            coordinate: coordinate,
            radiusMeters: 25_000,
            category: nil,
            dateInterval: nil
        )

        do {
            let result = try await eventService.fetchNearbyEvents(query)
            guard token == loadGeneration, !Task.isCancelled else { return }
            events = result
        } catch is CancellationError {
            return
        } catch {
            guard token == loadGeneration, !Task.isCancelled else { return }
            errorMessage = "Couldn't load events. Pull to refresh."
        }

        guard token == loadGeneration else { return }
        isLoading = false
    }
}
