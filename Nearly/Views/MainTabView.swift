import SwiftUI

struct MainTabView: View {
    @Environment(LocationManager.self) private var locationManager
    @Environment(DiscoverViewModel.self) private var discoverViewModel
    @Environment(SavedStore.self) private var savedStore

    /// Combined lat/lon identity so longitude-only moves also reload Discover.
    private var coordinateIdentity: String {
        guard let coordinate = locationManager.currentLocation?.coordinate else {
            return "nil"
        }
        return "\(coordinate.latitude),\(coordinate.longitude)"
    }

    var body: some View {
        TabView {
            DiscoverView()
                .tabItem {
                    Label("Discover", systemImage: "sparkle.magnifyingglass")
                }

            SavedView()
                .tabItem {
                    Label("Saved", systemImage: "bookmark.fill")
                }
        }
        .task {
            locationManager.refreshAuthorization()
            await reloadDiscover()
        }
        .onChange(of: coordinateIdentity) { _, _ in
            Task { await reloadDiscover() }
        }
        .onChange(of: locationManager.authorizationStatus) { _, _ in
            locationManager.startUpdatingIfAuthorized()
            Task { await reloadDiscover() }
        }
    }

    private func reloadDiscover() async {
        await discoverViewModel.loadEvents(
            near: locationManager.coordinateForSearch,
            usingDefaultLocation: locationManager.usingDefaultLocation,
            authorizationStatus: locationManager.authorizationStatus
        )
    }
}
