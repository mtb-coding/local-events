import Foundation
import CoreLocation

/// Ticketmaster Discovery API behind `EventService`.
/// Selected only when a real API key is present (`EventServiceFactory`); otherwise Mock.
struct TicketmasterEventService: EventService {
    let apiKey: String
    var session: URLSession = .shared
    var baseURL = URL(string: "https://app.ticketmaster.com/discovery/v2")!

    enum TicketmasterError: Error, LocalizedError {
        case missingAPIKey
        case invalidResponse
        case httpStatus(Int)

        var errorDescription: String? {
            switch self {
            case .missingAPIKey: return "Ticketmaster API key is missing."
            case .invalidResponse: return "Unexpected Ticketmaster response."
            case .httpStatus(let code): return "Ticketmaster HTTP \(code)."
            }
        }
    }

    func fetchNearbyEvents(_ query: EventQuery) async throws -> [Event] {
        guard !apiKey.isEmpty else { throw TicketmasterError.missingAPIKey }

        var components = URLComponents(
            url: baseURL.appendingPathComponent("events.json"),
            resolvingAgainstBaseURL: false
        )!
        var items: [URLQueryItem] = [
            URLQueryItem(name: "apikey", value: apiKey),
            URLQueryItem(
                name: "latlong",
                value: "\(query.coordinate.latitude),\(query.coordinate.longitude)"
            ),
            URLQueryItem(name: "radius", value: String(max(1, Int((query.radiusMeters / 1609.344).rounded())))),
            URLQueryItem(name: "unit", value: "miles"),
            URLQueryItem(name: "size", value: "50"),
        ]
        if let category = query.category {
            items.append(URLQueryItem(name: "classificationName", value: Self.classificationName(for: category)))
        }
        if let interval = query.dateInterval {
            items.append(URLQueryItem(name: "startDateTime", value: Self.iso8601.string(from: interval.start)))
            items.append(URLQueryItem(name: "endDateTime", value: Self.iso8601.string(from: interval.end)))
        }
        components.queryItems = items

        guard let url = components.url else { throw TicketmasterError.invalidResponse }
        let (data, response) = try await session.data(from: url)
        guard let http = response as? HTTPURLResponse else { throw TicketmasterError.invalidResponse }
        guard (200..<300).contains(http.statusCode) else {
            throw TicketmasterError.httpStatus(http.statusCode)
        }

        let decoded = try JSONDecoder().decode(TicketmasterEventsResponse.self, from: data)
        return (decoded.embedded?.events ?? []).compactMap(TicketmasterMapper.map)
    }

    func event(id: String) async throws -> Event? {
        guard !apiKey.isEmpty else { throw TicketmasterError.missingAPIKey }
        let (_, rawID) = EventSource.split(id)
        let pathID = rawID.isEmpty ? id : rawID

        var components = URLComponents(
            url: baseURL.appendingPathComponent("events/\(pathID).json"),
            resolvingAgainstBaseURL: false
        )!
        components.queryItems = [URLQueryItem(name: "apikey", value: apiKey)]
        guard let url = components.url else { throw TicketmasterError.invalidResponse }

        let (data, response) = try await session.data(from: url)
        guard let http = response as? HTTPURLResponse else { throw TicketmasterError.invalidResponse }
        if http.statusCode == 404 { return nil }
        guard (200..<300).contains(http.statusCode) else {
            throw TicketmasterError.httpStatus(http.statusCode)
        }

        let dto = try JSONDecoder().decode(TicketmasterEventDTO.self, from: data)
        return TicketmasterMapper.map(dto)
    }

    private static func classificationName(for category: EventCategory) -> String {
        switch category {
        case .music: return "Music"
        case .sports: return "Sports"
        case .arts: return "Arts & Theatre"
        case .nightlife, .comedy: return "Miscellaneous"
        case .food, .outdoors, .community: return "Miscellaneous"
        }
    }

    private static let iso8601: ISO8601DateFormatter = {
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime]
        return f
    }()
}

// MARK: - DTOs

struct TicketmasterEventsResponse: Decodable {
    let embedded: TicketmasterEmbedded?
    enum CodingKeys: String, CodingKey { case embedded = "_embedded" }
}

struct TicketmasterEmbedded: Decodable {
    let events: [TicketmasterEventDTO]?
}

struct TicketmasterEventDTO: Decodable {
    let id: String?
    let name: String?
    let type: String?
    let test: Bool?
    let info: String?
    let pleaseNote: String?
    let url: String?
    let dates: TicketmasterDates?
    let classifications: [TicketmasterClassification]?
    let images: [TicketmasterImage]?
    let embedded: TicketmasterEventEmbedded?
    enum CodingKeys: String, CodingKey {
        case id, name, type, test, info, pleaseNote, url, dates, classifications, images
        case embedded = "_embedded"
    }
}

struct TicketmasterDates: Decodable {
    let start: TicketmasterStart?
    let end: TicketmasterStart?
    let status: TicketmasterStatus?
}

struct TicketmasterStart: Decodable {
    let dateTime: String?
    let localDate: String?
    let localTime: String?
}

struct TicketmasterStatus: Decodable {
    let code: String?
}

struct TicketmasterClassification: Decodable {
    let segment: TicketmasterNamed?
    let genre: TicketmasterNamed?
    let primary: Bool?
}

