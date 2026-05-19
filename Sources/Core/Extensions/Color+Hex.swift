import SwiftUI

extension Color {
    /// `Color(hex: "F4B6C2")` — supports 6 or 8 (RGBA) digit hex.
    init(hex: String) {
        let cleaned = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var value: UInt64 = 0
        Scanner(string: cleaned).scanHexInt64(&value)

        let r, g, b, a: Double
        switch cleaned.count {
        case 6:
            r = Double((value & 0xFF0000) >> 16) / 255
            g = Double((value & 0x00FF00) >> 8)  / 255
            b = Double( value & 0x0000FF)        / 255
            a = 1
        case 8:
            r = Double((value & 0xFF000000) >> 24) / 255
            g = Double((value & 0x00FF0000) >> 16) / 255
            b = Double((value & 0x0000FF00) >> 8)  / 255
            a = Double( value & 0x000000FF)        / 255
        default:
            r = 1; g = 1; b = 1; a = 1
        }
        self = Color(.sRGB, red: r, green: g, blue: b, opacity: a)
    }

    /// Returns a darker version of the color by reducing HSB brightness.
    func darker(by amount: CGFloat = 0.18) -> Color {
        let ui = UIColor(self)
        var h: CGFloat = 0, s: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        ui.getHue(&h, saturation: &s, brightness: &b, alpha: &a)
        return Color(UIColor(hue: h,
                             saturation: s,
                             brightness: max(0, b - amount),
                             alpha: a))
    }

    /// Lighter via reduced saturation + slight brightness lift.
    func lighter(by amount: CGFloat = 0.18) -> Color {
        let ui = UIColor(self)
        var h: CGFloat = 0, s: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        ui.getHue(&h, saturation: &s, brightness: &b, alpha: &a)
        return Color(UIColor(hue: h,
                             saturation: max(0, s - amount),
                             brightness: min(1, b + amount * 0.3),
                             alpha: a))
    }
}
