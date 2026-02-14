import SwiftUI
import SwiftData
import Charts
import WidgetKit

enum ChartPeriod: String, CaseIterable {
    case week = "Week"
    case month = "Month"
    case threeMonths = "3 Months"
    case custom = "Custom"
}

struct DailyAggregate: Identifiable {
    let id = UUID()
    let date: Date
    let value: Double
}

struct TrackerDetailView: View {
    @Bindable var tracker: Tracker
    @Environment(\.modelContext) private var modelContext
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.dismiss) private var dismiss
    @Query private var allEntries: [Entry]
    @State private var showingLogEntry = false
    @State private var showingEditTracker = false
    @State private var showingDeleteConfirmation = false
    @State private var selectedEntry: Entry?
    @State private var chartPeriod: ChartPeriod = .week
    @State private var customStart = Calendar.current.date(byAdding: .month, value: -1, to: Date())!
    @State private var customEnd = Date()

    init(tracker: Tracker) {
        self._tracker = Bindable(tracker)
        // @Query fetches all entries; we filter to this tracker in computed properties
        self._allEntries = Query(sort: \Entry.date, order: .reverse)
    }

    /// All entries belonging to this tracker
    private var trackerEntries: [Entry] {
        allEntries.filter { $0.tracker?.id == tracker.id }
    }

    private var dateRange: (start: Date, end: Date) {
        let cal = Calendar.current
        let now = Date()
        switch chartPeriod {
        case .week:
            return (cal.date(byAdding: .day, value: -7, to: now)!, now)
        case .month:
            return (cal.date(byAdding: .month, value: -1, to: now)!, now)
        case .threeMonths:
            return (cal.date(byAdding: .month, value: -3, to: now)!, now)
        case .custom:
            return (customStart, cal.date(byAdding: .day, value: 1, to: customEnd)!)
        }
    }

    private var filteredEntries: [Entry] {
        let range = dateRange
        return trackerEntries.filter { $0.date >= range.start && $0.date <= range.end }
    }

    private var dailyAggregates: [DailyAggregate] {
        let cal = Calendar.current
        var grouped: [Date: Double] = [:]
        for entry in filteredEntries {
            let day = cal.startOfDay(for: entry.date)
            grouped[day, default: 0] += entry.value
        }
        return grouped.map { DailyAggregate(date: $0.key, value: $0.value) }
            .sorted { $0.date < $1.date }
    }

    var body: some View {
        List {
            if tracker.isArchived {
                Section {
                    HStack {
                        Image(systemName: "pause.circle.fill")
                            .foregroundStyle(.orange)
                        Text("Tracker Paused")
                            .fontWeight(.medium)
                        Spacer()
                        Button("Unarchive") {
                            tracker.isArchived = false
                            if tracker.reminderCadence != .none {
                                NotificationManager.scheduleReminders(for: tracker)
                            }
                        }
                        .buttonStyle(.bordered)
                        .tint(.orange)
                    }
                }
            }

            Section("Chart") {
                VStack(alignment: .leading, spacing: 8) {
                    Picker("Period", selection: $chartPeriod) {
                        ForEach(ChartPeriod.allCases, id: \.self) { period in
                            Text(period.rawValue).tag(period)
                        }
                    }
                    .pickerStyle(.segmented)

                    if chartPeriod == .custom {
                        HStack {
                            DatePicker("From", selection: $customStart, displayedComponents: .date)
                                .labelsHidden()
                            Text("to")
                                .foregroundStyle(.secondary)
                            DatePicker("To", selection: $customEnd, displayedComponents: .date)
                                .labelsHidden()
                        }
                        .font(.caption)
                    }

                    if filteredEntries.isEmpty {
                        Text("No entries for this period")
                            .foregroundStyle(.secondary)
                            .frame(height: 200)
                            .frame(maxWidth: .infinity)
                    } else {
                        chartView
                            .frame(height: 200)
                    }
                }
                .padding(.vertical, 4)
            }

            if tracker.type == .yesNo {
                Section("Summary") {
                    let yes = filteredEntries.filter { $0.value >= 1 }.count
                    let no = filteredEntries.filter { $0.value < 1 }.count
                    HStack {
                        VStack {
                            Text("\(yes)")
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundStyle(.green)
                            Text("Yes")
                                .font(.caption)
                        }
                        .frame(maxWidth: .infinity)
                        VStack {
                            Text("\(no)")
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundStyle(.red)
                            Text("No")
                                .font(.caption)
                        }
                        .frame(maxWidth: .infinity)
                        VStack {
                            Text("\(filteredEntries.count)")
                                .font(.title2)
                                .fontWeight(.bold)
                            Text("Total")
                                .font(.caption)
                        }
                        .frame(maxWidth: .infinity)
                    }
                }
            }

            if tracker.type == .count {
                Section("Daily Stats") {
                    let aggs = dailyAggregates
                    if !aggs.isEmpty {
                        let dailyValues = aggs.map(\.value)
                        let total = Int(dailyValues.reduce(0, +))
                        HStack {
                            StatBox(label: "Total", value: "\(total)")
                            StatBox(label: "Daily Avg", value: String(format: "%.1f", dailyValues.reduce(0, +) / Double(dailyValues.count)))
                            StatBox(label: "Best Day", value: "\(Int(dailyValues.max()!))")
                            StatBox(label: "Days", value: "\(aggs.count)")
                        }
                    }
                }
            }

            if tracker.type == .scale {
                Section("Stats") {
                    let values = filteredEntries.map(\.value)
                    if !values.isEmpty {
                        HStack {
                            StatBox(label: "Avg", value: String(format: "%.1f", values.reduce(0, +) / Double(values.count)))
                            StatBox(label: "Min", value: "\(Int(values.min()!))")
                            StatBox(label: "Max", value: "\(Int(values.max()!))")
                            StatBox(label: "Entries", value: "\(values.count)")
                        }
                    }
                }
            }

            Section("History") {
                ForEach(trackerEntries.prefix(50)) { entry in
                    Button {
                        selectedEntry = entry
                    } label: {
                        EntryRow(entry: entry, tracker: tracker)
                    }
                    .buttonStyle(.plain)
                    .swipeActions(edge: .trailing) {
                        Button(role: .destructive) {
                            modelContext.delete(entry)
                            SharedModelContainer.saveAndReloadWidgets(modelContext)
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    }
                }
            }
        }
        .navigationTitle(tracker.name)
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Menu {
                    if !tracker.isArchived {
                        Button {
                            showingLogEntry = true
                        } label: {
                            Label("Log Entry", systemImage: "plus")
                        }
                    }
                    Button {
                        showingEditTracker = true
                    } label: {
                        Label("Edit Tracker", systemImage: "pencil")
                    }
                    Button {
                        if tracker.isArchived {
                            tracker.isArchived = false
                            if tracker.reminderCadence != .none {
                                NotificationManager.scheduleReminders(for: tracker)
                            }
                        } else {
                            tracker.isArchived = true
                            NotificationManager.removeReminders(for: tracker)
                            SharedModelContainer.saveAndReloadWidgets(modelContext)
                            dismiss()
                        }
                    } label: {
                        Label(tracker.isArchived ? "Unarchive" : "Archive", systemImage: tracker.isArchived ? "play.circle" : "archivebox")
                    }
                    Divider()
                    Button(role: .destructive) {
                        showingDeleteConfirmation = true
                    } label: {
                        Label("Delete Tracker", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
        .sheet(isPresented: $showingLogEntry) {
            LogEntryView(tracker: tracker)
        }
        .sheet(isPresented: $showingEditTracker) {
            EditTrackerView(tracker: tracker)
        }
        .sheet(item: $selectedEntry) { entry in
            EditEntryView(entry: entry, tracker: tracker)
        }
        .alert("Delete Tracker", isPresented: $showingDeleteConfirmation) {
            Button("Delete", role: .destructive) {
                NotificationManager.removeReminders(for: tracker)
                modelContext.delete(tracker)
                SharedModelContainer.saveAndReloadWidgets(modelContext)
                dismiss()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Are you sure you want to delete \"\(tracker.name)\"? All \(tracker.entries.count) entries will be permanently deleted.")
        }
    }

    @ViewBuilder
    private var chartView: some View {
        switch tracker.type {
        case .scale:
            let entries = filteredEntries.sorted { $0.date < $1.date }
            Chart(entries) { entry in
                LineMark(
                    x: .value("Date", entry.date),
                    y: .value("Value", entry.value)
                )
                .foregroundStyle(Color(hex: tracker.colorHex))
                PointMark(
                    x: .value("Date", entry.date),
                    y: .value("Value", entry.value)
                )
                .foregroundStyle(Color(hex: tracker.colorHex))
            }
            .chartYScale(domain: tracker.scaleMin...tracker.scaleMax)

        case .yesNo:
            let aggregates = dailyAggregates
            Chart(aggregates) { agg in
                BarMark(
                    x: .value("Date", agg.date, unit: .day),
                    y: .value("Value", 1)
                )
                .foregroundStyle(agg.value >= 1 ? Color.green : Color.red.opacity(0.5))
            }

        case .count:
            let aggregates = dailyAggregates
            let maxVal = max(1, Int(aggregates.map(\.value).max() ?? 1))
            Chart(aggregates) { agg in
                BarMark(
                    x: .value("Date", agg.date, unit: .day),
                    y: .value("Count", Int(agg.value))
                )
                .foregroundStyle(Color(hex: tracker.colorHex).gradient)
            }
            .chartYScale(domain: 0...maxVal)
            .chartYAxis {
                AxisMarks(values: .stride(by: max(1, Double(maxVal / 5)))) { value in
                    AxisGridLine()
                    AxisValueLabel {
                        if let v = value.as(Int.self) {
                            Text("\(v)")
                        }
                    }
                }
            }
        }
    }
}

struct StatBox: View {
    let label: String
    let value: String

    var body: some View {
        VStack {
            Text(value)
                .font(.title3)
                .fontWeight(.bold)
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

struct EntryRow: View {
    let entry: Entry
    let tracker: Tracker

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(entry.date, style: .date)
                    .font(.subheadline)
                if !entry.note.isEmpty {
                    Text(entry.note)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }
            Spacer()
            Text(displayValue)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundStyle(Color(hex: tracker.colorHex))
        }
    }

    private var displayValue: String {
        switch tracker.type {
        case .yesNo: return entry.value >= 1 ? "✅ Yes" : "❌ No"
        case .scale: return "\(Int(entry.value))/\(tracker.scaleMax)"
        case .count:
            let val = "\(Int(entry.value))"
            return tracker.unit.isEmpty ? val : "\(val) \(tracker.unit)"
        }
    }
}
