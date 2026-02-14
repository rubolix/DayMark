import Foundation
import SwiftData

@Model
final class Profile {
    var name: String
    var emoji: String
    var colorHex: String
    var createdAt: Date

    @Relationship(deleteRule: .cascade, inverse: \Tracker.profile)
    var trackers: [Tracker] = []

    init(name: String, emoji: String = "👤", colorHex: String = "#6A4C93") {
        self.name = name
        self.emoji = emoji
        self.colorHex = colorHex
        self.createdAt = Date()
    }
}
