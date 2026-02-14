import SwiftUI

struct EditTrackerView: View {
    let tracker: Tracker
    @Environment(\.dismiss) private var dismiss

    @State private var name: String
    @State private var scaleMin: Int
    @State private var scaleMax: Int
    @State private var unit: String
    @State private var selectedColor: String

    init(tracker: Tracker) {
        self.tracker = tracker
        _name = State(initialValue: tracker.name)
        _scaleMin = State(initialValue: tracker.scaleMin)
        _scaleMax = State(initialValue: tracker.scaleMax)
        _unit = State(initialValue: tracker.unit)
        _selectedColor = State(initialValue: tracker.colorHex)
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
        dismiss()
    }
}
