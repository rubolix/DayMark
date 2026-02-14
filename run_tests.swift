#!/usr/bin/env swift
// DayMark Test Suite
// Run: swift run_tests.swift

import Foundation

var passed = 0
var failed = 0

func assert(_ condition: Bool, _ msg: String) {
    if condition {
        passed += 1
        print("  ✅ \(msg)")
    } else {
        failed += 1
        print("  ❌ FAIL: \(msg)")
    }
}

let cal = Calendar.current

// ============================================================
print("\n📊 TRACKER TYPE TESTS")
print(String(repeating: "=", count: 50))

// Scale tracker value validation
func isValidScaleValue(_ value: Double, min: Int, max: Int) -> Bool {
    Int(value) >= min && Int(value) <= max
}

assert(isValidScaleValue(3, min: 1, max: 5), "Scale: 3 is valid for 1-5")
assert(isValidScaleValue(1, min: 1, max: 5), "Scale: 1 (min) is valid for 1-5")
assert(isValidScaleValue(5, min: 1, max: 5), "Scale: 5 (max) is valid for 1-5")
assert(!isValidScaleValue(0, min: 1, max: 5), "Scale: 0 is invalid for 1-5")
assert(!isValidScaleValue(6, min: 1, max: 5), "Scale: 6 is invalid for 1-5")
assert(isValidScaleValue(0, min: 0, max: 10), "Scale: 0 is valid for 0-10")
assert(isValidScaleValue(10, min: 0, max: 10), "Scale: 10 is valid for 0-10")
assert(!isValidScaleValue(-1, min: 0, max: 10), "Scale: -1 is invalid for 0-10")
assert(isValidScaleValue(50, min: 1, max: 100), "Scale: 50 is valid for 1-100")

// Yes/No tracker value encoding
func yesNoValue(_ isYes: Bool) -> Double { isYes ? 1.0 : 0.0 }
func isYes(_ value: Double) -> Bool { value >= 1 }

assert(yesNoValue(true) == 1.0, "YesNo: true encodes to 1.0")
assert(yesNoValue(false) == 0.0, "YesNo: false encodes to 0.0")
assert(isYes(1.0), "YesNo: 1.0 decodes to Yes")
assert(!isYes(0.0), "YesNo: 0.0 decodes to No")
assert(isYes(2.0), "YesNo: 2.0 decodes to Yes (threshold)")

// Count tracker values
assert(Int(0.0) == 0, "Count: 0 is valid")
assert(Int(42.0) == 42, "Count: 42 is valid")
assert(Int(999.0) == 999, "Count: large values work")

// ============================================================
print("\n📈 CHART PERIOD TESTS")
print(String(repeating: "=", count: 50))

let now = Date()

func entriesInPeriod(entries: [(Date, Double)], start: Date, end: Date) -> [(Date, Double)] {
    entries.filter { $0.0 >= start && $0.0 <= end }
}

// Generate sample data: one entry per day for 100 days
var sampleEntries: [(Date, Double)] = []
for i in 0..<100 {
    let date = cal.date(byAdding: .day, value: -i, to: now)!
    sampleEntries.append((date, Double(i % 5 + 1)))
}

// Week filter
let weekAgo = cal.date(byAdding: .day, value: -7, to: now)!
let weekEntries = entriesInPeriod(entries: sampleEntries, start: weekAgo, end: now)
assert(weekEntries.count == 8, "Week period: 8 entries (today + 7 days ago)")

// Month filter
let monthAgo = cal.date(byAdding: .month, value: -1, to: now)!
let monthEntries = entriesInPeriod(entries: sampleEntries, start: monthAgo, end: now)
assert(monthEntries.count >= 29 && monthEntries.count <= 32, "Month period: ~30 entries (got \(monthEntries.count))")

// 3 Month filter
let threeMonthsAgo = cal.date(byAdding: .month, value: -3, to: now)!
let threeMonthEntries = entriesInPeriod(entries: sampleEntries, start: threeMonthsAgo, end: now)
assert(threeMonthEntries.count >= 90, "3 Month period: ~90+ entries (got \(threeMonthEntries.count))")

// Custom range
let customStart = cal.date(byAdding: .day, value: -14, to: now)!
let customEnd = cal.date(byAdding: .day, value: -7, to: now)!
let customEntries = entriesInPeriod(entries: sampleEntries, start: customStart, end: customEnd)
assert(customEntries.count == 8, "Custom 2-week-ago to 1-week-ago: 8 entries")

// Empty period
let futureStart = cal.date(byAdding: .day, value: 10, to: now)!
let futureEnd = cal.date(byAdding: .day, value: 20, to: now)!
let emptyEntries = entriesInPeriod(entries: sampleEntries, start: futureStart, end: futureEnd)
assert(emptyEntries.count == 0, "Future period: 0 entries")

// ============================================================
print("\n📊 STATISTICS TESTS")
print(String(repeating: "=", count: 50))

func stats(_ values: [Double]) -> (avg: Double, min: Double, max: Double, count: Int) {
    guard !values.isEmpty else { return (0, 0, 0, 0) }
    let avg = values.reduce(0, +) / Double(values.count)
    return (avg, values.min()!, values.max()!, values.count)
}

