import AppIntents
import SwiftData
import WidgetKit
import Foundation

struct IncrementTrackerIntent: AppIntent {
    static var title: LocalizedStringResource = "Increment Tracker"
    static var description: IntentDescription = "Add one to a count tracker."

    @Parameter(title: "Tracker ID")
    var trackerID: String

    init() {}

    init(trackerID: String) {
        self.trackerID = trackerID
    }

    func perform() async throws -> some IntentResult & ReturnsValue<Bool> {
        let context = SharedModelContainer.newContext()
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
        try? context.save()

        WidgetCenter.shared.reloadAllTimelines()

        return .result(value: true)
    }
}
