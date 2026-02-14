import SwiftUI

struct AddTrackerView: View {
    let subject: Subject
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var name = ""
    @State private var type: TrackerType = .scale
    @State private var scaleMin = 1
    @State private var scaleMax = 5
    @State private var unit = ""
    @State private var selectedColor = JewelColors.options[1].hex

    var body: some View {
        NavigationStack {
            Form {
                Section("What are you tracking?") {
                    TextField("e.g., Irritability, Water Intake", text: $name)
                }

                Section("Type") {
                    Picker("Type", selection: $type) {
                        ForEach(TrackerType.allCases, id: \.self) { t in
                            Text(t.rawValue).tag(t)
                        }
                    }
                    .pickerStyle(.segmented)
                }

                if type == .scale {
                    Section("Scale Range") {
                        Stepper("Minimum: \(scaleMin)", value: $scaleMin, in: 0...scaleMax - 1)
                        Stepper("Maximum: \(scaleMax)", value: $scaleMax, in: scaleMin + 1...100)
                    }
                }

                if type == .count {
                    Section("Unit (optional)") {
                        TextField("e.g., glasses, minutes, miles", text: $unit)
                    }
                }

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

                Section {
                    previewSection
                }
            }
            .navigationTitle("Add Tracker")
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

    @ViewBuilder
    private var previewSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Preview")
                .font(.caption)
                .foregroundStyle(.secondary)
            HStack {
                Circle()
                    .fill(Color(hex: selectedColor))
                    .frame(width: 12, height: 12)
                Text(name.isEmpty ? "Tracker Name" : name)
                    .font(.body)
                Spacer()
                Text(type.rawValue)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            switch type {
            case .scale:
                Text("Range: \(scaleMin) – \(scaleMax)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            case .yesNo:
                Text("Yes or No each day")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            case .count:
                Text("Log a number\(unit.isEmpty ? "" : " in \(unit)")")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private func save() {
        let tracker = Tracker(
            name: name.trimmingCharacters(in: .whitespaces),
            type: type,
            scaleMin: scaleMin,
            scaleMax: scaleMax,
            unit: unit.trimmingCharacters(in: .whitespaces),
            colorHex: selectedColor
        )
        tracker.subject = subject
        modelContext.insert(tracker)
        dismiss()
    }
}
