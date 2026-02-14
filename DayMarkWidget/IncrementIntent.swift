import AppIntents
import SwiftData
import WidgetKit
import Foundation

struct IncrementTrackerIntent: AppIntent {
    static var title: LocalizedStringResource = "Increment Tracker"
    static var description: IntentDescription = "Add one to a count tracker."
    static var openAppWhenRun: Bool = false

    @Parameter(title: "Tracker ID")
    var trackerID: String

    init() {}

    init(trackerID: String) {
        self.trackerID = trackerID
    }

    @MainActor
    func perform() async throws -> some IntentResult & ReturnsValue<Bool> {
        let container = SharedModelContainer.container
        let context = ModelContext(container)
        let descriptor = FetchDescriptor<Tracker>()
        let trackers = (try? context.fetch(descriptor)) ?? []

        guard let tracker = trackers.first(where: {
            $0.id.uuidString == trackerID
        }) else {
            return .result(value: false)
        }

        let entry = Entry(date: .now, value: 1)
        entry.tracker = tracker
        context.insert(entry)
        do {
            try context.save()
        } catch {
            return .result(value: false)
        }

        WidgetCenter.shared.reloadAllTimelines()
        SharedModelContainer.notifyStoreChanged()

        return .result(value: true)
    }
}
