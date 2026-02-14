import UserNotifications

struct NotificationManager {
    static func requestPermission() async -> Bool {
        do {
            return try await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound])
        } catch {
            return false
        }
    }

    static func scheduleReminders(for tracker: Tracker) {
        let center = UNUserNotificationCenter.current()
        let idPrefix = "daymark-\(tracker.persistentModelID.hashValue)"

        // Remove existing notifications for this tracker
        removeReminders(idPrefix: idPrefix)

        guard tracker.reminderCadence != .none && !tracker.isArchived else { return }

        let profileName = tracker.profile?.name ?? ""
        let content = UNMutableNotificationContent()
        content.title = "DayMark Reminder"
        content.body = "Time to log \(tracker.name)\(profileName.isEmpty ? "" : " for \(profileName)")"
        content.sound = .default

        let weekdays: [Int] // 1=Sun, 2=Mon, ..., 7=Sat
        switch tracker.reminderCadence {
        case .none:
            return
        case .daily:
            weekdays = [1, 2, 3, 4, 5, 6, 7]
        case .weekdays:
            weekdays = [2, 3, 4, 5, 6]
        case .weekends:
            weekdays = [1, 7]
        case .weekly:
            weekdays = [tracker.reminderWeekday]
        case .custom:
            weekdays = tracker.reminderCustomDays
        }

        for day in weekdays {
            var dateComponents = DateComponents()
            dateComponents.weekday = day
            dateComponents.hour = tracker.reminderHour
            dateComponents.minute = tracker.reminderMinute

            let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
            let request = UNNotificationRequest(
                identifier: "\(idPrefix)-\(day)",
                content: content,
                trigger: trigger
            )
            center.add(request)
        }
    }

    static func removeReminders(for tracker: Tracker) {
        let idPrefix = "daymark-\(tracker.persistentModelID.hashValue)"
        removeReminders(idPrefix: idPrefix)
    }

    private static func removeReminders(idPrefix: String) {
        let center = UNUserNotificationCenter.current()
        let ids = (1...7).map { "\(idPrefix)-\($0)" }
        center.removePendingNotificationRequests(withIdentifiers: ids)
    }
}
