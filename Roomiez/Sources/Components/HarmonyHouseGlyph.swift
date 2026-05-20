import SwiftUI

/// Custom house silhouette whose four windows light up based on the
/// household's harmony score. Replaces the circular harmony ring on the
/// home page hero — feels like a home rather than a fitness app.
struct HarmonyHouseGlyph: View {
    var harmony: Double                    // 0...1
    var size: CGFloat = 100
    var bodyFill: Color   = Color.white.opacity(0.22)
    var strokeColor: Color = Color.white.opacity(0.70)
    var doorColor: Color   = Color.white.opacity(0.35)
    var windowLit: Color   = Color(hex: "FFE17A")   // warm lamp glow
    var windowDim: Color   = Color.white.opacity(0.22)

    private let windowCount = 4
    private var litCount: Int {
        let v = Int((harmony * Double(windowCount)).rounded())
        return max(0, min(windowCount, v))
    }

    var body: some View {
        ZStack {
            HouseShape()
                .fill(bodyFill)
            HouseShape()
                .stroke(strokeColor, lineWidth: 2.5)

            // Door — small rectangle bottom-center.
            GeometryReader { proxy in
                let w = proxy.size.width
                let h = proxy.size.height
                RoundedRectangle(cornerRadius: 1.5, style: .continuous)
                    .fill(doorColor)
                    .frame(width: w * 0.14, height: h * 0.18)
                    .position(x: w * 0.5, y: h * 0.85)

                // Four windows in a 2x2 grid on the body.
                let windowSize = w * 0.16
                let centerY    = h * 0.62
                let centerX    = w * 0.5
                let offset     = w * 0.16
                let positions: [(CGFloat, CGFloat)] = [
                    (centerX - offset, centerY - offset),
                    (centerX + offset, centerY - offset),
                    (centerX - offset, centerY + offset),
                    (centerX + offset, centerY + offset),
                ]

                ForEach(0..<windowCount, id: \.self) { idx in
                    let lit = idx < litCount
                    RoundedRectangle(cornerRadius: 2.5, style: .continuous)
                        .fill(lit ? windowLit : windowDim)
                        .overlay(
                            RoundedRectangle(cornerRadius: 2.5, style: .continuous)
                                .stroke(strokeColor.opacity(0.8), lineWidth: 1.2)
                        )
                        .frame(width: windowSize, height: windowSize)
                        .shadow(color: lit ? windowLit.opacity(0.5) : .clear,
                                radius: lit ? 4 : 0)
                        .position(x: positions[idx].0,
                                  y: positions[idx].1)
                }
            }
        }
        .frame(width: size, height: size)
    }
}

private struct HouseShape: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        let w = rect.width
        let h = rect.height
        let roofPeakY  = h * 0.06
        let bodyTopY   = h * 0.40
        let bodyBottomY = h * 0.96
        let leftX  = w * 0.08
        let rightX = w * 0.92
        let midX   = w * 0.50
        // Roof eaves slightly overhang the body.
        let eaveLeft  = w * 0.04
        let eaveRight = w * 0.96

        // Roof triangle
        p.move(to:  CGPoint(x: midX,     y: roofPeakY))
        p.addLine(to: CGPoint(x: eaveLeft,  y: bodyTopY))
        p.addLine(to: CGPoint(x: eaveRight, y: bodyTopY))
        p.closeSubpath()

        // Body rectangle (slightly inset under the eaves)
        p.addRect(CGRect(x: leftX,
                         y: bodyTopY,
                         width: rightX - leftX,
                         height: bodyBottomY - bodyTopY))

        return p
    }
}
