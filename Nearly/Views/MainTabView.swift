import SwiftUI
import CoreLocation

struct MainTabView: View {
    @Environment(LocationManager.self) private var locationManager
    @Environment(DiscoverViewModel.self) private var discoverViewModel
    @Environment(SavedStore.self) private var savedStore

    /// Last coordinate used to load Discover; jitter below 300 m is ignored.
    @State private var lastLoadedCoordinate: CLLocationCoordinate2D?

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
        .onChange(of: locationManager.currentLocation) { _, newLocation in
            guard let newLocation, shouldReload(for: newLocation) else { return }
            lastLoadedCoordinate = newLocation.coordinate
            Task { await reloadDiscover() }
        }
        .onChange(of: locationManager.authorizationStatus) { _, _ in
            locationManager.startUpdatingIfAuthorized()
            Task { await reloadDiscover() }
        }
        .onChange(of: locationManager.locationFixFailed) { _, failed in
            guard failed else { return }
            Task { await reloadDiscover() }
        }
    }

    private func shouldReload(for location: CLLocation) -> Bool {
        guard let last = lastLoadedCoordinate else { return true }
        let previous = CLLocation(latitude: last.latitude, longitude: last.longitude)
        return location.distance(from: previous) >= LocationManager.significantMoveMeters
    }

    private func reloadDiscover() async {
        await discoverViewModel.loadEvents(
            near: locationManager.coordinateForSearch,
            usingDefaultLocation: locationManager.usingDefaultLocation,
            authorizationStatus: locationManager.authorizationStatus,
            locationFixFailed: locationManager.locationFixFailed
        )
    }
}
