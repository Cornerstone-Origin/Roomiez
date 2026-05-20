import SwiftUI

/// The Roomiez brand mark — an angular "R" inside a softly rounded badge.
/// Used as the app's logo on the auth screen + anywhere we'd otherwise
/// show a household emoji.
struct RoomiezMark: View {
    var size: CGFloat = 92
    var cornerRadius: CGFloat { size * 0.32 }

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .fill(Theme.Gradients.logo)

            // Inner stroke — gives the mark a more crafted, etched feel.
            RoundedRectangle(cornerRadius: cornerRadius - 4, style: .continuous)
                .strokeBorder(.white.opacity(0.15), lineWidth: 1.2)
                .padding(6)

            RGlyph(strokeWidth: size * 0.085)
                .fill(.white)
                .padding(size * 0.22)
        }
        .frame(width: size, height: size)
        .compositingGroup()
        .shadow(color: Theme.Palette.brick.opacity(0.28),
                radius: 22, x: 0, y: 12)
    }
}

/// Custom "R" silhouette drawn as a path — playful proportions, geometric.
private struct RGlyph: Shape {
    var strokeWidth: CGFloat

    func path(in rect: CGRect) -> Path {
        let w  = rect.width
        let h  = rect.height
        let sw = strokeWidth
        let bowlH = h * 0.52
        let bowlRight = w * 0.92

        return Path { p in
            // Left vertical stem
            p.addRect(CGRect(x: 0, y: 0, width: sw, height: h))

            // Top bowl (filled half-pill)
            p.move(to: CGPoint(x: sw, y: 0))
            p.addLine(to: CGPoint(x: bowlRight - bowlH / 2, y: 0))
            p.addArc(center: CGPoint(x: bowlRight - bowlH / 2, y: bowlH / 2),
                     radius: bowlH / 2,
                     startAngle: .degrees(-90),
                     endAngle: .degrees(90),
                     clockwise: false)
            p.addLine(to: CGPoint(x: sw, y: bowlH))
            p.addLine(to: CGPoint(x: sw, y: bowlH - sw))
            p.addLine(to: CGPoint(x: bowlRight - bowlH / 2, y: bowlH - sw))
            p.addArc(center: CGPoint(x: bowlRight - bowlH / 2,
                                     y: bowlH / 2),
                     radius: bowlH / 2 - sw,
                     startAngle: .degrees(90),
                     endAngle: .degrees(-90),
                     clockwise: true)
            p.addLine(to: CGPoint(x: sw, y: sw))
            p.closeSubpath()

            // Diagonal leg
            let legTopX = w * 0.42
            let legTopY = bowlH - sw
            let legBottomX = w * 0.95
            let legBottomY = h
            p.move(to: CGPoint(x: legTopX, y: legTopY))
            p.addLine(to: CGPoint(x: legTopX + sw, y: legTopY))
            p.addLine(to: CGPoint(x: legBottomX, y: legBottomY))
            p.addLine(to: CGPoint(x: legBottomX - sw, y: legBottomY))
            p.closeSubpath()
        }
    }
}