let scaleValues: [Double] = [1, 3, 5, 2, 4]
let s1 = stats(scaleValues)
assert(s1.avg == 3.0, "Stats: avg of [1,3,5,2,4] = 3.0")
assert(s1.min == 1.0, "Stats: min of [1,3,5,2,4] = 1")
assert(s1.max == 5.0, "Stats: max of [1,3,5,2,4] = 5")
assert(s1.count == 5, "Stats: count of [1,3,5,2,4] = 5")

let singleValue: [Double] = [7]
let s2 = stats(singleValue)
assert(s2.avg == 7.0, "Stats: avg of [7] = 7.0")
assert(s2.min == 7.0, "Stats: min of [7] = 7")
assert(s2.max == 7.0, "Stats: max of [7] = 7")

let emptyValues: [Double] = []
let s3 = stats(emptyValues)
assert(s3.count == 0, "Stats: empty array count = 0")

// YesNo summary
let yesNoValues: [Double] = [1, 0, 1, 1, 0, 1, 0]
let yesCount = yesNoValues.filter { $0 >= 1 }.count
let noCount = yesNoValues.filter { $0 < 1 }.count
assert(yesCount == 4, "YesNo summary: 4 yes")
assert(noCount == 3, "YesNo summary: 3 no")

// ============================================================
print("\n💾 JSON ENCODING/DECODING TESTS")
print(String(repeating: "=", count: 50))

struct TestBackup: Codable {
    let version: Int
    let exportDate: Date
    let subjects: [TestSubject]
}

struct TestSubject: Codable {
    let name: String
    let emoji: String
    let colorHex: String
    let trackers: [TestTracker]
}

struct TestTracker: Codable {
    let name: String
    let type: String
    let scaleMin: Int
    let scaleMax: Int
    let unit: String
    let entries: [TestEntry]
}

struct TestEntry: Codable {
    let date: Date
    let value: Double
    let note: String
}

let testDate = cal.date(from: DateComponents(year: 2026, month: 1, day: 15, hour: 12))!

let backup = TestBackup(
    version: 1,
    exportDate: now,
    subjects: [
        TestSubject(
            name: "Steph",
            emoji: "👩",
            colorHex: "#6A4C93",
            trackers: [
                TestTracker(
                    name: "Irritability",
                    type: "Scale",
                    scaleMin: 1,
                    scaleMax: 5,
                    unit: "",
                    entries: [
                        TestEntry(date: testDate, value: 3.0, note: "Normal day")
                    ]
                ),
                TestTracker(
                    name: "Water Intake",
                    type: "Count",
                    scaleMin: 1,
                    scaleMax: 5,
                    unit: "glasses",
                    entries: [
                        TestEntry(date: testDate, value: 8.0, note: "")
                    ]
                )
            ]
        ),
        TestSubject(
            name: "Buddy",
            emoji: "🐕",
            colorHex: "#2A9D5C",
            trackers: [
                TestTracker(
                    name: "Indoor Accident",
                    type: "Yes / No",
                    scaleMin: 1,
                    scaleMax: 5,
                    unit: "",
                    entries: [
                        TestEntry(date: testDate, value: 0.0, note: "Good boy")
                    ]
                )
            ]
        )
    ]
)

let encoder = JSONEncoder()
encoder.dateEncodingStrategy = .iso8601
encoder.outputFormatting = [.prettyPrinted, .sortedKeys]

do {
    let data = try encoder.encode(backup)
    assert(data.count > 0, "JSON encode: produces data")

    let jsonString = String(data: data, encoding: .utf8)!
    assert(jsonString.contains("Steph"), "JSON encode: contains subject name")
    assert(jsonString.contains("Irritability"), "JSON encode: contains tracker name")
    assert(jsonString.contains("Indoor Accident"), "JSON encode: contains yes/no tracker")
    assert(jsonString.contains("glasses"), "JSON encode: contains unit")
    assert(jsonString.contains("Normal day"), "JSON encode: contains note")

    // Decode
    let decoder = JSONDecoder()
    decoder.dateDecodingStrategy = .iso8601
    let decoded = try decoder.decode(TestBackup.self, from: data)

    assert(decoded.version == 1, "JSON decode: version = 1")
    assert(decoded.subjects.count == 2, "JSON decode: 2 subjects")
    assert(decoded.subjects[0].name == "Buddy" || decoded.subjects[1].name == "Buddy", "JSON decode: has Buddy")
    assert(decoded.subjects[0].trackers.count + decoded.subjects[1].trackers.count == 3, "JSON decode: 3 total trackers")

    let steph = decoded.subjects.first { $0.name == "Steph" }!
    assert(steph.emoji == "👩", "JSON decode: emoji preserved")
    assert(steph.colorHex == "#6A4C93", "JSON decode: color preserved")

    let irritability = steph.trackers.first { $0.name == "Irritability" }!
    assert(irritability.type == "Scale", "JSON decode: type preserved")
    assert(irritability.scaleMin == 1, "JSON decode: scaleMin preserved")
    assert(irritability.scaleMax == 5, "JSON decode: scaleMax preserved")
    assert(irritability.entries.count == 1, "JSON decode: entry count preserved")
    assert(irritability.entries[0].value == 3.0, "JSON decode: entry value preserved")
    assert(irritability.entries[0].note == "Normal day", "JSON decode: note preserved")

    let buddy = decoded.subjects.first { $0.name == "Buddy" }!
    let accident = buddy.trackers[0]
    assert(accident.type == "Yes / No", "JSON decode: YesNo type preserved")
    assert(accident.entries[0].value == 0.0, "JSON decode: No value = 0.0")
} catch {
    failed += 1
    print("  ❌ JSON encoding/decoding failed: \(error)")
}

