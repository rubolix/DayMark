import Foundation
import SwiftData

enum TrackerType: String, Codable, CaseIterable {
    case scale = "Scale"
    case yesNo = "Yes / No"
    case count = "Count"
}

enum ReminderCadence: String, Codable, CaseIterable {
    case none = "None"
    case daily = "Daily"
    case weekdays = "Weekdays"
    case weekends = "Weekends"
    case weekly = "Weekly"
    case custom = "Custom"
}

@Model
final class Tracker {
    var name: String
    var type: TrackerType
    var scaleMin: Int
    var scaleMax: Int
    var unit: String
    var colorHex: String
    var createdAt: Date
    var isArchived: Bool
    var presetNotes: [String]
    var reminderCadence: ReminderCadence
    var reminderHour: Int
    var reminderMinute: Int
    var reminderWeekday: Int
    var reminderCustomDays: [Int]
    var profile: Profile?

    @Relationship(deleteRule: .cascade, inverse: \Entry.tracker)
    var entries: [Entry] = []

    init(name: String, type: TrackerType, scaleMin: Int = 1, scaleMax: Int = 5, unit: String = "", colorHex: String = "#1982C4", presetNotes: [String] = []) {
        self.name = name
        self.type = type
        self.scaleMin = scaleMin
        self.scaleMax = scaleMax
        self.unit = unit
        self.colorHex = colorHex
        self.createdAt = Date()
        self.isArchived = false
        self.presetNotes = presetNotes
        self.reminderCadence = .none
        self.reminderHour = 20
        self.reminderMinute = 0
        self.reminderWeekday = 2
        self.reminderCustomDays = []
    }

    var reminderTime: Date {
        var components = DateComponents()
        components.hour = reminderHour
        components.minute = reminderMinute
        return Calendar.current.date(from: components) ?? Date()
    }

    var sortedEntries: [Entry] {
        entries.sorted { $0.date > $1.date }
    }

    var latestEntry: Entry? {
        sortedEntries.first
    }
}
