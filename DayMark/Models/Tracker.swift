import Foundation
import SwiftData

enum TrackerType: String, Codable, CaseIterable {
    case scale = "Scale"
    case yesNo = "Yes / No"
    case count = "Count"
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
    var subject: Subject?

    @Relationship(deleteRule: .cascade, inverse: \Entry.tracker)
    var entries: [Entry] = []

    init(name: String, type: TrackerType, scaleMin: Int = 1, scaleMax: Int = 5, unit: String = "", colorHex: String = "#1982C4") {
        self.name = name
        self.type = type
        self.scaleMin = scaleMin
        self.scaleMax = scaleMax
        self.unit = unit
        self.colorHex = colorHex
        self.createdAt = Date()
        self.isArchived = false
    }

    var sortedEntries: [Entry] {
        entries.sorted { $0.date > $1.date }
    }

    var latestEntry: Entry? {
        sortedEntries.first
    }
}
