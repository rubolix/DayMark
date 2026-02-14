import SwiftUI

struct SubjectCard: View {
    let subject: Subject

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(subject.emoji)
                    .font(.title2)
                Text(subject.name)
                    .font(.headline)
                Spacer()
                let active = subject.trackers.filter { !$0.isArchived }
                Text("\(active.count) tracker\(active.count == 1 ? "" : "s")")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            let activeTrackers = subject.trackers.filter { !$0.isArchived }
            if activeTrackers.isEmpty {
                Text("No active trackers")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            } else {
                ForEach(activeTrackers.prefix(4)) { tracker in
                    TrackerSummaryRow(tracker: tracker)
                }
                if activeTrackers.count > 4 {
                    Text("+\(activeTrackers.count - 4) more")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding()
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color(hex: subject.colorHex).opacity(0.4), lineWidth: 1.5)
        )
    }
}

struct TrackerSummaryRow: View {
    let tracker: Tracker

    var body: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(Color(hex: tracker.colorHex))
                .frame(width: 8, height: 8)
            Text(tracker.name)
                .font(.subheadline)
            Spacer()
            if let latest = tracker.latestEntry {
                Text(displayValue(latest))
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundStyle(Color(hex: tracker.colorHex))
            } else {
                Text("—")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private func displayValue(_ entry: Entry) -> String {
        switch tracker.type {
        case .yesNo: return entry.value >= 1 ? "Yes" : "No"
        case .scale: return "\(Int(entry.value))/\(tracker.scaleMax)"
        case .count:
            let val = "\(Int(entry.value))"
            return tracker.unit.isEmpty ? val : "\(val) \(tracker.unit)"
        }
    }
}
