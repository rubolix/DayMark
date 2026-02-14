import SwiftUI

struct EditProfileView: View {
    let profile: Profile
    @Environment(\.dismiss) private var dismiss

    @State private var name: String
    @State private var emoji: String
    @State private var selectedColor: String

    private let emojiOptions = ["👤", "👩", "👨", "👧", "👦", "🐕", "🐈", "🐾", "👶", "🧑‍🦳", "🏠", "⭐️"]

    init(profile: Profile) {
        self.profile = profile
        _name = State(initialValue: profile.name)
        _emoji = State(initialValue: profile.emoji)
        _selectedColor = State(initialValue: profile.colorHex)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Name") {
                    TextField("Name", text: $name)
                }

                Section("Icon") {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 6), spacing: 12) {
                        ForEach(emojiOptions, id: \.self) { option in
                            Text(option)
                                .font(.title)
                                .padding(6)
                                .background(
                                    Circle()
                                        .fill(emoji == option ? Color(hex: selectedColor).opacity(0.3) : .clear)
                                )
                                .overlay(
                                    Circle()
                                        .stroke(emoji == option ? Color(hex: selectedColor) : .clear, lineWidth: 2)
                                )
                                .onTapGesture { emoji = option }
                        }
                    }
                    .padding(.vertical, 4)
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
            .navigationTitle("Edit Profile")
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
        profile.name = name.trimmingCharacters(in: .whitespaces)
        profile.emoji = emoji
        profile.colorHex = selectedColor
        dismiss()
    }
}
