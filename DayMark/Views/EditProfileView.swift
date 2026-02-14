import SwiftUI
import PhotosUI

struct EditProfileView: View {
    let profile: Profile
    @Environment(\.dismiss) private var dismiss

    @State private var name: String
    @State private var emoji: String
    @State private var selectedColor: String
    @State private var photoData: Data?
    @State private var selectedPhoto: PhotosPickerItem?

    private let emojiOptions = ["👤", "👩", "👨", "👧", "👦", "🐕", "🐈", "🐾", "👶", "🧑‍🦳", "🏠", "⭐️"]

    init(profile: Profile) {
        self.profile = profile
        _name = State(initialValue: profile.name)
        _emoji = State(initialValue: profile.emoji)
        _selectedColor = State(initialValue: profile.colorHex)
        _photoData = State(initialValue: profile.photoData)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Name") {
                    TextField("Name", text: $name)
                }

                Section {
                    HStack {
                        Spacer()
                        ProfileIcon(emoji: emoji, photoData: photoData, colorHex: selectedColor, size: 80)
                        Spacer()
                    }
                    .padding(.vertical, 4)

                    HStack {
                        PhotosPicker(selection: $selectedPhoto, matching: .images) {
                            Label("Choose Photo", systemImage: "photo.on.rectangle")
                        }
                        Spacer()
                        if photoData != nil {
                            Button("Remove Photo") {
                                photoData = nil
                                selectedPhoto = nil
                            }
                            .foregroundStyle(.red)
                        }
                    }
                } header: {
                    Text("Photo")
                } footer: {
                    Text("Upload a photo, or pick an emoji icon below.")
                }

                Section("Emoji Icon") {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 6), spacing: 12) {
                        ForEach(emojiOptions, id: \.self) { option in
                            Text(option)
                                .font(.title)
                                .padding(6)
                                .background(
                                    Circle()
                                        .fill(emoji == option && photoData == nil ? Color(hex: selectedColor).opacity(0.3) : .clear)
                                )
                                .overlay(
                                    Circle()
                                        .stroke(emoji == option && photoData == nil ? Color(hex: selectedColor) : .clear, lineWidth: 2)
                                )
                                .onTapGesture {
                                    emoji = option
                                    photoData = nil
                                    selectedPhoto = nil
                                }
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
            .onChange(of: selectedPhoto) {
                loadPhoto()
            }
        }
    }

    private func loadPhoto() {
        guard let item = selectedPhoto else { return }
        Task {
            if let data = try? await item.loadTransferable(type: Data.self) {
                if let uiImage = UIImage(data: data) {
                    let resized = resizeImage(uiImage, maxSize: 300)
                    photoData = resized.jpegData(compressionQuality: 0.8)
                }
            }
        }
    }

    private func resizeImage(_ image: UIImage, maxSize: CGFloat) -> UIImage {
        let scale = min(maxSize / image.size.width, maxSize / image.size.height, 1.0)
        let newSize = CGSize(width: image.size.width * scale, height: image.size.height * scale)
        let renderer = UIGraphicsImageRenderer(size: newSize)
        return renderer.image { _ in image.draw(in: CGRect(origin: .zero, size: newSize)) }
    }

    private func save() {
        profile.name = name.trimmingCharacters(in: .whitespaces)
        profile.emoji = emoji
        profile.colorHex = selectedColor
        profile.photoData = photoData
        dismiss()
    }
}
