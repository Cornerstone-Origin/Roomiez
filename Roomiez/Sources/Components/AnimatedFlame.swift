import SwiftUI

/// A flame.fill SF Symbol that actually feels alive.
///
/// Two layers of motion stacked on top of each other:
///   • `symbolEffect(.variableColor.iterative.reversing)` — SF Symbols'
///     built-in variable-colour ripple, designed for fire-like effects.
///     Parts of the flame layer fade in and out cyclically.
///   • A `TimelineView(.animation)`-driven wobble — small breathing
///     scale + slight rotation + tiny upward lift, each on a different
///     phase so the motion never looks robotic.
///
/// Used as the streak indicator across the app (`StreakChip`,
/// `StatPill` when its `systemImage` is `flame.fill`).
struct AnimatedFlame: View {
    /// Font size of the flame glyph.
    var size: CGFloat = 12
    var weight: Font.Weight = .bold
    /// Render mode. `.multicolor` paints the flame in its native red →
    /// orange → yellow palette (most fire-like). `.monochrome` uses the
    /// supplied `tint` instead — preserve brand cohesion in chips that
    /// are otherwise single-coloured.
    var renderMode: Mode = .multicolor
    /// Used only when `renderMode == .monochrome`.
    var tint: Color = Theme.Palette.coral
    /// Animation speed multiplier — higher = faster flicker. Default 1.
    var speed: Double = 1.0

    enum Mode { case multicolor, monochrome }

    var body: some View {
        TimelineView(.animation) { context in
            let t = context.date.timeIntervalSinceReferenceDate * speed
            // Three phase-shifted oscillators so scale / rotation / lift
            // never line up — the flame looks like it's dancing rather
            // than pulsing on a metronome.
            let omega = 6.4                                  // ~1 cycle / sec
            let s = sin(t * omega)
            let r = sin(t * omega + 1.1)
            let h = sin(t * omega + 2.3)

            flame
                .scaleEffect(1 + s * 0.07)
                .rotationEffect(.degrees(r * 3.0))
                .offset(y: -abs(h) * 0.9)
        }
    }

    @ViewBuilder
    private var flame: some View {
        let image = Image(systemName: "flame.fill")
            .font(.system(size: size, weight: weight))
            // SF Symbols' .variableColor effect ripples through the symbol's
            // layered shapes — on flame.fill that ripple reads as flicker.
            .symbolEffect(
                .variableColor.iterative.reversing,
                options: .repeating
            )

        switch renderMode {
        case .multicolor:
            image
                .symbolRenderingMode(.multicolor)
        case .monochrome:
            image
                .symbolRenderingMode(.monochrome)
                .foregroundStyle(tint)
        }
    }
}

#Preview {
    HStack(spacing: 24) {
        AnimatedFlame(size: 20)
        AnimatedFlame(size: 28, renderMode: .monochrome,
                      tint: Theme.Palette.coral)
        AnimatedFlame(size: 36, speed: 0.7)
    }
    .padding()
    .background(Theme.Palette.surface)
}
