import Foundation
import CoreLocation

struct Event: Identifiable, Codable, Hashable {
    /// Collision-safe provider-prefixed id (`mock:…`, `ticketmaster:…`).
    let id: String
    /// Raw provider id without prefix (also persisted on SavedEvent).
    let rawID: String
    let title: String
    let description: String
    let startDate: Date
    let endDate: Date?
    let venueName: String
    let neighborhood: String
    let address: String
    let latitude: Double
    let longitude: Double
    let category: EventCategory
    /// SF Symbol fallback when `imageURL` is nil.
    let imageSystemName: String
    let imageURL: URL?
    let source: EventSource

    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }

    var location: CLLocation {
        CLLocation(latitude: latitude, longitude: longitude)
    }

    init(
        rawID: String,
        source: EventSource,
        title: String,
        description: String,
        startDate: Date,
        endDate: Date?,
        venueName: String,
        neighborhood: String,
        address: String,
        latitude: Double,
        longitude: Double,
        category: EventCategory,
        imageSystemName: String,
        imageURL: URL? = nil
    ) {
        self.rawID = rawID
        self.source = source
        self.id = source.prefixedID(rawID)
        self.title = title
        self.description = description
        self.startDate = startDate
        self.endDate = endDate
        self.venueName = venueName
        self.neighborhood = neighborhood
        self.address = address
        self.latitude = latitude
        self.longitude = longitude
        self.category = category
        self.imageSystemName = imageSystemName
        self.imageURL = imageURL
    }

    /// Full memberwise for SwiftData hydration when id is already prefixed.
    init(
        id: String,
        rawID: String,
        title: String,
        description: String,
        startDate: Date,
        endDate: Date?,
        venueName: String,
        neighborhood: String,
        address: String,
        latitude: Double,
        longitude: Double,
        category: EventCategory,
        imageSystemName: String,
        imageURL: URL?,
        source: EventSource
    ) {
        self.id = id
        self.rawID = rawID
        self.title = title
        self.description = description
        self.startDate = startDate
        self.endDate = endDate
        self.venueName = venueName
        self.neighborhood = neighborhood
        self.address = address
        self.latitude = latitude
        self.longitude = longitude
        self.category = category
        self.imageSystemName = imageSystemName
        self.imageURL = imageURL
        self.source = source
    }

    func distance(from userLocation: CLLocation?) -> CLLocationDistance? {
        guard let userLocation else { return nil }
        return location.distance(from: userLocation)
    }

    func formattedDistance(from userLocation: CLLocation?) -> String {
        guard let meters = distance(from: userLocation) else {
            return "Nearby"
        }
        let miles = meters / 1609.344
        if miles < 0.1 {
            return "Nearby"
        }
        if miles < 10 {
            return String(format: "%.1f mi", miles)
        }
        return String(format: "%.0f mi", miles)
    }
}
