import Foundation
import SwiftData

@Model
final class SavedEvent {
    /// Prefixed id (`mock:…` / `ticketmaster:…`).
    @Attribute(.unique) var eventId: String
    /// Raw provider id without prefix.
    var rawEventId: String
    var title: String
    var eventDescription: String
    var startDate: Date
    var endDate: Date?
    var venueName: String
    var neighborhood: String
    var address: String
    var latitude: Double
    var longitude: Double
    var categoryRaw: String
    var imageSystemName: String
    var imageURLString: String?
    /// `EventSource.rawValue`
    var sourceRaw: String
    var savedAt: Date

    init(from event: Event, savedAt: Date = .now) {
        self.eventId = event.id
        self.rawEventId = event.rawID
        self.title = event.title
        self.eventDescription = event.description
        self.startDate = event.startDate
        self.endDate = event.endDate
        self.venueName = event.venueName
        self.neighborhood = event.neighborhood
        self.address = event.address
        self.latitude = event.latitude
        self.longitude = event.longitude
        self.categoryRaw = event.category.rawValue
        self.imageSystemName = event.imageSystemName
        self.imageURLString = event.imageURL?.absoluteString
        self.sourceRaw = event.source.rawValue
        self.savedAt = savedAt
    }

    var asEvent: Event {
        let source = EventSource(rawValue: sourceRaw) ?? .unknown
        let raw = rawEventId.isEmpty ? EventSource.split(eventId).rawID : rawEventId
        return Event(
            id: eventId,
            rawID: raw,
            title: title,
            description: eventDescription,
            startDate: startDate,
            endDate: endDate,
            venueName: venueName,
            neighborhood: neighborhood,
            address: address,
            latitude: latitude,
            longitude: longitude,
            category: EventCategory(rawValue: categoryRaw) ?? .community,
            imageSystemName: imageSystemName,
            imageURL: imageURLString.flatMap(URL.init(string:)),
            source: source
        )
    }
}
