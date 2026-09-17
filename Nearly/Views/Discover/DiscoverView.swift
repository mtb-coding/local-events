import SwiftUI

struct DiscoverView: View {
    @Environment(LocationManager.self) private var locationManager
    @Environment(DiscoverViewModel.self) private var viewModel
    @Environment(SavedStore.self) private var savedStore

    var body: some View {
        @Bindable var viewModel = viewModel

        NavigationStack {
            Group {
                switch viewModel.contentState {
                case .loading:
                    ProgressView("Finding events…")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                case .error(let message):
                    ContentUnavailableView {
                        Label("Something went wrong", systemImage: "exclamationmark.triangle")
                    } description: {
                        Text(message)
                    } actions: {
                        Button("Try Again") {
                            Task { await reloadEvents() }
                        }
                        .buttonStyle(.borderedProminent)
                    }
                case .emptyFeed:
                    ContentUnavailableView(
                        "No events nearby",
                        systemImage: "mappin.and.ellipse",
                        description: Text("Nothing in this radius yet. Try a larger radius or another category.")
                    )
                case .emptyFilter:
                    ContentUnavailableView(
                        "No events match",
                        systemImage: "magnifyingglass",
                        description: Text(viewModel.emptyFilterMessage)
                    )
                case .results:
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
                VStack(spacing: 0) {
                    if viewModel.showingLocationDeniedBanner {
                        locationBanner
                    }
                    radiusPicker(selection: $viewModel.radiusMiles)
                }
            }
            .refreshable {
                await reloadEvents()
            }
            .onChange(of: viewModel.radiusMiles) { _, _ in
                Task { await reloadEvents() }
            }
            .onChange(of: viewModel.selectedCategory) { _, _ in
                Task { await reloadEvents() }
            }
        }
    }

    private func radiusPicker(selection: Binding<Int>) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Radius")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
            Picker("Radius", selection: selection) {
                ForEach(DiscoverViewModel.radiusMilesOptions, id: \.self) { miles in
                    Text("\(miles) mi").tag(miles)
                }
            }
            .pickerStyle(.segmented)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(.bar)
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

    private func reloadEvents() async {
        await viewModel.loadEvents(
            near: locationManager.coordinateForSearch,
            usingDefaultLocation: locationManager.usingDefaultLocation
        )
    }
}
