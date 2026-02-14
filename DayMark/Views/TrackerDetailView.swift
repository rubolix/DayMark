import SwiftUI
import Charts

enum ChartPeriod: String, CaseIterable {
    case week = "Week"
    case month = "Month"
    case threeMonths = "3 Months"
    case custom = "Custom"
}

struct TrackerDetailView: View {
    let tracker: Tracker
    @Environment(\.modelContext) private var modelContext
    @State private var showingLogEntry = false
    @State private var showingEditTracker = false
    @State private var selectedEntry: Entry?
    @State private var chartPeriod: ChartPeriod = .week
    @State private var customStart = Calendar.current.date(byAdding: .month, value: -1, to: Date())!
    @State private var customEnd = Date()

    var filteredEntries: [Entry] {
        let cal = Calendar.current
        let now = Date()
        let start: Date
        let end: Date

        switch chartPeriod {
        case .week:
            start = cal.date(byAdding: .day, value: -7, to: now)!
            end = now
        case .month:
            start = cal.date(byAdding: .month, value: -1, to: now)!
            end = now
        case .threeMonths:
            start = cal.date(byAdding: .month, value: -3, to: now)!
            end = now
        case .custom:
            start = customStart
            end = cal.date(byAdding: .day, value: 1, to: customEnd)!
        }

        return tracker.sortedEntries.filter { $0.date >= start && $0.date <= end }
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

            if tracker.type == .scale || tracker.type == .count {
                Section("Stats") {
                    let values = filteredEntries.map(\.value)
                    if !values.isEmpty {
                        HStack {
                            StatBox(label: "Avg", value: String(format: "%.1f", values.reduce(0, +) / Double(values.count)))
                            StatBox(label: "Min", value: "\(Int(values.min()!))")
                            StatBox(label: "Max", value: "\(Int(values.max()!))")
                            StatBox(label: "Count", value: "\(values.count)")
                        }
                    }
                }
            }

            Section("History") {
                ForEach(tracker.sortedEntries.prefix(50)) { entry in
                    Button {
                        selectedEntry = entry
                    } label: {
                        EntryRow(entry: entry, tracker: tracker)
                    }
                    .buttonStyle(.plain)
                    .swipeActions(edge: .trailing) {
                        Button(role: .destructive) {
                            modelContext.delete(entry)
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
                        tracker.isArchived.toggle()
                    } label: {
                        Label(tracker.isArchived ? "Unarchive" : "Archive", systemImage: tracker.isArchived ? "play.circle" : "pause.circle")
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
    }

    @ViewBuilder
    private var chartView: some View {
        let entries = filteredEntries.sorted { $0.date < $1.date }
        switch tracker.type {
        case .scale:
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
            Chart(entries) { entry in
                BarMark(
                    x: .value("Date", entry.date, unit: .day),
                    y: .value("Value", 1)
                )
                .foregroundStyle(entry.value >= 1 ? Color.green : Color.red.opacity(0.5))
            }

        case .count:
            Chart(entries) { entry in
                BarMark(
                    x: .value("Date", entry.date, unit: .day),
                    y: .value("Value", entry.value)
                )
                .foregroundStyle(Color(hex: tracker.colorHex).gradient)
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
