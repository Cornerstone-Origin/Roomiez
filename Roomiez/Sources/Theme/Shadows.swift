import SwiftUI

extension View {
    /// Soft, warm card shadow — used by `CozyCard` and most surfaces.
    func cozyShadow(intensity: CGFloat = 1.0) -> some View {
        shadow(color: Color.black.opacity(0.05 * intensity),
               radius: 12 * intensity, x: 0, y: 6 * intensity)
        .shadow(color: Color(hex: "E8593A").opacity(0.10 * intensity),
                radius: 24 * intensity, x: 0, y: 14 * intensity)
    }

    /// Slightly lifted variant for floating action buttons / popovers.
    func floatingShadow() -> some View {
        shadow(color: Color.black.opacity(0.10),
               radius: 18, x: 0, y: 10)
    }
}
