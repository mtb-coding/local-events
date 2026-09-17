import SwiftUI

struct MainTabView: View {
    @Environment(LocationManager.self) private var locationManager
    @Environment(DiscoverViewModel.self) private var discoverViewModel
    @Environment(SavedStore.self) private var savedStore

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
            await discoverViewModel.loadEvents(
                near: locationManager.coordinateForSearch,
                usingDefaultLocation: locationManager.usingDefaultLocation
            )
        }
        .onChange(of: locationManager.currentLocation?.coordinate.latitude) { _, _ in
            Task {
                await discoverViewModel.loadEvents(
                    near: locationManager.coordinateForSearch,
                    usingDefaultLocation: locationManager.usingDefaultLocation
                )
            }
        }
        .onChange(of: locationManager.authorizationStatus) { _, _ in
            locationManager.startUpdatingIfAuthorized()
            Task {
                await discoverViewModel.loadEvents(
                    near: locationManager.coordinateForSearch,
                    usingDefaultLocation: locationManager.usingDefaultLocation
                )
            }
        }
    }
}
