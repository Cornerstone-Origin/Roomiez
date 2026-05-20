import SwiftUI

/// Decorative "cozy night" landscape that fills the home-page hero —
/// layered rolling hills along the bottom, a crescent moon glowing in
/// the top-right, and scattered tiny stars in between. Reads like a
/// peaceful view from the loft's window.
struct CozyHomeBackdrop: View {
    var body: some View {
        GeometryReader { proxy in
            let w = proxy.size.width
            let h = proxy.size.height

            ZStack {
                // Soft moon glow — radial gradient anchored top-right.
                RadialGradient(
                    colors: [
                        Color.white.opacity(0.45),
                        Color.white.opacity(0.0)
                    ],
                    center: UnitPoint(x: 0.85, y: 0.22),
                    startRadius: 0,
                    endRadius: 110
                )

                // Stars sprinkled across the upper-mid sky.
                star(at: CGPoint(x: w * 0.16, y: h * 0.12), size: 3,   opacity: 0.65)
                star(at: CGPoint(x: w * 0.34, y: h * 0.20), size: 4,   opacity: 0.80)
                star(at: CGPoint(x: w * 0.52, y: h * 0.08), size: 2.5, opacity: 0.55)
                star(at: CGPoint(x: w * 0.68, y: h * 0.35), size: 3,   opacity: 0.65)
                star(at: CGPoint(x: w * 0.46, y: h * 0.32), size: 2,   opacity: 0.50)
                star(at: CGPoint(x: w * 0.10, y: h * 0.36), size: 2.5, opacity: 0.55)
                star(at: CGPoint(x: w * 0.78, y: h * 0.10), size: 3.5, opacity: 0.75)
                twinkle(at: CGPoint(x: w * 0.26, y: h * 0.05), size: 9,
                         color: Theme.Palette.marigold.opacity(0.50))
                twinkle(at: CGPoint(x: w * 0.60, y: h * 0.22), size: 11,
                         color: Theme.Palette.marigold.opacity(0.55))

                // Three layered hills along the bottom — back to front.
                HillShape(peakRatio: 0.62, wave: 0.55)
                    .fill(Theme.Palette.periwinkle.opacity(0.42))
                HillShape(peakRatio: 0.74, wave: 0.45)
                    .fill(Theme.Palette.mint.opacity(0.55))
                HillShape(peakRatio: 0.86, wave: 0.50)
                    .fill(Theme.Palette.grass.opacity(0.70))
            }
        }
        .allowsHitTesting(false)
    }

    // MARK: - Pieces

    private func star(at pos: CGPoint,
                      size: CGFloat,
                      opacity: Double) -> some View {
        Circle()
            .fill(Color.white.opacity(opacity))
            .frame(width: size, height: size)
            .blur(radius: 0.4)
            .position(pos)
    }

    /// Slightly bigger four-pointed sparkle to mix with the round stars.
    private func twinkle(at pos: CGPoint, size: CGFloat, color: Color) -> some View {
        Image(systemName: "sparkle")
            .font(.system(size: size, weight: .bold))
            .foregroundStyle(color)
            .position(pos)
    }
}

// MARK: - Shapes

/// Rolling hill silhouette — a soft Bezier curve from corner to corner,
/// peaking in the middle. `peakRatio` controls how tall the hill is
/// (lower = taller). `wave` shifts the peak's x position.
private struct HillShape: Shape {
    var peakRatio: CGFloat
    var wave: CGFloat = 0.50

    func path(in rect: CGRect) -> Path {
        var p = Path()
        let w = rect.width
        let h = rect.height
        let peakY = h * peakRatio
        let peakX = w * wave

        p.move(to: CGPoint(x: 0, y: h))
        p.addLine(to: CGPoint(x: 0, y: peakY + 20))
        p.addCurve(
            to:        CGPoint(x: w, y: peakY + 10),
            control1:  CGPoint(x: peakX * 0.6, y: peakY - 28),
            control2:  CGPoint(x: w - (w - peakX) * 0.4, y: peakY + 32)
        )
        p.addLine(to: CGPoint(x: w, y: h))
        p.closeSubpath()
        return p
    }
}

/// Crescent moon shape — a circle with an offset circle cut out of it.
private struct CrescentMoonShape: Shape {
    func path(in rect: CGRect) -> Path {
        let r = min(rect.width, rect.height) * 0.5
        let cx = rect.midX
        let cy = rect.midY
        let offset = r * 0.32

        // Outer full circle.
        let outer = Path { p in
            p.addEllipse(in: CGRect(x: cx - r, y: cy - r,
                                    width: r * 2, height: r * 2))
        }
        // Inner cut-out circle, offset toward upper-right.
        let cutR = r * 0.92
        let inner = Path { p in
            p.addEllipse(in: CGRect(x: cx - cutR + offset,
                                    y: cy - cutR - offset * 0.4,
                                    width: cutR * 2, height: cutR * 2))
        }
        return outer.subtracting(inner)
    }
}
