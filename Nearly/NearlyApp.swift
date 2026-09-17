import SwiftUI
import SwiftData

@main
struct NearlyApp: App {
    @State private var locationManager = LocationManager()
    @State private var discoverViewModel = DiscoverViewModel()

    var body: some Scene {
        WindowGroup {
            SavedStoreBootstrap {
                ContentView()
                    .environment(locationManager)
                    .environment(discoverViewModel)
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
