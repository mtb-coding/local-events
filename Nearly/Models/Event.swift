import Foundation
import CoreLocation

struct Event: Identifiable, Codable, Hashable {
    let id: String
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
    let imageSystemName: String

    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }

    var location: CLLocation {
        CLLocation(latitude: latitude, longitude: longitude)
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
