import Foundation
import CoreLocation

/// Query parameters for nearby event discovery.
struct EventQuery: Sendable {
    var coordinate: CLLocationCoordinate2D
    var radiusMeters: CLLocationDistance
    var category: EventCategory?
    var dateInterval: DateInterval?

    init(
        coordinate: CLLocationCoordinate2D,
        radiusMeters: CLLocationDistance = 25_000,
        category: EventCategory? = nil,
        dateInterval: DateInterval? = nil
    ) {
        self.coordinate = coordinate
        self.radiusMeters = radiusMeters
        self.category = category
        self.dateInterval = dateInterval
    }
}
