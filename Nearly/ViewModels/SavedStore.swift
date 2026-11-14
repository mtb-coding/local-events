import Foundation
import SwiftData
import Observation

@Observable
@MainActor
final class SavedStore {
    private var modelContext: ModelContext

    /// Observable set so Save buttons and row bookmarks flip immediately.
    private(set) var savedIDs: Set<String> = []

    /// Surfaced to UI when a SwiftData save fails.
    var lastErrorMessage: String?

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
        refreshSavedIDs()
    }

    func updateContext(_ context: ModelContext) {
        modelContext = context
        refreshSavedIDs()
    }

    func isSaved(_ eventID: String) -> Bool {
        savedIDs.contains(eventID)
    }

    /// Hydrate a domain `Event` from a saved snapshot (offline detail fallback).
    func event(id: String) -> Event? {
        savedRecord(for: id)?.asEvent
    }

    func toggle(_ event: Event) {
        if let existing = savedRecord(for: event.id) {
            modelContext.delete(existing)
            savedIDs.remove(event.id)
        } else {
            modelContext.insert(SavedEvent(from: event))
            savedIDs.insert(event.id)
        }
        persist()
    }

    func save(_ event: Event) {
        guard !savedIDs.contains(event.id) else { return }
        modelContext.insert(SavedEvent(from: event))
        savedIDs.insert(event.id)
        persist()
    }

    func unsave(eventID: String) {
        if let existing = savedRecord(for: eventID) {
            modelContext.delete(existing)
            savedIDs.remove(eventID)
            persist()
        }
    }

    func allSavedEvents() -> [Event] {
        let descriptor = FetchDescriptor<SavedEvent>(
            sortBy: [SortDescriptor(\.savedAt, order: .reverse)]
        )
        let records = (try? modelContext.fetch(descriptor)) ?? []
        return records.map(\.asEvent)
    }

    private func persist() {
        do {
            try modelContext.save()
            lastErrorMessage = nil
        } catch {
            lastErrorMessage = "Couldn't update saved events. Please try again."
            // Revert the in-memory set to whatever SwiftData still holds.
            refreshSavedIDs()
        }
    }

    private func refreshSavedIDs() {
        let descriptor = FetchDescriptor<SavedEvent>()
        let records = (try? modelContext.fetch(descriptor)) ?? []
        savedIDs = Set(records.map(\.eventId))
    }

    private func savedRecord(for eventID: String) -> SavedEvent? {
        var descriptor = FetchDescriptor<SavedEvent>(
            predicate: #Predicate { $0.eventId == eventID }
        )
        descriptor.fetchLimit = 1
        return try? modelContext.fetch(descriptor).first
    }
}
