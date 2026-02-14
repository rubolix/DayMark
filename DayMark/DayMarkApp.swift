import SwiftUI
import SwiftData

@main
struct DayMarkApp: App {
    var body: some Scene {
        WindowGroup {
            DashboardView()
        }
        .modelContainer(SharedModelContainer.container)
    }
}
