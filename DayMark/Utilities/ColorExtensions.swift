import SwiftUI

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 6:
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(.sRGB, red: Double(r) / 255, green: Double(g) / 255, blue: Double(b) / 255, opacity: Double(a) / 255)
    }
}

struct JewelColors {
    struct ColorOption: Identifiable {
        let hex: String
        let name: String
        var id: String { hex }
    }

    static let options: [ColorOption] = [
        ColorOption(hex: "#6A4C93", name: "Amethyst"),
        ColorOption(hex: "#1982C4", name: "Sapphire"),
        ColorOption(hex: "#2A9D5C", name: "Emerald"),
        ColorOption(hex: "#B8436E", name: "Ruby"),
        ColorOption(hex: "#FFCA3A", name: "Topaz"),
        ColorOption(hex: "#FF595E", name: "Garnet"),
        ColorOption(hex: "#8AC926", name: "Peridot"),
        ColorOption(hex: "#C77DFF", name: "Lavender"),
        ColorOption(hex: "#E07A5F", name: "Coral"),
        ColorOption(hex: "#3D5A80", name: "Slate"),
        ColorOption(hex: "#F4845F", name: "Amber"),
        ColorOption(hex: "#48BFE3", name: "Aquamarine"),
    ]
}
