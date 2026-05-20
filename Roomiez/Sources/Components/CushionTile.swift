import SwiftUI

/// Soft glass-cushion button. White surface with a gentle tint gradient
/// from top to bottom, a thin white inner stroke for the cushion highlight,
/// a coloured drop shadow, and an outlined SF Symbol in the tint colour.
/// Optional caption below.
struct CushionTile: View {
    /// Outlined SF Symbol name.
    var systemName: String
    var label: String? = nil
    var tint: Color
    var isActive: Bool = false
    var tileSize: CGFloat = 50
    var radius: CGFloat = 16
    var action: () -> Void = {}

    var body: some View {
        Button {
            Haptics.selection()
            action()
        } label: {
            VStack(spacing: 5) {
                ZStack {
                    // Cushion gradient: white at top, tinted at bottom.
                    RoundedRectangle(cornerRadius: radius, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color.white,
                                    tint.opacity(isActive ? 0.28 : 0.13)
                                ],
                                startPoint: .top,
                                endPoint:   .bottom
                            )
                        )

                    // Glossy inner highlight stroke.
                    RoundedRectangle(cornerRadius: radius, style: .continuous)
                        .strokeBorder(.white.opacity(0.85), lineWidth: 1)

                    // Outlined icon in the tint colour.
                    Image(systemName: systemName)
                        .font(.system(size: tileSize * 0.46,
                                      weight: isActive ? .semibold : .medium))
                        .foregroundStyle(tint)
                }
                .frame(width: tileSize, height: tileSize)
                .shadow(color: tint.opacity(isActive ? 0.28 : 0.18),
                        radius: 6, x: 0, y: 4)
                .shadow(color: Color.black.opacity(0.04),
                        radius: 1, x: 0, y: 1)
                .scaleEffect(isActive ? 1.02 : 1)
                .animation(Theme.Motion.spring, value: isActive)

                if let label {
                    Text(label)
                        .font(.cozy(10, weight: .semibold))
                        .foregroundStyle(
                            isActive ? Theme.Palette.text : Theme.Palette.textSoft
                        )
                }
            }
        }
        .buttonStyle(.plain)
        .pressable(scale: 0.92)
    }
}
