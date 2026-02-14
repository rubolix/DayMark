import AppIntents
import SwiftData
import Foundation

struct TrackerEntity: AppEntity {
    var id: String
    var name: String
    var profileName: String

    static var typeDisplayRepresentation: TypeDisplayRepresentation = "Tracker"

    var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(title: "\(name)", subtitle: "\(profileName)")
    }

    static var defaultQuery = TrackerEntityQuery()
}

struct TrackerEntityQuery: EntityQuery {
    func entities(for identifiers: [String]) async throws -> [TrackerEntity] {
        let context = ModelContext(SharedModelContainer.container)
        let descriptor = FetchDescriptor<Tracker>()
        let trackers = (try? context.fetch(descriptor)) ?? []
        return trackers
            .filter { identifiers.contains($0.persistentModelID.hashValue.description) }
            .map { tracker in
                TrackerEntity(
                    id: tracker.persistentModelID.hashValue.description,
                    name: tracker.name,
                    profileName: tracker.profile?.name ?? "Unknown"
                )
            }
    }

    func suggestedEntities() async throws -> [TrackerEntity] {
        let context = ModelContext(SharedModelContainer.container)
        let descriptor = FetchDescriptor<Tracker>()
        let trackers = (try? context.fetch(descriptor)) ?? []
        return trackers
            .filter { !$0.isArchived && $0.type == .count }
            .map { tracker in
                TrackerEntity(
                    id: tracker.persistentModelID.hashValue.description,
                    name: tracker.name,
                    profileName: tracker.profile?.name ?? "Unknown"
                )
            }
    }
}

struct SelectTrackerIntent: WidgetConfigurationIntent {
    static var title: LocalizedStringResource = "Select Tracker"
    static var description: IntentDescription = "Choose a count tracker to display."

    @Parameter(title: "Tracker")
    var tracker: TrackerEntity?
}
