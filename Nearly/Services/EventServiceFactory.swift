import Foundation

enum EventServiceFactory {
    /// Info.plist key for an optional Ticketmaster API key.
    /// Leave empty or unset to use `MockEventService` (default).
    static let ticketmasterAPIKeyInfoPlistKey = "TicketmasterAPIKey"

    /// Prefer Ticketmaster when a real key is present; otherwise Mock.
    /// Never commit real secrets — inject via xcconfig / scheme env / local plist override.
    static func makeDefault(bundle: Bundle = .main) -> any EventService {
        if let key = resolvedTicketmasterAPIKey(bundle: bundle) {
            return TicketmasterEventService(apiKey: key)
        }
        return MockEventService()
    }

    static func resolvedTicketmasterAPIKey(bundle: Bundle = .main) -> String? {
        guard let raw = bundle.object(forInfoDictionaryKey: ticketmasterAPIKeyInfoPlistKey) as? String else {
            return nil
        }
        let key = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        if key.isEmpty { return nil }
        // Unexpanded build setting placeholder
        if key.hasPrefix("$(") { return nil }
        if key == "YOUR_API_KEY_HERE" { return nil }
        return key
    }
}
