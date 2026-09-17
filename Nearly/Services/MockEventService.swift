import Foundation
import CoreLocation

struct MockEventService: EventService {
    static let nycCenter = CLLocationCoordinate2D(latitude: 40.7580, longitude: -73.9855)

    private let events: [Event]

    init(calendar: Calendar = .current, now: Date = .now) {
        self.events = Self.makeMockEvents(calendar: calendar, now: now)
    }

    func fetchNearbyEvents(_ query: EventQuery) async throws -> [Event] {
        try await Task.sleep(nanoseconds: 250_000_000)
        let center = CLLocation(latitude: query.coordinate.latitude, longitude: query.coordinate.longitude)

        return events
            .filter { event in
                if let category = query.category, event.category != category {
                    return false
                }
                if let interval = query.dateInterval, !interval.contains(event.startDate) {
                    return false
                }
                return true
            }
            .map { event in
                (event, event.location.distance(from: center))
            }
            .filter { $0.1 <= query.radiusMeters }
            .sorted { $0.1 < $1.1 }
            .map(\.0)
    }

    func event(id: String) async throws -> Event? {
        events.first { $0.id == id }
    }

    private static func makeMockEvents(calendar: Calendar, now: Date) -> [Event] {
        func date(days: Int, hour: Int, minute: Int = 0) -> Date {
            var comps = calendar.dateComponents([.year, .month, .day], from: now)
            comps.hour = hour
            comps.minute = minute
            let base = calendar.date(from: comps) ?? now
            return calendar.date(byAdding: .day, value: days, to: base) ?? base
        }

        return [
            Event(
                rawID: "evt-01",
                source: .mock,
                title: "Jazz Under the Arch",
                description: "Live jazz under Washington Square Arch.",
                startDate: date(days: 0, hour: 19, minute: 30),
                endDate: date(days: 0, hour: 22),
                venueName: "Washington Square Park",
                neighborhood: "Greenwich Village",
                address: "Washington Square, New York, NY 10012",
                latitude: 40.7308, longitude: -73.9973,
                category: .music,
                imageSystemName: "music.note.list"
            ),
            Event(
                rawID: "evt-02",
                source: .mock,
                title: "Chelsea Market Food Crawl",
                description: "Guided tasting of Chelsea Market favorites.",
                startDate: date(days: 1, hour: 12),
                endDate: date(days: 1, hour: 14, minute: 30),
                venueName: "Chelsea Market",
                neighborhood: "Chelsea",
                address: "75 9th Ave, New York, NY 10011",
                latitude: 40.7420, longitude: -74.0048,
                category: .food,
                imageSystemName: "fork.knife.circle"
            ),
            Event(
                rawID: "evt-03",
                source: .mock,
                title: "MoMA Late Night Sketch",
                description: "After-hours drawing at MoMA.",
                startDate: date(days: 2, hour: 18, minute: 30),
                endDate: date(days: 2, hour: 21),
                venueName: "Museum of Modern Art",
                neighborhood: "Midtown",
                address: "11 W 53rd St, New York, NY 10019",
                latitude: 40.7614, longitude: -73.9776,
                category: .arts,
                imageSystemName: "paintbrush.pointed"
            ),
            Event(
                rawID: "evt-04",
                source: .mock,
                title: "Brooklyn Bridge Sunrise Run",
                description: "5K group jog over the Brooklyn Bridge.",
                startDate: date(days: 3, hour: 6, minute: 30),
                endDate: date(days: 3, hour: 8),
                venueName: "Brooklyn Bridge Park",
                neighborhood: "DUMBO",
                address: "334 Furman St, Brooklyn, NY 11201",
                latitude: 40.7021, longitude: -73.9969,
                category: .sports,
                imageSystemName: "figure.run"
            ),
            Event(
                rawID: "evt-05",
                source: .mock,
                title: "Rooftop Indie Night",
                description: "Indie bands on a Lower East Side rooftop.",
                startDate: date(days: 1, hour: 20),
                endDate: date(days: 2, hour: 0),
                venueName: "The Roof at PhD",
                neighborhood: "Lower East Side",
                address: "155 Rivington St, New York, NY 10002",
                latitude: 40.7195, longitude: -73.9870,
                category: .nightlife,
                imageSystemName: "moon.stars.fill"
            ),
            Event(
                rawID: "evt-06",
                source: .mock,
                title: "Central Park Bird Walk",
                description: "Guided migratory songbird walk.",
                startDate: date(days: 4, hour: 7, minute: 30),
                endDate: date(days: 4, hour: 9, minute: 30),
                venueName: "Central Park Conservancy",
                neighborhood: "Upper West Side",
                address: "West 72nd St entrance, New York, NY 10023",
                latitude: 40.7769, longitude: -73.9761,
                category: .outdoors,
                imageSystemName: "bird"
            ),
            Event(
                rawID: "evt-07",
                source: .mock,
                title: "Harlem Community Potluck",
                description: "Neighborhood potluck and food bank drive.",
                startDate: date(days: 5, hour: 17),
                endDate: date(days: 5, hour: 20),
                venueName: "Marcus Garvey Park",
                neighborhood: "Harlem",
                address: "18 Mt Morris Park W, New York, NY 10027",
                latitude: 40.8044, longitude: -73.9436,
                category: .community,
                imageSystemName: "person.3.fill"
            ),
            Event(
                rawID: "evt-08",
                source: .mock,
                title: "Stand-Up at The Stand",
                description: "NYC comics showcase night.",
                startDate: date(days: 0, hour: 21),
                endDate: date(days: 0, hour: 23),
                venueName: "The Stand",
                neighborhood: "Union Square",
                address: "116 E 16th St, New York, NY 10003",
                latitude: 40.7359, longitude: -73.9875,
                category: .comedy,
                imageSystemName: "mic"
            ),
            Event(
                rawID: "evt-09",
                source: .mock,
                title: "Williamsburg Vinyl Fair",
                description: "Rare pressings and DJ sets.",
                startDate: date(days: 6, hour: 11),
                endDate: date(days: 6, hour: 18),
                venueName: "Brooklyn Steel Lobby",
                neighborhood: "Williamsburg",
                address: "319 Frost St, Brooklyn, NY 11222",
                latitude: 40.7195, longitude: -73.9342,
                category: .music,
                imageSystemName: "opticaldisc"
            ),
            Event(
                rawID: "evt-10",
                source: .mock,
                title: "Smorgasburg Picnic",
                description: "Open-air food market by the East River.",
                startDate: date(days: 6, hour: 11),
                endDate: date(days: 6, hour: 18),
                venueName: "Smorgasburg",
                neighborhood: "Williamsburg",
                address: "90 Kent Ave, Brooklyn, NY 11249",
                latitude: 40.7215, longitude: -73.9614,
                category: .food,
                imageSystemName: "takeoutbag.and.cup.and.straw"
            ),
            Event(
                rawID: "evt-11",
                source: .mock,
                title: "Gallery Hop: Chelsea",
                description: "Self-guided Chelsea gallery afternoon.",
                startDate: date(days: 2, hour: 14),
                endDate: date(days: 2, hour: 18),
                venueName: "Chelsea Art District",
                neighborhood: "Chelsea",
                address: "W 24th St and 10th Ave, New York, NY 10011",
                latitude: 40.7480, longitude: -74.0045,
                category: .arts,
                imageSystemName: "building.columns"
            ),
            Event(
                rawID: "evt-12",
                source: .mock,
                title: "Pickup Soccer at Pier 40",
                description: "Casual 7v7 on the Hudson.",
                startDate: date(days: 3, hour: 18),
                endDate: date(days: 3, hour: 20),
                venueName: "Pier 40",
                neighborhood: "Hudson Square",
                address: "353 West St, New York, NY 10014",
                latitude: 40.7295, longitude: -74.0115,
                category: .sports,
                imageSystemName: "soccerball"
            ),
            Event(
                rawID: "evt-13",
                source: .mock,
                title: "Speakeasy Cocktail Class",
                description: "Learn three classics behind a hidden bar.",
                startDate: date(days: 4, hour: 19),
                endDate: date(days: 4, hour: 21),
                venueName: "Employees Only",
                neighborhood: "West Village",
                address: "510 Hudson St, New York, NY 10014",
                latitude: 40.7336, longitude: -74.0060,
                category: .nightlife,
                imageSystemName: "wineglass"
            ),
            Event(
                rawID: "evt-14",
                source: .mock,
                title: "Prospect Park Picnic Concert",
                description: "Free outdoor brass concert.",
                startDate: date(days: 7, hour: 16),
                endDate: date(days: 7, hour: 18),
                venueName: "Prospect Park Bandshell",
                neighborhood: "Park Slope",
                address: "9th St and Prospect Park W, Brooklyn, NY 11215",
                latitude: 40.6602, longitude: -73.9690,
                category: .outdoors,
                imageSystemName: "tree"
            ),
            Event(
                rawID: "evt-15",
                source: .mock,
                title: "Astoria Book Swap",
                description: "Bring books to trade; author readings.",
                startDate: date(days: 5, hour: 15),
                endDate: date(days: 5, hour: 18),
                venueName: "Astoria Library",
                neighborhood: "Astoria",
                address: "14-01 Astoria Blvd, Astoria, NY 11102",
                latitude: 40.7724, longitude: -73.9309,
                category: .community,
                imageSystemName: "books.vertical"
            ),
            Event(
                rawID: "evt-16",
                source: .mock,
                title: "Improv Jam: UCB East",
                description: "Open improv jam for all levels.",
                startDate: date(days: 1, hour: 19, minute: 30),
                endDate: date(days: 1, hour: 22),
                venueName: "UCB Theatre East",
                neighborhood: "East Village",
                address: "153 E 3rd St, New York, NY 10009",
                latitude: 40.7230, longitude: -73.9845,
                category: .comedy,
                imageSystemName: "theatermasks"
            ),
            Event(
                rawID: "evt-17",
                source: .mock,
                title: "Times Square Silent Disco",
                description: "Wireless headphone dance under the lights.",
                startDate: date(days: 8, hour: 21),
                endDate: date(days: 8, hour: 23, minute: 30),
                venueName: "Duffy Square",
                neighborhood: "Times Square",
                address: "1560 Broadway, New York, NY 10036",
                latitude: 40.7587, longitude: -73.9851,
                category: .nightlife,
                imageSystemName: "headphones"
            ),
            Event(
                rawID: "evt-18",
                source: .mock,
                title: "Queens Night Market Preview",
                description: "Early-season vendor tasting night.",
                startDate: date(days: 9, hour: 17),
                endDate: date(days: 9, hour: 22),
                venueName: "New York Hall of Science Lot",
                neighborhood: "Flushing Meadows",
                address: "47-01 111th St, Corona, NY 11368",
                latitude: 40.7472, longitude: -73.8517,
                category: .food,
                imageSystemName: "flame"
            )
        ]
    }
}
