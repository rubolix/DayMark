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
                // Re-fetch data that may have been changed by the widget
                try? SharedModelContainer.container.mainContext.save()
            }
        }
    }
}
