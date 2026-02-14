import SwiftUI
import SwiftData

@main
struct DayMarkApp: App {
    @Environment(\.scenePhase) private var scenePhase

    var body: some Scene {
        WindowGroup {
            DashboardView()
        }
        .modelContainer(SharedModelContainer.container)
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .active {
                // Pick up any changes made by the widget extension
                SharedModelContainer.container.mainContext.autosaveEnabled = true
            }
        }
    }
}
