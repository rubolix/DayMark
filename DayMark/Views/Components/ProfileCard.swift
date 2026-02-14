import SwiftUI
import SwiftData

struct ProfileCard: View {
    let profile: Profile
    @Query private var allTrackers: [Tracker]

    private var activeCount: Int {
        allTrackers.filter { $0.profile?.persistentModelID == profile.persistentModelID && !$0.isArchived }.count
    }

    var body: some View {
        HStack {
            ProfileIcon(emoji: profile.emoji, photoData: profile.photoData, colorHex: profile.colorHex, size: 40)
            Text(profile.name)
                .font(.headline)
            Spacer()
            Text("\(activeCount) tracker\(activeCount == 1 ? "" : "s")")
                .font(.caption)
                .foregroundStyle(.secondary)
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .padding()
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color(hex: profile.colorHex).opacity(0.4), lineWidth: 1.5)
        )
    }
}
