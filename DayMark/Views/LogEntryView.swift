import SwiftUI

struct LogEntryView: View {
    let tracker: Tracker
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var date = Date()
    @State private var scaleValue: Int
    @State private var yesNoValue = true
    @State private var countValue = 1
    @State private var selectedPresets: Set<String> = []
    @State private var customNote = ""

    init(tracker: Tracker) {
        self.tracker = tracker
        _scaleValue = State(initialValue: (tracker.scaleMin + tracker.scaleMax) / 2)
    }

    private var composedNote: String {
        var parts: [String] = tracker.presetNotes.filter { selectedPresets.contains($0) }
        let trimmed = customNote.trimmingCharacters(in: .whitespaces)
        if !trimmed.isEmpty { parts.append(trimmed) }
        return parts.joined(separator: " · ")
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("When") {
                    DatePicker("Date", selection: $date, displayedComponents: [.date, .hourAndMinute])
                }

                Section("Value") {
                    switch tracker.type {
                    case .scale:
                        VStack(spacing: 12) {
                            Text("\(scaleValue)")
                                .font(.system(size: 48, weight: .bold, design: .rounded))
                                .foregroundStyle(Color(hex: tracker.colorHex))
                            HStack {
                                Text("\(tracker.scaleMin)")
                                    .font(.caption)
                                Slider(value: Binding(
                                    get: { Double(scaleValue) },
                                    set: { scaleValue = Int($0) }
                                ), in: Double(tracker.scaleMin)...Double(tracker.scaleMax), step: 1)
                                .tint(Color(hex: tracker.colorHex))
                                Text("\(tracker.scaleMax)")
                                    .font(.caption)
                            }
                        }
                        .padding(.vertical, 8)

                    case .yesNo:
                        Picker("", selection: $yesNoValue) {
                            Text("Yes").tag(true)
                            Text("No").tag(false)
                        }
                        .pickerStyle(.segmented)
                        .padding(.vertical, 4)

                    case .count:
                        HStack {
                            Button {
                                if countValue > 0 { countValue -= 1 }
                            } label: {
                                Image(systemName: "minus.circle.fill")
                                    .font(.title)
                                    .foregroundStyle(Color(hex: tracker.colorHex))
                            }
                            .buttonStyle(.plain)

                            TextField("Count", value: $countValue, format: .number)
                                .font(.system(size: 36, weight: .bold, design: .rounded))
                                .multilineTextAlignment(.center)
                                .keyboardType(.numberPad)
                                .frame(minWidth: 80)

                            Button {
                                countValue += 1
                            } label: {
                                Image(systemName: "plus.circle.fill")
                                    .font(.title)
                                    .foregroundStyle(Color(hex: tracker.colorHex))
                            }
                            .buttonStyle(.plain)
                        }
                        .padding(.vertical, 8)

                        if !tracker.unit.isEmpty {
                            Text(tracker.unit)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                    }
                }

                Section("Note (optional)") {
                    if !tracker.presetNotes.isEmpty {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach(tracker.presetNotes, id: \.self) { preset in
                                    Button {
                                        if selectedPresets.contains(preset) {
                                            selectedPresets.remove(preset)
                                        } else {
                                            selectedPresets.insert(preset)
                                        }
                                    } label: {
                                        Text(preset)
                                            .font(.subheadline)
                                            .padding(.horizontal, 12)
                                            .padding(.vertical, 6)
                                            .background(selectedPresets.contains(preset) ? Color(hex: tracker.colorHex) : Color(hex: tracker.colorHex).opacity(0.15))
                                            .foregroundStyle(selectedPresets.contains(preset) ? .white : Color(hex: tracker.colorHex))
                                            .clipShape(Capsule())
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                            .padding(.vertical, 4)
                        }
                    }
                    TextField("Any additional context", text: $customNote)
                }
            }
            .navigationTitle("Log Entry")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                }
            }
        }
    }

    private func save() {
        let value: Double
        switch tracker.type {
        case .scale: value = Double(scaleValue)
        case .yesNo: value = yesNoValue ? 1.0 : 0.0
        case .count: value = Double(countValue)
        }

        let entry = Entry(date: date, value: value, note: composedNote)
        entry.tracker = tracker
        modelContext.insert(entry)
        dismiss()
    }
}
