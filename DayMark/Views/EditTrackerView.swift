import SwiftUI

struct EditTrackerView: View {
    let tracker: Tracker
    @Environment(\.dismiss) private var dismiss

    @State private var name: String
    @State private var scaleMin: Int
    @State private var scaleMax: Int
    @State private var unit: String
    @State private var selectedColor: String
    @State private var presetNotes: [String]
    @State private var newPresetNote = ""
    @State private var reminderCadence: ReminderCadence
    @State private var reminderTime: Date
    @State private var reminderWeekday: Int
    @State private var reminderCustomDays: [Int]

    init(tracker: Tracker) {
        self.tracker = tracker
        _name = State(initialValue: tracker.name)
        _scaleMin = State(initialValue: tracker.scaleMin)
        _scaleMax = State(initialValue: tracker.scaleMax)
        _unit = State(initialValue: tracker.unit)
        _selectedColor = State(initialValue: tracker.colorHex)
        _presetNotes = State(initialValue: tracker.presetNotes)
        _reminderCadence = State(initialValue: tracker.reminderCadence)
        _reminderTime = State(initialValue: tracker.reminderTime)
        _reminderWeekday = State(initialValue: tracker.reminderWeekday)
        _reminderCustomDays = State(initialValue: tracker.reminderCustomDays)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Name") {
                    TextField("Name", text: $name)
                }

                if tracker.type == .scale {
                    Section("Scale Range") {
                        Stepper("Minimum: \(scaleMin)", value: $scaleMin, in: 0...scaleMax - 1)
                        Stepper("Maximum: \(scaleMax)", value: $scaleMax, in: scaleMin + 1...100)
                    }
                }

                if tracker.type == .count {
                    Section("Unit (optional)") {
                        TextField("e.g., glasses, minutes", text: $unit)
                    }
                }

                Section {
                    ForEach(presetNotes, id: \.self) { preset in
                        HStack {
                            Text(preset)
                            Spacer()
                            Button {
                                presetNotes.removeAll { $0 == preset }
                            } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundStyle(.secondary)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    HStack {
                        TextField("Add a quick note", text: $newPresetNote)
                        Button {
                            let trimmed = newPresetNote.trimmingCharacters(in: .whitespaces)
                            if !trimmed.isEmpty && !presetNotes.contains(trimmed) {
                                presetNotes.append(trimmed)
                                newPresetNote = ""
                            }
                        } label: {
                            Image(systemName: "plus.circle.fill")
                                .foregroundStyle(Color(hex: selectedColor))
                        }
                        .buttonStyle(.plain)
                        .disabled(newPresetNote.trimmingCharacters(in: .whitespaces).isEmpty)
                    }
                } header: {
                    Text("Quick Notes")
                } footer: {
                    Text("Preset notes you can tap to quickly add when logging an entry.")
                }

                ReminderSection(
                    cadence: $reminderCadence,
                    reminderTime: $reminderTime,
                    weekday: $reminderWeekday,
                    customDays: $reminderCustomDays
                )

                Section("Color") {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 6), spacing: 12) {
                        ForEach(JewelColors.options) { option in
                            Circle()
                                .fill(Color(hex: option.hex))
                                .frame(width: 36, height: 36)
                                .overlay(
                                    Circle()
                                        .stroke(Color.primary, lineWidth: selectedColor == option.hex ? 3 : 0)
                                )
                                .onTapGesture { selectedColor = option.hex }
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
            .navigationTitle("Edit Tracker")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                        .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
    }

    private func save() {
        tracker.name = name.trimmingCharacters(in: .whitespaces)
        tracker.scaleMin = scaleMin
        tracker.scaleMax = scaleMax
        tracker.unit = unit.trimmingCharacters(in: .whitespaces)
        tracker.colorHex = selectedColor
        tracker.presetNotes = presetNotes
        tracker.reminderCadence = reminderCadence
        let comps = Calendar.current.dateComponents([.hour, .minute], from: reminderTime)
        tracker.reminderHour = comps.hour ?? 20
        tracker.reminderMinute = comps.minute ?? 0
        tracker.reminderWeekday = reminderWeekday
        tracker.reminderCustomDays = reminderCustomDays

        if reminderCadence != .none {
            Task {
                let granted = await NotificationManager.requestPermission()
                if granted {
                    NotificationManager.scheduleReminders(for: tracker)
                }
            }
        } else {
            NotificationManager.removeReminders(for: tracker)
        }

        dismiss()
    }
}
