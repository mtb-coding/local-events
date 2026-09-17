import SwiftUI

struct DiscoverView: View {
    @Environment(LocationManager.self) private var locationManager
    @Environment(DiscoverViewModel.self) private var viewModel
    @Environment(SavedStore.self) private var savedStore

    var body: some View {
        @Bindable var viewModel = viewModel

        NavigationStack {
            Group {
                switch viewModel.phase {
                case .loading:
                    loadingView
                case .populated:
                    populatedView
                case .empty(let radiusMiles):
                    emptyView(radiusMiles: radiusMiles)
                case .locationDenied:
                    locationDeniedView
                case .failed(let retryable):
                    failedView(retryable: retryable)
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
                    if viewModel.isSampleData, viewModel.phase == .populated {
                        sampleDataBadge
                    }
                    if viewModel.phase != .locationDenied {
                        radiusPicker(selection: $viewModel.radiusMiles)
                    }
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

    // MARK: - Phase views

    private var loadingView: some View {
        ProgressView("Finding events…")
            .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    @ViewBuilder
    private var populatedView: some View {
        if viewModel.filteredEvents.isEmpty {
            ContentUnavailableView(
                "No events match",
                systemImage: "magnifyingglass",
                description: Text(viewModel.emptyFilterMessage)
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
            .overlay(alignment: .top) {
                if viewModel.isRefreshing {
                    ProgressView()
                        .padding(8)
                        .background(.ultraThinMaterial, in: Capsule())
                        .padding(.top, 8)
                }
            }
        }
    }

    private func emptyView(radiusMiles: Int) -> some View {
        ContentUnavailableView {
            Label("Nothing within \(radiusMiles) mi", systemImage: "mappin.and.ellipse")
        } description: {
            Text("Try widening the radius or picking another category.")
        } actions: {
            if let next = nextWiderRadius(from: radiusMiles) {
                Button("Widen to \(next) mi") {
                    viewModel.radiusMiles = next
                }
                .buttonStyle(.borderedProminent)
            }
        }
    }

    private var locationDeniedView: some View {
        ContentUnavailableView {
            Label("Location needed", systemImage: "location.slash")
        } description: {
            Text("Turn on Location to discover events near you. We don’t treat this as an empty city.")
        } actions: {
            if locationManager.authorizationStatus == .notDetermined {
                Button("Enable Location") {
                    locationManager.requestPermission()
                }
                .buttonStyle(.borderedProminent)
            } else {
                Button("Open Settings") {
                    openSystemSettings()
                }
                .buttonStyle(.borderedProminent)
            }
        }
    }

    private func failedView(retryable: Bool) -> some View {
        ContentUnavailableView {
            Label("Couldn't load events", systemImage: "exclamationmark.triangle")
        } description: {
            Text(
                retryable
                    ? "Something went wrong talking to the events service. This doesn’t mean your area is empty."
                    : "Something went wrong talking to the events service."
            )
        } actions: {
            if retryable {
                Button("Try Again") {
                    Task { await reloadEvents() }
                }
                .buttonStyle(.borderedProminent)
            }
        }
    }

    private var sampleDataBadge: some View {
        HStack(spacing: 6) {
            Image(systemName: "sparkles")
            Text("Sample events")
                .font(.caption.weight(.semibold))
            Spacer(minLength: 0)
        }
        .foregroundStyle(.secondary)
        .padding(.horizontal, 16)
        .padding(.vertical, 6)
        .background(Color(.secondarySystemBackground))
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

    private func nextWiderRadius(from miles: Int) -> Int? {
        DiscoverViewModel.radiusMilesOptions.first { $0 > miles }
    }

    private func openSystemSettings() {
        guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
        UIApplication.shared.open(url)
    }

    private func reloadEvents() async {
        await viewModel.loadEvents(
            near: locationManager.coordinateForSearch,
            usingDefaultLocation: locationManager.usingDefaultLocation
        )
    }
}
