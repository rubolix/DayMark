import SwiftData
import Foundation

struct SharedModelContainer {
    static let appGroupIdentifier = "group.com.rubolix.DayMark"

    @MainActor
    static var container: ModelContainer = {
        let schema = Schema([Profile.self, Tracker.self, Entry.self])
        let config: ModelConfiguration
        if let groupURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: appGroupIdentifier) {
            let storeURL = groupURL.appendingPathComponent("DayMark.store")
            config = ModelConfiguration("DayMark", schema: schema, url: storeURL)
        } else {
            config = ModelConfiguration(schema: schema)
        }
        do {
            return try ModelContainer(for: schema, configurations: [config])
        } catch {
            fatalError("Failed to create ModelContainer: \(error)")
        }
    }()
}
