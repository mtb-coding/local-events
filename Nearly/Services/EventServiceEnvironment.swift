import SwiftUI

private struct EventServiceKey: EnvironmentKey {
    static let defaultValue: any EventService = MockEventService()
}

extension EnvironmentValues {
    var eventService: any EventService {
        get { self[EventServiceKey.self] }
        set { self[EventServiceKey.self] = newValue }
    }
}
