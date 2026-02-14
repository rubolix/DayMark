import SwiftUI

struct ProfileIcon: View {
    let emoji: String
    let photoData: Data?
    let colorHex: String
    var size: CGFloat = 40

    var body: some View {
        if let data = photoData, let uiImage = UIImage(data: data) {
            Image(uiImage: uiImage)
                .resizable()
                .scaledToFill()
                .frame(width: size, height: size)
                .clipShape(Circle())
        } else {
            Text(emoji)
                .font(.system(size: size * 0.6))
                .frame(width: size, height: size)
                .background(Color(hex: colorHex).opacity(0.2))
                .clipShape(Circle())
        }
    }
}
