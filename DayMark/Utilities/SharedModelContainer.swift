import SwiftData
import Foundation
import Combine

struct SharedModelContainer {
    static let appGroupIdentifier = "group.com.rubolix.DayMark"
    static let darwinNotificationName = "com.rubolix.DayMark.storeDidChange"

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

    /// Post a Darwin notification to inform other processes that the store changed.
    static func notifyStoreChanged() {
        let center = CFNotificationCenterGetDarwinNotifyCenter()
        CFNotificationCenterPostNotification(center, CFNotificationName(darwinNotificationName as CFString), nil, nil, true)
    }
}

/// Observable object that views can use to force @Query re-evaluation.
/// Bump `refreshID` to make SwiftUI re-evaluate views that depend on it.
@MainActor
final class StoreRefreshCoordinator: ObservableObject {
    static let shared = StoreRefreshCoordinator()
    @Published var refreshID = UUID()

    private init() {
        startObservingDarwinNotification()
    }

    /// Force views to re-query by assigning a new ID
    func refresh() {
        SharedModelContainer.container.mainContext.rollback()
        refreshID = UUID()
    }

    private func startObservingDarwinNotification() {
        let center = CFNotificationCenterGetDarwinNotifyCenter()
        let observer = Unmanaged.passUnretained(self).toOpaque()
        CFNotificationCenterAddObserver(
            center,
            observer,
            { _, observer, _, _, _ in
                guard let observer else { return }
                let coordinator = Unmanaged<StoreRefreshCoordinator>.fromOpaque(observer).takeUnretainedValue()
                Task { @MainActor in
                    coordinator.refresh()
                }
            },
            SharedModelContainer.darwinNotificationName as CFString,
            nil,
            .deliverImmediately
        )
    }
}
