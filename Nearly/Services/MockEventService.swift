import Foundation
import CoreLocation

struct MockEventService: EventService {
    static let nycCenter = CLLocationCoordinate2D(latitude: 40.7580, longitude: -73.9855)

    private let events: [Event]

    init(calendar: Calendar = .current, now: Date = .now) {
        self.events = Self.makeMockEvents(calendar: calendar, now: now)
    }

    func fetchNearbyEvents(
        near coordinate: CLLocationCoordinate2D,
        radiusMeters: CLLocationDistance
    ) async throws -> [Event] {
        try await Task.sleep(nanoseconds: 250_000_000)
        let center = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
        return events
            .map { event in
                (event, event.location.distance(from: center))
            }
            .filter { $0.1 <= radiusMeters }
            .sorted { $0.1 < $1.1 }
            .map(\.0)
    }

    func event(id: String) async throws -> Event? {
        events.first { $0.id == id }
    }

    // MARK: - Seed data (~18 events around NYC)

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
                id: "evt-01",
                title: "Jazz Under the Arch",
                description: "An intimate evening of live jazz with local ensembles beneath Washington Square Arch. Bring a blanket and settle in for standards and originals.",
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
                id: "evt-02",
                title: "Chelsea Market Food Crawl",
                description: "Sample bites from ten favorite vendors with a local guide. Vegetarian options available; tickets include tastings and a souvenir tote.",
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
                id: "evt-03",
                title: "MoMA Late Night Sketch",
                description: "After-hours drawing session inspired by current exhibitions. Materials provided; all skill levels welcome.",
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
                id: "evt-04",
                title: "Brooklyn Bridge Sunrise Run",
                description: "5K group jog from Brooklyn Bridge Park over the bridge and back. Pace groups for beginners through intermediate runners.",
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
                id: "evt-05",
                title: "Rooftop Indie Night",
                description: "Three rising NYC indie bands on a Lower East Side rooftop. Doors at 8; skyline views included.",
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
                id: "evt-06",
                title: "Central Park Bird Walk",
                description: "Morning guided walk focused on migratory songbirds. Binoculars available to borrow; limited to 20 guests.",
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
                id: "evt-07",
                title: "Harlem Community Potluck",
                description: "Neighborhood potluck celebrating local makers and musicians. Bring a dish to share or donate to the food bank drive.",
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
                id: "evt-08",
                title: "Stand-Up at The Stand",
                description: "Showcase night featuring comics from NYC club circuit. Two-drink minimum; 21+.",
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
                id: "evt-09",
                title: "Williamsburg Vinyl Fair",
                description: "Dozens of sellers with rare pressings, new releases, and listening stations. Live DJ sets all afternoon.",
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
                id: "evt-10",
                title: "Smorgasburg Picnic",
                description: "Open-air market with dozens of food vendors along the East River. Grab a plate and watch the ferries roll by.",
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
                id: "evt-11",
                title: "Gallery Hop: Chelsea",
                description: "Self-guided afternoon visiting five contemporary galleries with a shared checklist and closing wine reception.",
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
                id: "evt-12",
                title: "Pickup Soccer at Pier 40",
                description: "Casual 7v7 games on the Hudson. Cleats recommended; teams reshuffled every two matches.",
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
                id: "evt-13",
                title: "Speakeasy Cocktail Class",
                description: "Learn three classic cocktails behind a hidden West Village bar. Includes tasting flight and recipe cards.",
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
                id: "evt-14",
                title: "Prospect Park Picnic Concert",
                description: "Free outdoor concert by the Brooklyn Philharmonic brass ensemble. Picnic blankets encouraged.",
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
                id: "evt-15",
                title: "Astoria Book Swap",
                description: "Bring up to five books to trade. Local authors read short excerpts at 5 PM.",
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
                id: "evt-16",
                title: "Improv Jam: UCB East",
                description: "Open jam for improvisers of all levels. Warm-ups at 7:30; scenes start at 8.",
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
                id: "evt-17",
                title: "Times Square Silent Disco",
                description: "Wireless headphones, three DJ channels, and neon lights. Dance under the billboards without the noise complaints.",
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
                id: "evt-18",
                title: "Queens Night Market Preview",
                description: "Early-season tasting night with 20 vendors from Flushing to Jackson Heights. Live folk sets on the main stage.",
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
