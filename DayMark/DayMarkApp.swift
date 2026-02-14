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
                // Reset the main context to pick up changes written by the widget extension
                SharedModelContainer.container.mainContext.rollback()
            }
        }
    }
}
