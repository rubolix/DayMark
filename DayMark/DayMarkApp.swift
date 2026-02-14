import SwiftUI
import SwiftData

@main
struct DayMarkApp: App {
    var body: some Scene {
        WindowGroup {
            DashboardView()
        }
        .modelContainer(for: [Subject.self, Tracker.self, Entry.self])
    }
}
