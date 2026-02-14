import WidgetKit
import SwiftUI
import SwiftData
import AppIntents

struct CountTrackerEntry: TimelineEntry {
    let date: Date
    let trackerName: String
    let trackerColorHex: String
    let todayCount: Int
    let unit: String
    let profileName: String
    let profileEmoji: String
    let trackerID: String?
    let isPlaceholder: Bool
}

struct CountTrackerProvider: AppIntentTimelineProvider {
    func placeholder(in context: Context) -> CountTrackerEntry {
        CountTrackerEntry(
            date: .now,
            trackerName: "Water",
            trackerColorHex: "#1982C4",
            todayCount: 3,
            unit: "glasses",
            profileName: "Profile",
            profileEmoji: "👤",
            trackerID: nil,
            isPlaceholder: true
        )
    }

    func snapshot(for configuration: SelectTrackerIntent, in context: Context) async -> CountTrackerEntry {
        loadEntry(for: configuration)
    }

    func timeline(for configuration: SelectTrackerIntent, in context: Context) async -> Timeline<CountTrackerEntry> {
        let entry = loadEntry(for: configuration)
        return Timeline(entries: [entry], policy: .atEnd)
    }

    private func loadEntry(for configuration: SelectTrackerIntent) -> CountTrackerEntry {
        guard let selectedTracker = configuration.tracker else {
            return CountTrackerEntry(
                date: .now,
                trackerName: "No tracker selected",
                trackerColorHex: "#1982C4",
                todayCount: 0,
                unit: "",
                profileName: "",
                profileEmoji: "",
                trackerID: nil,
                isPlaceholder: false
            )
        }

        let context = SharedModelContainer.newContext()
        let descriptor = FetchDescriptor<Tracker>()
        let trackers = (try? context.fetch(descriptor)) ?? []

        guard let tracker = trackers.first(where: {
            $0.id.uuidString == selectedTracker.id
        }) else {
            return CountTrackerEntry(
                date: .now,
                trackerName: selectedTracker.name,
                trackerColorHex: "#1982C4",
                todayCount: 0,
                unit: "",
                profileName: selectedTracker.profileName,
                profileEmoji: "",
                trackerID: selectedTracker.id,
                isPlaceholder: false
            )
        }

        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: Date())
        let todayCount = tracker.entries
            .filter { calendar.isDate($0.date, inSameDayAs: startOfDay) }
            .reduce(0) { $0 + Int($1.value) }

        return CountTrackerEntry(
            date: .now,
            trackerName: tracker.name,
            trackerColorHex: tracker.colorHex,
            todayCount: todayCount,
            unit: tracker.unit,
            profileName: tracker.profile?.name ?? "",
            profileEmoji: tracker.profile?.emoji ?? "👤",
            trackerID: selectedTracker.id,
            isPlaceholder: false
        )
    }
}

struct DayMarkWidgetSmallView: View {
    let entry: CountTrackerEntry
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(entry.trackerName)
                .font(.headline)
                .foregroundStyle(Color(hex: entry.trackerColorHex))
                .lineLimit(1)

            Spacer()

            Text("\(entry.todayCount)")
                .font(.system(size: 44, weight: .bold, design: .rounded))
                .foregroundStyle(Color(hex: entry.trackerColorHex))

            Spacer()

            if let trackerID = entry.trackerID {
                Button(intent: IncrementTrackerIntent(trackerID: trackerID)) {
                    Label("Add", systemImage: "plus")
                        .font(.subheadline.weight(.semibold))
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .tint(Color(hex: entry.trackerColorHex))
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct DayMarkWidgetMediumView: View {
    let entry: CountTrackerEntry
    
    var body: some View {
        HStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 4) {
                if !entry.profileName.isEmpty {
                    HStack(spacing: 4) {
                        Text(entry.profileEmoji)
                        Text(entry.profileName)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                Text(entry.trackerName)
                    .font(.headline)
                    .foregroundStyle(Color(hex: entry.trackerColorHex))
                    .lineLimit(1)

                Spacer()

                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    Text("\(entry.todayCount)")
                        .font(.system(size: 44, weight: .bold, design: .rounded))
                        .foregroundStyle(Color(hex: entry.trackerColorHex))
                    if !entry.unit.isEmpty {
                        Text(entry.unit)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
            }

            Spacer()

            if let trackerID = entry.trackerID {
                Button(intent: IncrementTrackerIntent(trackerID: trackerID)) {
                    Image(systemName: "plus")
                        .font(.title2.weight(.bold))
                        .frame(width: 56, height: 56)
                }
                .buttonStyle(.borderedProminent)
                .tint(Color(hex: entry.trackerColorHex))
                .clipShape(Circle())
            }
        }
    }
}

struct DayMarkWidgetEntryView: View {
    @Environment(\.widgetFamily) var family
    var entry: CountTrackerEntry

    var body: some View {
        switch family {
        case .systemSmall:
            DayMarkWidgetSmallView(entry: entry)
        case .systemMedium:
            DayMarkWidgetMediumView(entry: entry)
        default:
            DayMarkWidgetSmallView(entry: entry)
        }
    }
}

struct DayMarkWidget: Widget {
    let kind: String = "DayMarkWidget"

    var body: some WidgetConfiguration {
        AppIntentConfiguration(
            kind: kind,
            intent: SelectTrackerIntent.self,
            provider: CountTrackerProvider()
        ) { entry in
            DayMarkWidgetEntryView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("Count Tracker")
        .description("Track and increment your count trackers.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}
