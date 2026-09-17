import Foundation

/// Provider tag for events. Prefixed IDs use `"\(source.rawValue):\(rawID)"`.
enum EventSource: String, Codable, Sendable, Hashable, CaseIterable {
    case mock
    case ticketmaster
    case unknown

    /// Build a collision-safe id, e.g. `mock:evt-01`, `ticketmaster:G5…`.
    func prefixedID(_ rawID: String) -> String {
        "\(rawValue):\(rawID)"
    }

    /// Split a prefixed id into source + raw. Falls back to `.unknown` if no colon.
    static func split(_ id: String) -> (source: EventSource, rawID: String) {
        guard let idx = id.firstIndex(of: ":") else {
            return (.unknown, id)
        }
        let prefix = String(id[..<idx])
        let raw = String(id[id.index(after: idx)...])
        return (EventSource(rawValue: prefix) ?? .unknown, raw)
    }
}
