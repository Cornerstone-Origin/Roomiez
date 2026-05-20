import SwiftUI

/// What part of the day it is, used by the home hero to choose its sky
/// and atmosphere. Computed from the hour of `date`.
enum DayPhase: Hashable, CaseIterable {
    case morning, afternoon, evening, night

    init(date: Date = .now) {
        let hour = Calendar.current.component(.hour, from: date)
        switch hour {
        case 5..<12:  self = .morning
        case 12..<17: self = .afternoon
        case 17..<20: self = .evening
        default:      self = .night
        }
    }

    /// Friendly name for the phase. Could surface as a caption later.
    var label: String {
        switch self {
        case .morning:   "Morning"
        case .afternoon: "Afternoon"
        case .evening:   "Evening"
        case .night:     "Night"
        }
    }

    /// Sky gradient stops top → bottom for this phase.
    var skyColors: [Color] {
        switch self {
        case .morning:
            return [Color(hex: "FFD8C2"),   // peach top
                    Color(hex: "FFE9DE"),   // warm midband
                    Color(hex: "DCEAF7")]   // pale blue horizon
        case .afternoon:
            return [Color(hex: "B6DAF2"),   // bright sky blue
                    Color(hex: "DCEDF8"),   // soft mid sky
                    Color(hex: "FFF6E2")]   // golden horizon
        case .evening:
            return [Color(hex: "5A3E72"),   // dusky purple top
                    Color(hex: "E36685"),   // pink mid
                    Color(hex: "FF9E5E")]   // sunset orange horizon
        case .night:
            return [Color(hex: "0E1330"),   // near-black sky
                    Color(hex: "1F2A56"),   // indigo mid
                    Color(hex: "30457F")]   // deep blue horizon
        }
    }

    /// Reading-safe foreground tint for the hero text. Switches to white
    /// for the saturated evening / night skies.
    var contentTint: Color {
        switch self {
        case .night, .evening:    return .white
        case .morning, .afternoon: return Theme.Palette.text
        }
    }

    var subContentTint: Color {
        switch self {
        case .night, .evening:    return .white.opacity(0.80)
        case .morning, .afternoon: return Theme.Palette.textSoft
        }
    }

    /// Brand-aligned accent colour used for the hero stroke + shadow.
    var accentColor: Color {
        switch self {
        case .morning:   return Theme.Palette.coral
        case .afternoon: return Theme.Palette.azure
        case .evening:   return Theme.Palette.coral
        case .night:     return Theme.Palette.azure
        }
    }
}

