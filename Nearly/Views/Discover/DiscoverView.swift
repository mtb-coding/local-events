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
                    if viewModel.isSampleData,
                       viewModel.phase == .populated || viewModel.phase == .loading {
                        sampleEventsChip
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

    // MARK: - Phase views (Designer 1:1)

    /// First load: skeleton rows matching card geometry. Never used on reload with data.
    private var loadingView: some View {
        List {
            ForEach(0..<4, id: \.self) { _ in
                skeletonRow
            }
        }
        .listStyle(.plain)
        .disabled(true)
        .redacted(reason: .placeholder)
    }

    private var skeletonRow: some View {
        HStack(alignment: .top, spacing: 14) {
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.secondary.opacity(0.18))
                .frame(width: 44, height: 44)

            VStack(alignment: .leading, spacing: 8) {
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.secondary.opacity(0.18))
                    .frame(height: 16)
                    .frame(maxWidth: 220)
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.secondary.opacity(0.14))
                    .frame(height: 12)
                    .frame(maxWidth: 140)
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.secondary.opacity(0.14))
                    .frame(height: 12)
                    .frame(maxWidth: 180)
                HStack(spacing: 8) {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.secondary.opacity(0.14))
                        .frame(width: 64, height: 22)
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.secondary.opacity(0.14))
                        .frame(width: 52, height: 22)
                }
            }
        }
        .padding(.vertical, 4)
        .accessibilityLabel("Loading event")
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
                        .controlSize(.small)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(.ultraThinMaterial, in: Capsule())
                        .padding(.top, 8)
                }
            }
        }
    }

    private func emptyView(radiusMiles: Int) -> some View {
        ContentUnavailableView {
            Label("Nothing within \(radiusMiles) mi.", systemImage: "mappin.and.ellipse")
        } description: {
            Text("Widen your search to see more nearby.")
        } actions: {
            Button("Widen radius") {
                viewModel.widenRadius()
            }
            .buttonStyle(.borderedProminent)
            .disabled(viewModel.nextWiderRadiusMiles == nil)
        }
    }

    /// Full-screen; primary action is Open Settings only.
    private var locationDeniedView: some View {
        ContentUnavailableView {
            Label("Location needed.", systemImage: "location.slash")
        } description: {
            Text("Turn on location so we can show what’s near you.")
        } actions: {
            Button("Open Settings.") {
                openSystemSettings()
            }
            .buttonStyle(.borderedProminent)
        }
    }

    private func failedView(retryable: Bool) -> some View {
        ContentUnavailableView {
            Label("Couldn't load events.", systemImage: "exclamationmark.triangle")
        } description: {
            Text("Something went wrong. Try again.")
        } actions: {
            if retryable {
                Button("Retry") {
                    Task { await reloadEvents() }
                }
                .buttonStyle(.borderedProminent)
            }
        }
    }

    private var sampleEventsChip: some View {
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
        .accessibilityLabel("Sample events")
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
