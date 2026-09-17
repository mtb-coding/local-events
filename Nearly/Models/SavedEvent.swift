import Foundation
import SwiftData

@Model
final class SavedEvent {
    @Attribute(.unique) var eventId: String
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
    var savedAt: Date

    init(from event: Event, savedAt: Date = .now) {
        self.eventId = event.id
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
        self.savedAt = savedAt
    }

    var asEvent: Event {
        Event(
            id: eventId,
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
            imageSystemName: imageSystemName
        )
    }
}