/// Animated, time-of-day-aware backdrop for the home-page hero.
///
///   • **Morning**   — soft peach sky, rising sun glowing in the lower-right,
///                     white clouds drifting slowly, pastel hills.
///   • **Afternoon** — bright blue sky, bright sun top-left with halo, white
///                     clouds drifting faster, green hills.
///   • **Evening**   — sunset purple→pink→orange gradient, big warm sun low
///                     on the right, faint early stars, warm ember dust
///                     drifting upward, plum hills.
///   • **Night**     — deep indigo sky, crescent moon top-right with halo,
///                     many twinkling stars, dark silhouette hills.
///
/// Driven by a single `TimelineView(.animation)` so every moving element
/// shares the same frame clock. Phase is recomputed each frame from the
/// timeline's date, so a viewer crossing a phase boundary sees the scene
/// transition without the dashboard needing to refresh.
struct TimeOfDayBackdrop: View {
    /// Optional override (useful for previews and testing each phase).
    var phaseOverride: DayPhase? = nil

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 30.0)) { context in
            let date  = context.date
            let phase = phaseOverride ?? DayPhase(date: date)
            let t     = date.timeIntervalSinceReferenceDate

            GeometryReader { proxy in
                let w = proxy.size.width
                let h = proxy.size.height
                ZStack {
                    LinearGradient(colors: phase.skyColors,
                                   startPoint: .top, endPoint: .bottom)

                    celestialGlow(phase: phase, t: t, w: w, h: h)
                    starField(phase: phase, t: t, w: w, h: h)
                    celestialBody(phase: phase, t: t, w: w, h: h)
                    cloudLayer(phase: phase, t: t, w: w, h: h)
                    emberLayer(phase: phase, t: t, w: w, h: h)
                    hillsLayer(phase: phase)
                }
            }
        }
        .allowsHitTesting(false)
    }

    // MARK: - Layers

    /// Big radial glow centred on the sun or moon, slightly pulsing.
    private func celestialGlow(phase: DayPhase, t: TimeInterval,
                               w: CGFloat, h: CGFloat) -> some View {
        let p = glowParams(for: phase)
        let pulse = p.intensity + sin(t * 1.4) * 0.05
        return RadialGradient(
            colors: [p.color.opacity(pulse), p.color.opacity(0)],
            center: p.center,
            startRadius: 0,
            endRadius: p.radius
        )
        .frame(width: w, height: h)
    }

    private func glowParams(for phase: DayPhase)
        -> (center: UnitPoint, color: Color, intensity: Double, radius: CGFloat)
    {
        switch phase {
        case .morning:
            return (UnitPoint(x: 0.80, y: 0.78), Color(hex: "FFCE8F"), 0.55, 150)
        case .afternoon:
            return (UnitPoint(x: 0.22, y: 0.18), Color(hex: "FFE99E"), 0.50, 160)
        case .evening:
            return (UnitPoint(x: 0.78, y: 0.55), Color(hex: "FFB57A"), 0.70, 180)
        case .night:
            return (UnitPoint(x: 0.85, y: 0.22), .white,               0.32, 130)
        }
    }

    /// Sun (morning / afternoon / evening) or crescent moon (night),
    /// with a subtle scale pulse so it feels alive.
    @ViewBuilder
    private func celestialBody(phase: DayPhase, t: TimeInterval,
                               w: CGFloat, h: CGFloat) -> some View {
        let pulse = 1 + sin(t * 1.2) * 0.05

        switch phase {
        case .morning:
            Circle()
                .fill(LinearGradient(
                    colors: [Color(hex: "FFD78A"), Color(hex: "FF9466")],
                    startPoint: .top, endPoint: .bottom))
                .frame(width: 52, height: 52)
                .scaleEffect(pulse)
                .position(x: w * 0.80, y: h * 0.82)
                .opacity(0.92)

        case .afternoon:
            Circle()
                .fill(Color(hex: "FFE082"))
                .frame(width: 56, height: 56)
                .scaleEffect(pulse)
                .shadow(color: Color(hex: "FFE082").opacity(0.6), radius: 18)
                .position(x: w * 0.22, y: h * 0.20)

        case .evening:
            Circle()
                .fill(LinearGradient(
                    colors: [Color(hex: "FFA87A"), Color(hex: "E04A50")],
                    startPoint: .top, endPoint: .bottom))
                .frame(width: 70, height: 70)
                .scaleEffect(pulse)
                .shadow(color: Color(hex: "FF8C5C").opacity(0.7), radius: 24)
                .position(x: w * 0.78, y: h * 0.62)

        case .night:
            BackdropCrescent()
                .fill(Color(hex: "F1F2F8"))
                .frame(width: 44, height: 44)
                .shadow(color: .white.opacity(0.35), radius: 12)
                .scaleEffect(1 + sin(t * 0.9) * 0.02)
                .position(x: w * 0.85, y: h * 0.22)
        }
    }

    /// Twinkling stars — visible at full strength at night, faintly at
    /// dusk. Each star runs on its own phase-shifted sine so the field
    /// shimmers rather than blinking in unison.
    @ViewBuilder
    private func starField(phase: DayPhase, t: TimeInterval,
                           w: CGFloat, h: CGFloat) -> some View {
        if phase == .night || phase == .evening {
            let intensity: Double = phase == .night ? 1.0 : 0.50
            let stars: [(x: CGFloat, y: CGFloat, size: CGFloat, off: Double)] = [
                (0.10, 0.10, 2.0, 0.0),
                (0.18, 0.22, 3.0, 1.1),
                (0.32, 0.08, 2.5, 2.2),
                (0.45, 0.18, 2.0, 0.6),
                (0.58, 0.10, 3.5, 1.7),
                (0.66, 0.28, 2.0, 2.5),
                (0.30, 0.34, 2.0, 3.0),
                (0.50, 0.36, 3.0, 1.4),
                (0.12, 0.42, 2.5, 1.8),
                (0.92, 0.34, 2.5, 0.9),
                (0.74, 0.06, 2.0, 2.7),
                (0.05, 0.25, 2.0, 0.4),
            ]
            ForEach(0..<stars.count, id: \.self) { i in
                let s = stars[i]
                let tw = 0.4 + 0.6 * abs(sin(t * 1.6 + s.off))
                Circle()
                    .fill(Color.white.opacity(intensity * tw))
                    .frame(width: s.size, height: s.size)
                    .blur(radius: 0.3)
                    .position(x: w * s.x, y: h * s.y)
            }
        }
    }

    /// Two clouds drifting left → right across the upper sky. Skipped on
    /// evening / night so the sunset and the stars get clear sky.
    @ViewBuilder
    private func cloudLayer(phase: DayPhase, t: TimeInterval,
                            w: CGFloat, h: CGFloat) -> some View {
        if phase == .morning || phase == .afternoon {
            let baseSpeed: Double = phase == .afternoon ? 22 : 14   // px/sec
            let cloudW: CGFloat = 78
            let span = w + cloudW * 2
            let opacity: Double = phase == .afternoon ? 0.92 : 0.75

            let p1 = (t * baseSpeed).truncatingRemainder(dividingBy: span)
            let p2 = (t * baseSpeed * 0.7 + Double(span) * 0.5)
                        .truncatingRemainder(dividingBy: span)

            CloudShape()
                .fill(Color.white.opacity(opacity))
                .frame(width: cloudW, height: 22)
                .position(x: CGFloat(p1) - cloudW, y: h * 0.20)
            CloudShape()
                .fill(Color.white.opacity(opacity * 0.7))
                .frame(width: cloudW * 0.7, height: 18)
                .position(x: CGFloat(p2) - cloudW, y: h * 0.34)
        }
    }

    /// Warm ember dust drifting upward at evening — adds the sense of a
    /// summer-night bonfire breeze. Each ember runs on its own cycle so
    /// they don't lock-step.
    @ViewBuilder
    private func emberLayer(phase: DayPhase, t: TimeInterval,
                            w: CGFloat, h: CGFloat) -> some View {
        if phase == .evening {
            let embers: [(x: CGFloat, baseY: CGFloat, off: Double, dur: Double)] = [
                (0.15, 0.92, 0.0, 5.5),
                (0.35, 0.95, 1.6, 6.2),
                (0.50, 0.85, 0.9, 4.8),
                (0.62, 0.94, 2.4, 5.0),
                (0.88, 0.90, 1.3, 6.5),
            ]
            ForEach(0..<embers.count, id: \.self) { i in
                let e = embers[i]
                let cycle = ((t + e.off).truncatingRemainder(dividingBy: e.dur)) / e.dur
                let progress = CGFloat(cycle)
                let opacity = sin(cycle * .pi)   // fades in + out per cycle
                Circle()
                    .fill(Color(hex: "FFD08F").opacity(0.85 * opacity))
                    .frame(width: 4, height: 4)
                    .blur(radius: 1)
                    .position(
                        x: w * e.x,
                        y: h * (e.baseY - progress * 0.55)
                    )
            }
        }
    }

    /// Three layered rolling hills, recoloured per phase so the
    /// foreground matches the sky's mood.
    private func hillsLayer(phase: DayPhase) -> some View {
        let colors: [Color]
        switch phase {
        case .morning:
            colors = [
                Color(hex: "D8C5F2").opacity(0.55),
                Color(hex: "F0BBA8").opacity(0.65),
                Color(hex: "D4B89B").opacity(0.78),
            ]
        case .afternoon:
            colors = [
                Color(hex: "8FC3DC").opacity(0.55),
                Color(hex: "7FBF8B").opacity(0.65),
                Color(hex: "5FA66E").opacity(0.78),
            ]
        case .evening:
            colors = [
                Color(hex: "523660").opacity(0.65),
                Color(hex: "6E3956").opacity(0.78),
                Color(hex: "3D213A").opacity(0.90),
            ]
        case .night:
            colors = [
                Color(hex: "1B2447").opacity(0.85),
                Color(hex: "131A36").opacity(0.92),
                Color(hex: "0C1228"),
            ]
        }

        return ZStack {
            BackdropHill(peakRatio: 0.62, wave: 0.55).fill(colors[0])
            BackdropHill(peakRatio: 0.74, wave: 0.45).fill(colors[1])
            BackdropHill(peakRatio: 0.86, wave: 0.50).fill(colors[2])
        }
    }
}

