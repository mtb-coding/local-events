import SwiftUI

struct DiscoverView: View {
    @Environment(LocationManager.self) private var locationManager
    @Environment(DiscoverViewModel.self) private var viewModel
    @Environment(SavedStore.self) private var savedStore

    var body: some View {
        @Bindable var viewModel = viewModel

        NavigationStack {
            Group {
                if viewModel.isLoading && viewModel.events.isEmpty {
                    ProgressView("Finding events…")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if let error = viewModel.errorMessage, viewModel.events.isEmpty {
                    ContentUnavailableView(
                        "Something went wrong",
                        systemImage: "exclamationmark.triangle",
                        description: Text(error)
                    )
                } else if viewModel.filteredEvents.isEmpty {
                    ContentUnavailableView(
                        "No events match",
                        systemImage: "magnifyingglass",
                        description: Text("Try another category or clear your search.")
                    )
                } else {
                    List(viewModel.filteredEvents) { event in
                        NavigationLink(value: event) {
                            EventRowView(
                                event: event,
                                userLocation: locationManager.isAuthorized ? locationManager.currentLocation : nil,
                                isSaved: savedStore.isSaved(event.id)
                            )
                        }
                    }
                    .listStyle(.plain)
                }
            }
            .navigationTitle("Discover")
            .navigationDestination(for: Event.self) { event in
                EventDetailView(event: event)
            }
            .searchable(text: $viewModel.searchText, prompt: "Search events, venues…")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        Button("All categories") {
                            viewModel.selectedCategory = nil
                        }
                        ForEach(EventCategory.allCases) { category in
                            Button {
                                viewModel.selectedCategory = category
                            } label: {
                                Label(category.rawValue, systemImage: category.systemImage)
                            }
                        }
                    } label: {
                        Label(
                            viewModel.selectedCategory?.rawValue ?? "Filter",
                            systemImage: "line.3.horizontal.decrease.circle"
                        )
                    }
                }
            }
            .safeAreaInset(edge: .top) {
                if viewModel.showingLocationDeniedBanner {
                    locationBanner
                }
            }
            .refreshable {
                await viewModel.loadEvents(
                    near: locationManager.coordinateForSearch,
                    usingDefaultLocation: locationManager.usingDefaultLocation
                )
            }
        }
    }

    private var locationBanner: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "location.slash")
                .foregroundStyle(.orange)
            VStack(alignment: .leading, spacing: 2) {
                Text("Showing NYC defaults")
                    .font(.subheadline.weight(.semibold))
                Text("Distances need location access. Enable Location in Settings for nearby sorting.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer(minLength: 0)
            if locationManager.authorizationStatus == .notDetermined {
                Button("Enable") {
                    locationManager.requestPermission()
                }
                .font(.caption.weight(.semibold))
            }
        }
        .padding(12)
        .background(.orange.opacity(0.12))
    }
}
