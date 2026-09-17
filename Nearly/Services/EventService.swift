import Foundation
import CoreLocation

protocol EventService: Sendable {
    func fetchNearbyEvents(_ query: EventQuery) async throws -> [Event]
    func event(id: String) async throws -> Event?
}
