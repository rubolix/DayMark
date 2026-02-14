import SwiftUI

struct ProfileCard: View {
    let profile: Profile

    var body: some View {
        HStack {
            ProfileIcon(emoji: profile.emoji, photoData: profile.photoData, colorHex: profile.colorHex, size: 40)
            Text(profile.name)
                .font(.headline)
            Spacer()
            let active = profile.trackers.filter { !$0.isArchived }
            Text("\(active.count) tracker\(active.count == 1 ? "" : "s")")
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
