import SwiftUI
import SwiftData

@main
struct NearlyApp: App {
    @State private var locationManager = LocationManager()
    @State private var eventService: any EventService
    @State private var discoverViewModel: DiscoverViewModel

    init() {
        let service = EventServiceFactory.makeDefault()
        _eventService = State(initialValue: service)
        _discoverViewModel = State(initialValue: DiscoverViewModel(eventService: service))
    }

    var body: some Scene {
        WindowGroup {
            SavedStoreBootstrap {
                ContentView()
                    .environment(locationManager)
                    .environment(discoverViewModel)
                    .environment(\.eventService, eventService)
            }
        }
        .modelContainer(for: SavedEvent.self)
    }
}

/// Creates SavedStore from the SwiftData modelContext and injects it into the environment.
private struct SavedStoreBootstrap<Content: View>: View {
    @Environment(\.modelContext) private var modelContext
    @State private var savedStore: SavedStore?
    @ViewBuilder var content: () -> Content

    var body: some View {
        Group {
            if let savedStore {
                content()
                    .environment(savedStore)
            } else {
                ProgressView("Loading…")
                    .task {
                        savedStore = SavedStore(modelContext: modelContext)
                    }
            }
        }
    }
}