struct TicketmasterNamed: Decodable { let name: String? }

struct TicketmasterState: Decodable {
    let name: String?
    let stateCode: String?
}

struct TicketmasterImage: Decodable {
    let url: String?
    let ratio: String?
    let width: Int?
    let height: Int?
    let fallback: Bool?
}

struct TicketmasterEventEmbedded: Decodable {
    let venues: [TicketmasterVenueDTO]?
}

struct TicketmasterVenueDTO: Decodable {
    let name: String?
    let city: TicketmasterNamed?
    let state: TicketmasterState?
    let address: TicketmasterAddress?
    let location: TicketmasterLocation?
}

struct TicketmasterAddress: Decodable { let line1: String? }

struct TicketmasterLocation: Decodable {
    let latitude: String?
    let longitude: String?
}

// MARK: - Mapper (Research field map)

enum TicketmasterMapper {
    static func map(_ dto: TicketmasterEventDTO) -> Event? {
        if dto.test == true { return nil }
        let status = dto.dates?.status?.code?.lowercased() ?? ""
        if status == "cancelled" || status == "canceled" { return nil }
        guard let rawID = dto.id, let title = dto.name else { return nil }

        let venue = dto.embedded?.venues?.first
        guard
            let latStr = venue?.location?.latitude,
            let lonStr = venue?.location?.longitude,
            let lat = Double(latStr),
            let lon = Double(lonStr),
            !(lat == 0 && lon == 0)
        else {
            return nil
        }

        let start = parseStartDate(dto.dates?.start) ?? .now
        let endDate = parseStartDate(dto.dates?.end)
        let imageURL = bestImageURL(dto.images)
        let category = mapCategory(from: dto.classifications)
        let description = buildDescription(info: dto.info, pleaseNote: dto.pleaseNote, url: dto.url)
        let neighborhood = venue?.city?.name ?? ""
        let addressLine = venue?.address?.line1
        let address = buildAddress(
            line1: addressLine,
            city: venue?.city?.name,
            stateCode: venue?.state?.stateCode,
            stateName: venue?.state?.name,
            neighborhood: neighborhood
        )
        let venueName = venue?.name ?? "Venue TBA"

        return Event(
            rawID: rawID,
            source: .ticketmaster,
            title: title,
            description: description,
            startDate: start,
            endDate: endDate,
            venueName: venueName,
            neighborhood: neighborhood,
            address: address,
            latitude: lat,
            longitude: lon,
            category: category,
            imageSystemName: category.systemImage,
            imageURL: imageURL
        )
    }

    private static func buildAddress(
        line1: String?,
        city: String?,
        stateCode: String?,
        stateName: String?,
        neighborhood: String
    ) -> String {
        var parts: [String] = []
        if let line1, !line1.isEmpty { parts.append(line1) }
        if let city, !city.isEmpty { parts.append(city) }
        if let stateCode, !stateCode.isEmpty {
            parts.append(stateCode)
        } else if let stateName, !stateName.isEmpty {
            parts.append(stateName)
        }
        if parts.isEmpty {
            return neighborhood.isEmpty ? "Address TBA" : neighborhood
        }
        return parts.joined(separator: ", ")
    }

    private static func bestImageURL(_ images: [TicketmasterImage]?) -> URL? {
        guard let images, !images.isEmpty else { return nil }
        let nonFallback = images.filter { $0.fallback != true }
        let pool = nonFallback.isEmpty ? images : nonFallback
        let ratio16x9 = pool.filter { $0.ratio == "16_9" }
        let ranked = (ratio16x9.isEmpty ? pool : ratio16x9)
            .sorted { ($0.width ?? 0) > ($1.width ?? 0) }
        return ranked.compactMap { $0.url.flatMap(URL.init(string:)) }.first
    }

    private static func mapCategory(from classifications: [TicketmasterClassification]?) -> EventCategory {
        let primary = classifications?.first(where: { $0.primary == true }) ?? classifications?.first
        let name = (primary?.segment?.name ?? primary?.genre?.name ?? "").lowercased()
        if name.contains("music") { return .music }
        if name.contains("sport") { return .sports }
        if name.contains("art") || name.contains("theatre") || name.contains("theater") { return .arts }
        if name.contains("film") { return .arts }
        return .community
    }

    private static func buildDescription(info: String?, pleaseNote: String?, url: String?) -> String {
        var parts: [String] = []
        if let info, !info.isEmpty { parts.append(info) }
        if let pleaseNote, !pleaseNote.isEmpty { parts.append(pleaseNote) }
        if let url, !url.isEmpty { parts.append(url) }
        return parts.isEmpty ? "Event from Ticketmaster." : parts.joined(separator: "\n\n")
    }

    private static func parseStartDate(_ start: TicketmasterStart?) -> Date? {
        guard let start else { return nil }
        if let dateTime = start.dateTime {
            let f = ISO8601DateFormatter()
            f.formatOptions = [.withInternetDateTime]
            if let d = f.date(from: dateTime) { return d }
            f.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            if let d = f.date(from: dateTime) { return d }
        }
        guard let localDate = start.localDate else { return nil }
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        if let localTime = start.localTime {
            formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
            if let d = formatter.date(from: "\(localDate)T\(localTime)") { return d }
        }
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.date(from: localDate)
    }
}
