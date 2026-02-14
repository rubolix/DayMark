import SwiftUI
import SwiftData

@main
struct DayMarkApp: App {
    @Environment(\.scenePhase) private var scenePhase
    @StateObject private var refreshCoordinator = StoreRefreshCoordinator.shared

    var body: some Scene {
        WindowGroup {
            DashboardView()
                .id(refreshCoordinator.refreshID)
        }
        .modelContainer(SharedModelContainer.container)
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .active {
                refreshCoordinator.refresh()
            }
        }
    }
}
