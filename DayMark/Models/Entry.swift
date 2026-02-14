import Foundation
import SwiftData

@Model
final class Entry {
    var date: Date
    var value: Double
    var note: String
    var tracker: Tracker?

    init(date: Date = .now, value: Double, note: String = "") {
        self.date = date
        self.value = value
        self.note = note
    }
}
