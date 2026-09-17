import Foundation
import CoreLocation
import Observation

/// Discover load/UI phase (Code / Research / Designer).
enum DiscoverPhase: Equatable {
    case loading
    case populated
    case empty(radiusMiles: Int)
    case locationDenied
    case failed(retryable: Bool)
}

@Observable
@MainActor
final class DiscoverViewModel {
    private static let radiusMilesKey = "discoverRadiusMiles"
    static let radiusMilesOptions = [5, 10, 25, 50]

    private let eventService: any EventService

    /// Quiet “Sample events” when the active service is Mock.
    let isSampleData: Bool

    var events: [Event] = []
    var phase: DiscoverPhase = .loading
    /// True while a fetch is in flight (may keep showing prior `.populated` list).
    var isRefreshing = false
    var searchText = ""
    var selectedCategory: EventCategory?

    /// User-controlled search radius in miles (persisted).
    var radiusMiles: Int {
        didSet {
            let clamped = Self.clampedRadiusMiles(radiusMiles)
            if clamped != radiusMiles {
                radiusMiles = clamped
                return
            }
            UserDefaults.standard.set(radiusMiles, forKey: Self.radiusMilesKey)
        }
    }

    var radiusMeters: CLLocationDistance {
        CLLocationDistance(radiusMiles) * 1609.344
    }

    /// Bumps on every `loadEvents` so stale responses are ignored.
    private var loadGeneration = 0
    private var loadTask: Task<Void, Never>?

    init(eventService: any EventService) {
        self.eventService = eventService
        self.isSampleData = eventService is MockEventService
        let stored = UserDefaults.standard.object(forKey: Self.radiusMilesKey) as? Int
        self.radiusMiles = Self.clampedRadiusMiles(stored ?? 25)
    }

    /// Client-side search filter over the last successful fetch.
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

    var emptyFilterMessage: String {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        if !query.isEmpty {
            return "Try another search term or clear the search field."
        }
        if selectedCategory != nil {
            return "Try another category or choose All categories."
        }
        return "Try another category or clear your search."
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
        // Keep prior events on reload — never flash empty while refreshing.
        isRefreshing = true
        if events.isEmpty {
            phase = .loading
        }

        let query = EventQuery(
            coordinate: coordinate,
            radiusMeters: radiusMeters,
            category: selectedCategory,
            dateInterval: nil
        )

        do {
            let result = try await eventService.fetchNearbyEvents(query)
            guard token == loadGeneration, !Task.isCancelled else { return }
            // Success replace only.
            events = result
            phase = Self.phaseAfterSuccess(
                events: result,
                radiusMiles: radiusMiles,
                usingDefaultLocation: usingDefaultLocation
            )
        } catch is CancellationError {
            return
        } catch {
            guard token == loadGeneration, !Task.isCancelled else { return }
            // Hard failure with nothing to show → failed (not empty).
            // Soft failure with prior list → keep events + populated.
            if events.isEmpty {
                phase = .failed(retryable: true)
            }
        }

        guard token == loadGeneration else { return }
        isRefreshing = false
    }

    /// Location denied/off + zero results → `.locationDenied` (never `.empty`).
    private static func phaseAfterSuccess(
        events: [Event],
        radiusMiles: Int,
        usingDefaultLocation: Bool
    ) -> DiscoverPhase {
        if events.isEmpty {
            if usingDefaultLocation {
                return .locationDenied
            }
            return .empty(radiusMiles: radiusMiles)
        }
        return .populated
    }

    private static func clampedRadiusMiles(_ value: Int) -> Int {
        radiusMilesOptions.contains(value) ? value : 25
    }
}
