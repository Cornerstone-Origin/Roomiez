import SwiftUI

/// Large featured card with a colour gradient + soft decorative shapes.
/// Same shape language as the other dashboard cards (large radius,
/// gradient border, tinted lift shadow) — but inverted: bright gradient
/// fill with a white stroke instead of white fill with a tinted stroke.
struct HeroCard<Content: View>: View {
    var gradient: LinearGradient
    /// Hue used for the lift shadow — should match the gradient's dominant
    /// colour so the hero's "halo" feels part of the card pattern.
    var shadowTint: Color = Theme.Palette.coral
    var height: CGFloat = 200
    var radius: CGFloat = 28
    @ViewBuilder var content: () -> Content

    var body: some View {
        ZStack {
            gradient

            // Frosted shine across the top — light catching the glass.
            LinearGradient(
                colors: [
                    Color.white.opacity(0.55),
                    Color.white.opacity(0.0)
                ],
                startPoint: .top, endPoint: .center
            )
            .blendMode(.plusLighter)

            // Decorative translucent blobs — give the surface depth without
            // needing illustrations.
            Circle()
                .fill(Color.white.opacity(0.32))
                .frame(width: 160, height: 160)
                .offset(x: 110, y: -70)
                .blur(radius: 8)
            Circle()
                .fill(Color.white.opacity(0.18))
                .frame(width: 220, height: 220)
                .offset(x: -120, y: 90)
                .blur(radius: 12)

            content()
                .padding(22)
        }
        .frame(minHeight: height)
        .clipShape(RoundedRectangle(cornerRadius: radius, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: radius, style: .continuous)
                .strokeBorder(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(0.85),
                            Color.white.opacity(0.20)
                        ],
                        startPoint: .top, endPoint: .bottom
                    ),
                    lineWidth: 1.5
                )
        )
        .shadow(color: shadowTint.opacity(0.28), radius: 16, x: 0, y: 10)
        .shadow(color: Color.black.opacity(0.06), radius: 2, x: 0, y: 1)
    }
}
