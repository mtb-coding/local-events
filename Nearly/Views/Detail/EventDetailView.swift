import SwiftUI
import MapKit

struct EventDetailView: View {
    let event: Event

    @Environment(SavedStore.self) private var savedStore
    @Environment(LocationManager.self) private var locationManager

    @State private var cameraPosition: MapCameraPosition

    private static let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateStyle = .full
        f.timeStyle = .short
        return f
    }()

    init(event: Event) {
        self.event = event
        _cameraPosition = State(
            initialValue: .region(
                MKCoordinateRegion(
                    center: event.coordinate,
                    span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
                )
            )
        )
    }

    private var isSaved: Bool {
        savedStore.isSaved(event.id)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                header
                whenWhere
                mapSection
                descriptionSection
            }
            .padding()
        }
        .navigationTitle(event.title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    savedStore.toggle(event)
                } label: {
                    Label(
                        isSaved ? "Unsave" : "Save",
                        systemImage: isSaved ? "bookmark.fill" : "bookmark"
                    )
                }
            }
        }
        .safeAreaInset(edge: .bottom) {
            Button {
                savedStore.toggle(event)
            } label: {
                Label(
                    isSaved ? "Remove from Saved" : "Save Event",
                    systemImage: isSaved ? "bookmark.slash" : "bookmark.fill"
                )
                .font(.headline)
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .padding()
            .background(.bar)
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                CategoryChipView(category: event.category)
                Spacer()
                Text(
                    event.formattedDistance(
                        from: locationManager.isAuthorized ? locationManager.currentLocation : nil
                    )
                )
                .font(.subheadline)
                .foregroundStyle(.secondary)
            }

            Text(event.title)
                .font(.title.bold())

            Label(event.venueName, systemImage: "building.2")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }

    private var whenWhere: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label(Self.dateFormatter.string(from: event.startDate), systemImage: "calendar")
            Label("\(event.neighborhood) · \(event.address)", systemImage: "mappin.and.ellipse")
        }
        .font(.subheadline)
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color.secondary.opacity(0.08), in: RoundedRectangle(cornerRadius: 12))
    }

    private var mapSection: some View {
        Map(position: $cameraPosition) {
            Marker(event.venueName, coordinate: event.coordinate)
                .tint(.accentColor)
        }
        .frame(height: 220)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .mapStyle(.standard(elevation: .realistic))
    }

    private var descriptionSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("About")
                .font(.headline)
            Text(event.description)
                .font(.body)
                .foregroundStyle(.secondary)
        }
    }
}
