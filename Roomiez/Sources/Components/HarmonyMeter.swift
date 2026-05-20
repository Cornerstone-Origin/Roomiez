import SwiftUI

/// Big circular harmony gauge.
struct HarmonyMeter: View {
    var harmony: Double                       // 0…1
    var size: CGFloat = 168
    var style: Style = .dark
    /// SF Symbol shown inside the ring. Defaults to the basic house;
    /// callers pass the current `HouseTier.icon` for level-aware flair.
    var icon: String = "house.fill"

    enum Style { case dark, light }

    @State private var rendered: Double = 0

    private var textColor: Color {
        style == .dark ? Theme.Palette.text : .white
    }
    private var textSoftColor: Color {
        style == .dark ? Theme.Palette.textSoft : .white.opacity(0.85)
    }
    private var trackColor: Color {
        style == .dark
            ? Theme.Palette.text.opacity(0.07)
            : .white.opacity(0.25)
    }

    // Scale inner elements so a 100pt or 168pt meter both look balanced.
    private var strokeWidth: CGFloat { min(size * 0.11, 14) }
    private var iconPt:      CGFloat { size * 0.16 }
    private var percentPt:   CGFloat { size * 0.20 }
    private var labelPt:     CGFloat { size * 0.085 }

    var body: some View {
        ZStack {
            Circle()
                .stroke(trackColor, lineWidth: strokeWidth)

            Circle()
                .trim(from: 0, to: rendered)
                .stroke(Theme.Gradients.harmony,
                        style: StrokeStyle(lineWidth: strokeWidth, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .shadow(color: Theme.Palette.coral.opacity(0.35),
                        radius: 10, x: 0, y: 6)

            VStack(spacing: size * 0.02) {
                Image(systemName: icon)
                    .font(.system(size: iconPt, weight: .bold))
                    .foregroundStyle(textColor.opacity(0.65))
                Text("\(Int(harmony * 100))%")
                    .font(.system(size: percentPt, weight: .bold, design: .rounded))
                    .foregroundStyle(textColor)
                    .minimumScaleFactor(0.7)
                    .lineLimit(1)
                Text("Harmony")
                    .font(.system(size: labelPt, weight: .medium, design: .rounded))
                    .foregroundStyle(textSoftColor)
            }
            .padding(.horizontal, strokeWidth * 1.2)
        }
        .frame(width: size, height: size)
        .onAppear { animate(to: harmony) }
        .onChange(of: harmony) { _, new in animate(to: new) }
    }

    private func animate(to v: Double) {
        withAnimation(Theme.Motion.spring) {
            rendered = min(max(v, 0), 1)
        }
    }
}
