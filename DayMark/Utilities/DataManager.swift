import Foundation
import SwiftData

struct DayMarkBackup: Codable {
    let version: Int
    let exportDate: Date
    let subjects: [SubjectData]

    struct SubjectData: Codable {
        let name: String
        let emoji: String
        let colorHex: String
        let trackers: [TrackerData]
    }

    struct TrackerData: Codable {
        let name: String
        let type: String
        let scaleMin: Int
        let scaleMax: Int
        let unit: String
        let colorHex: String
        let isArchived: Bool
        let entries: [EntryData]
    }

    struct EntryData: Codable {
        let date: Date
        let value: Double
        let note: String
    }
}

struct DataManager {

    static func exportJSON(from context: ModelContext) throws -> Data {
        let descriptor = FetchDescriptor<Subject>(sortBy: [SortDescriptor(\.name)])
        let subjects = try context.fetch(descriptor)

        let backup = DayMarkBackup(
            version: 1,
            exportDate: Date(),
            subjects: subjects.map { subject in
                DayMarkBackup.SubjectData(
                    name: subject.name,
                    emoji: subject.emoji,
                    colorHex: subject.colorHex,
                    trackers: subject.trackers.map { tracker in
                        DayMarkBackup.TrackerData(
                            name: tracker.name,
                            type: tracker.type.rawValue,
                            scaleMin: tracker.scaleMin,
                            scaleMax: tracker.scaleMax,
                            unit: tracker.unit,
                            colorHex: tracker.colorHex,
                            isArchived: tracker.isArchived,
                            entries: tracker.sortedEntries.map { entry in
                                DayMarkBackup.EntryData(date: entry.date, value: entry.value, note: entry.note)
                            }
                        )
                    }
                )
            }
        )

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        return try encoder.encode(backup)
    }

    static func exportHTML(from context: ModelContext) throws -> Data {
        let descriptor = FetchDescriptor<Subject>(sortBy: [SortDescriptor(\.name)])
        let subjects = try context.fetch(descriptor)
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        dateFormatter.timeStyle = .short

        var html = """
        <!DOCTYPE html>
        <html><head><meta charset="utf-8"><meta name="viewport" content="width=device-width, initial-scale=1">
        <title>DayMark Export</title>
        <style>
        body { font-family: -apple-system, system-ui, sans-serif; max-width: 800px; margin: 0 auto; padding: 20px; background: #1A1A2E; color: #E8E8E8; }
        h1 { color: #8ECAE6; border-bottom: 2px solid #2A2A4A; padding-bottom: 8px; }
        h2 { color: #FFCA3A; margin-top: 32px; }
        h3 { color: #C77DFF; }
        .subject { background: #16213E; border-radius: 12px; padding: 20px; margin: 16px 0; }
        .tracker { background: #1A1A2E; border-radius: 8px; padding: 16px; margin: 12px 0; border-left: 4px solid; }
        table { width: 100%; border-collapse: collapse; margin: 8px 0; }
        th { text-align: left; padding: 8px; border-bottom: 1px solid #2A2A4A; color: #8ECAE6; }
        td { padding: 8px; border-bottom: 1px solid #1A1A2E; }
        .badge { display: inline-block; padding: 2px 8px; border-radius: 4px; font-size: 12px; }
        .meta { color: #888; font-size: 14px; }
        </style></head><body>
        <h1>📊 DayMark Export</h1>
        <p class="meta">Exported \(dateFormatter.string(from: Date()))</p>
        """

        for subject in subjects {
            html += """
            <div class="subject">
            <h2>\(subject.emoji) \(escapeHTML(subject.name))</h2>
            """

            for tracker in subject.trackers {
                let typeLabel: String
                switch tracker.type {
                case .scale: typeLabel = "Scale (\(tracker.scaleMin)–\(tracker.scaleMax))"
                case .yesNo: typeLabel = "Yes / No"
                case .count: typeLabel = "Count\(tracker.unit.isEmpty ? "" : " (\(escapeHTML(tracker.unit)))")"
                }

                html += """
                <div class="tracker" style="border-color: \(tracker.colorHex);">
                <h3>\(escapeHTML(tracker.name)) <span class="badge" style="background: \(tracker.colorHex)33; color: \(tracker.colorHex);">\(typeLabel)</span></h3>
                """

                let sorted = tracker.sortedEntries
                if sorted.isEmpty {
                    html += "<p class=\"meta\">No entries</p>"
                } else {
                    html += "<table><tr><th>Date</th><th>Value</th><th>Note</th></tr>"
                    for entry in sorted {
                        let displayValue: String
                        switch tracker.type {
                        case .yesNo: displayValue = entry.value >= 1 ? "✅ Yes" : "❌ No"
                        case .scale: displayValue = "\(Int(entry.value))"
                        case .count: displayValue = "\(Int(entry.value))\(tracker.unit.isEmpty ? "" : " \(escapeHTML(tracker.unit))")"
                        }
                        html += "<tr><td>\(dateFormatter.string(from: entry.date))</td><td>\(displayValue)</td><td>\(escapeHTML(entry.note))</td></tr>"
                    }
                    html += "</table>"
                }
                html += "</div>"
            }
            html += "</div>"
        }

        html += "</body></html>"
        return Data(html.utf8)
    }

    static func importJSON(from data: Data, into context: ModelContext) throws -> ImportResult {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let backup = try decoder.decode(DayMarkBackup.self, from: data)

        var subjectCount = 0
        var trackerCount = 0
        var entryCount = 0

        for subjectData in backup.subjects {
            let subject = Subject(name: subjectData.name, emoji: subjectData.emoji, colorHex: subjectData.colorHex)
            context.insert(subject)
            subjectCount += 1

            for trackerData in subjectData.trackers {
                let type = TrackerType(rawValue: trackerData.type) ?? .count
                let tracker = Tracker(
                    name: trackerData.name,
                    type: type,
                    scaleMin: trackerData.scaleMin,
                    scaleMax: trackerData.scaleMax,
                    unit: trackerData.unit,
                    colorHex: trackerData.colorHex
                )
                tracker.isArchived = trackerData.isArchived
                tracker.subject = subject
                context.insert(tracker)
                trackerCount += 1

                for entryData in trackerData.entries {
                    let entry = Entry(date: entryData.date, value: entryData.value, note: entryData.note)
                    entry.tracker = tracker
                    context.insert(entry)
                    entryCount += 1
                }
            }
        }

        return ImportResult(subjects: subjectCount, trackers: trackerCount, entries: entryCount)
    }

    private static func escapeHTML(_ string: String) -> String {
        string
            .replacingOccurrences(of: "&", with: "&amp;")
            .replacingOccurrences(of: "<", with: "&lt;")
            .replacingOccurrences(of: ">", with: "&gt;")
            .replacingOccurrences(of: "\"", with: "&quot;")
    }

    struct ImportResult {
        let subjects: Int
        let trackers: Int
        let entries: Int
    }
}
