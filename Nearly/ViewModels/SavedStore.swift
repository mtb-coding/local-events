import Foundation
import SwiftData
import Observation

@Observable
@MainActor
final class SavedStore {
    private var modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    func updateContext(_ context: ModelContext) {
        modelContext = context
    }

    func isSaved(_ eventID: String) -> Bool {
        savedRecord(for: eventID) != nil
    }

    func toggle(_ event: Event) {
        if let existing = savedRecord(for: event.id) {
            modelContext.delete(existing)
        } else {
            modelContext.insert(SavedEvent(from: event))
        }
        try? modelContext.save()
    }

    func save(_ event: Event) {
        guard savedRecord(for: event.id) == nil else { return }
        modelContext.insert(SavedEvent(from: event))
        try? modelContext.save()
    }

    func unsave(eventID: String) {
        if let existing = savedRecord(for: eventID) {
            modelContext.delete(existing)
            try? modelContext.save()
        }
    }

    func allSavedEvents() -> [Event] {
        let descriptor = FetchDescriptor<SavedEvent>(
            sortBy: [SortDescriptor(\.savedAt, order: .reverse)]
        )
        let records = (try? modelContext.fetch(descriptor)) ?? []
        return records.map(\.asEvent)
    }

    private func savedRecord(for eventID: String) -> SavedEvent? {
        var descriptor = FetchDescriptor<SavedEvent>(
            predicate: #Predicate { $0.eventId == eventID }
        )
        descriptor.fetchLimit = 1
        return try? modelContext.fetch(descriptor).first
    }
}