// MARK: - Shapes (duplicated locally so this component doesn't depend on
// CozyHomeBackdrop's private types).

private struct BackdropHill: Shape {
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
            to:       CGPoint(x: w, y: peakY + 10),
            control1: CGPoint(x: peakX * 0.6, y: peakY - 28),
            control2: CGPoint(x: w - (w - peakX) * 0.4, y: peakY + 32)
        )
        p.addLine(to: CGPoint(x: w, y: h))
        p.closeSubpath()
        return p
    }
}

private struct BackdropCrescent: Shape {
    func path(in rect: CGRect) -> Path {
        let r = min(rect.width, rect.height) * 0.5
        let cx = rect.midX
        let cy = rect.midY
        let offset = r * 0.32

        let outer = Path { p in
            p.addEllipse(in: CGRect(x: cx - r, y: cy - r,
                                    width: r * 2, height: r * 2))
        }
        let cutR = r * 0.92
        let inner = Path { p in
            p.addEllipse(in: CGRect(x: cx - cutR + offset,
                                    y: cy - cutR - offset * 0.4,
                                    width: cutR * 2, height: cutR * 2))
        }
        return outer.subtracting(inner)
    }
}

private struct CloudShape: Shape {
    func path(in rect: CGRect) -> Path {
        // Three overlapping ellipses approximating a cartoon cloud.
        var p = Path()
        let w = rect.width
        let h = rect.height
        p.addEllipse(in: CGRect(x: w * 0.00, y: h * 0.30,
                                width: w * 0.55, height: h * 0.70))
        p.addEllipse(in: CGRect(x: w * 0.28, y: h * 0.00,
                                width: w * 0.50, height: h * 0.95))
        p.addEllipse(in: CGRect(x: w * 0.55, y: h * 0.25,
                                width: w * 0.45, height: h * 0.70))
        return p
    }
}

// MARK: - Previews

#Preview("Morning") {
    TimeOfDayBackdrop(phaseOverride: .morning)
        .frame(height: 200)
        .clipShape(RoundedRectangle(cornerRadius: 28))
        .padding()
}

#Preview("Afternoon") {
    TimeOfDayBackdrop(phaseOverride: .afternoon)
        .frame(height: 200)
        .clipShape(RoundedRectangle(cornerRadius: 28))
        .padding()
}

#Preview("Evening") {
    TimeOfDayBackdrop(phaseOverride: .evening)
        .frame(height: 200)
        .clipShape(RoundedRectangle(cornerRadius: 28))
        .padding()
}

#Preview("Night") {
    TimeOfDayBackdrop(phaseOverride: .night)
        .frame(height: 200)
        .clipShape(RoundedRectangle(cornerRadius: 28))
        .padding()
}
