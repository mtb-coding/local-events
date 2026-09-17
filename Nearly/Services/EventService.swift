import Foundation
import CoreLocation

protocol EventService: Sendable {
    func fetchNearbyEvents(
        near coordinate: CLLocationCoordinate2D,
        radiusMeters: CLLocationDistance
    ) async throws -> [Event]

    func event(id: String) async throws -> Event?
}