// ============================================================
print("\n🔒 ARCHIVE TESTS")
print(String(repeating: "=", count: 50))

// Simulated archive behavior
struct SimTracker {
    var isArchived: Bool
    var entries: [(Date, Double)]

    var activeEntries: [(Date, Double)] {
        isArchived ? [] : entries
    }
}

var tracker = SimTracker(isArchived: false, entries: [(now, 3.0), (weekAgo, 2.0)])
assert(tracker.activeEntries.count == 2, "Active tracker: shows 2 entries")

tracker.isArchived = true
assert(tracker.activeEntries.count == 0, "Archived tracker: shows 0 active entries")
assert(tracker.entries.count == 2, "Archived tracker: still has 2 entries in storage")

tracker.isArchived = false
assert(tracker.activeEntries.count == 2, "Unarchived tracker: shows 2 entries again")

// ============================================================
print("\n🎨 COLOR TESTS")
print(String(repeating: "=", count: 50))

func parseHex(_ hex: String) -> (r: Int, g: Int, b: Int)? {
    let h = hex.trimmingCharacters(in: CharacterSet(charactersIn: "#"))
    guard h.count == 6 else { return nil }
    var int: UInt64 = 0
    Scanner(string: h).scanHexInt64(&int)
    return (Int(int >> 16), Int(int >> 8 & 0xFF), Int(int & 0xFF))
}

let jewels = ["#6A4C93", "#1982C4", "#2A9D5C", "#B8436E", "#FFCA3A",
              "#FF595E", "#8AC926", "#C77DFF", "#E07A5F", "#3D5A80",
              "#F4845F", "#48BFE3"]

for hex in jewels {
    let parsed = parseHex(hex)
    assert(parsed != nil, "Color \(hex) parses successfully")
}

assert(parseHex("invalid") == nil, "Invalid hex returns nil")
assert(parseHex("#GGG") == nil, "Short invalid hex returns nil")

let amethyst = parseHex("#6A4C93")!
assert(amethyst.r == 106 && amethyst.g == 76 && amethyst.b == 147, "Amethyst RGB correct (106, 76, 147)")

// ============================================================
print("\n📅 DATE GROUPING TESTS")
print(String(repeating: "=", count: 50))

func groupByDay(_ entries: [(Date, Double)]) -> [String: [(Date, Double)]] {
    let df = DateFormatter()
    df.dateFormat = "yyyy-MM-dd"
    var result: [String: [(Date, Double)]] = [:]
    for e in entries {
        let key = df.string(from: e.0)
        result[key, default: []].append(e)
    }
    return result
}

let morning = cal.date(bySettingHour: 9, minute: 0, second: 0, of: now)!
let afternoon = cal.date(bySettingHour: 14, minute: 0, second: 0, of: now)!
let yesterday = cal.date(byAdding: .day, value: -1, to: morning)!

let grouped = groupByDay([(morning, 3), (afternoon, 4), (yesterday, 2)])
assert(grouped.count == 2, "Grouping: 2 days from 3 entries")

let df = DateFormatter()
df.dateFormat = "yyyy-MM-dd"
let todayKey = df.string(from: morning)
assert(grouped[todayKey]?.count == 2, "Grouping: 2 entries today")

let yesterdayKey = df.string(from: yesterday)
assert(grouped[yesterdayKey]?.count == 1, "Grouping: 1 entry yesterday")

// ============================================================
func groupByWeek(_ entries: [(Date, Double)]) -> Int {
    var weeks = Set<Int>()
    for e in entries {
        let week = cal.component(.weekOfYear, from: e.0)
        weeks.insert(week)
    }
    return weeks.count
}

let twoWeeksEntries: [(Date, Double)] = (0..<14).map { i in
    (cal.date(byAdding: .day, value: -i, to: now)!, Double(i))
}
let weekCount = groupByWeek(twoWeeksEntries)
assert(weekCount >= 2 && weekCount <= 3, "Week grouping: 14 days spans 2-3 weeks (got \(weekCount))")

// ============================================================
print("\n" + String(repeating: "=", count: 50))
print("📊 RESULTS: \(passed) passed, \(failed) failed")
if failed == 0 {
    print("🎉 ALL TESTS PASSED!")
} else {
    print("⚠️ \(failed) test(s) failed")
    exit(1)
}
