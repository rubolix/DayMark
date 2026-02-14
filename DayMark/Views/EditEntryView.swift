import SwiftUI

struct EditEntryView: View {
    let entry: Entry
    let tracker: Tracker
    @Environment(\.dismiss) private var dismiss

    @State private var date: Date
    @State private var scaleValue: Int
    @State private var yesNoValue: Bool
    @State private var countValue: Int
    @State private var note: String

    init(entry: Entry, tracker: Tracker) {
        self.entry = entry
        self.tracker = tracker
        _date = State(initialValue: entry.date)
        _scaleValue = State(initialValue: Int(entry.value))
        _yesNoValue = State(initialValue: entry.value >= 1)
        _countValue = State(initialValue: Int(entry.value))
        _note = State(initialValue: entry.note)
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
                    }
                }

                Section("Note (optional)") {
                    TextField("Any additional context", text: $note)
                }
            }
            .navigationTitle("Edit Entry")
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
        entry.date = date
        entry.note = note.trimmingCharacters(in: .whitespaces)
        switch tracker.type {
        case .scale: entry.value = Double(scaleValue)
        case .yesNo: entry.value = yesNoValue ? 1.0 : 0.0
        case .count: entry.value = Double(countValue)
        }
        dismiss()
    }
}
