import SwiftUI
import SwiftData

struct SavedView: View {
    @Environment(SavedStore.self) private var savedStore
    @Environment(LocationManager.self) private var locationManager
    @Query(sort: \SavedEvent.savedAt, order: .reverse) private var savedRecords: [SavedEvent]

    var body: some View {
        NavigationStack {
            Group {
                if savedRecords.isEmpty {
                    ContentUnavailableView(
                        "No saved events",
                        systemImage: "bookmark",
                        description: Text("Bookmark events from Discover to see them here.")
                    )
                } else {
                    List(savedRecords, id: \.eventId) { record in
                        let event = record.asEvent
                        NavigationLink(value: event) {
                            EventRowView(
                                event: event,
                                userLocation: locationManager.isAuthorized ? locationManager.currentLocation : nil,
                                isSaved: true
                            )
                        }
                        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                            Button(role: .destructive) {
                                savedStore.unsave(eventID: event.id)
                            } label: {
                                Label("Unsave", systemImage: "bookmark.slash")
                            }
                        }
                    }
                    .listStyle(.plain)
                }
            }
            .navigationTitle("Saved")
            .navigationDestination(for: Event.self) { event in
                EventDetailView(event: event)
            }
        }
    }
}
