import SwiftUI

/// Lightweight confetti — overlays the whole screen for a moment when something
/// great happens (chore completed, achievement unlocked).
struct ConfettiView: View {
    var pieces: Int = 60
    @State private var animate = false

    var body: some View {
        GeometryReader { proxy in
            ZStack {
                ForEach(0..<pieces, id: \.self) { i in
                    let x = CGFloat.random(in: 0...proxy.size.width)
                    let dy = CGFloat.random(in: 280...proxy.size.height + 80)
                    let color = Theme.Palette.pastels.randomElement() ?? Theme.Palette.coral
                    let delay = Double(i) * 0.012
                    let size = CGFloat.random(in: 6...11)
                    let rot = Double.random(in: 0...360)

                    RoundedRectangle(cornerRadius: 2, style: .continuous)
                        .fill(color)
                        .frame(width: size, height: size * 1.6)
                        .position(x: x, y: animate ? dy : -40)
                        .rotationEffect(.degrees(animate ? rot + 360 : rot))
                        .opacity(animate ? 0 : 1)
                        .animation(
                            .easeOut(duration: 1.4).delay(delay),
                            value: animate
                        )
                }
            }
            .onAppear { animate = true }
            .allowsHitTesting(false)
        }
        .ignoresSafeArea()
    }
}

/// Reusable success popup — icon medallion + confetti burst.
struct CelebrationOverlay: View {
    var title: String
    var message: String
    /// SF Symbol name shown inside the medallion.
    var systemName: String = "checkmark.seal.fill"
    var tint: Color = Theme.Palette.forest

    var body: some View {
        ZStack {
            Color.black.opacity(0.18).ignoresSafeArea()
            ConfettiView()

            VStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(colors: [tint, tint.opacity(0.7)],
                                           startPoint: .topLeading,
                                           endPoint: .bottomTrailing)
                        )
                        .frame(width: 84, height: 84)
                        .shadow(color: tint.opacity(0.45),
                                radius: 18, x: 0, y: 8)
                    Image(systemName: systemName)
                        .font(.system(size: 38, weight: .bold))
                        .foregroundStyle(.white)
                }
                Text(title)
                    .font(.cozyTitle)
                    .foregroundStyle(Theme.Palette.text)
                    .multilineTextAlignment(.center)
                Text(message)
                    .font(.cozyBody)
                    .foregroundStyle(Theme.Palette.textSoft)
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal, 32).padding(.vertical, 28)
            .background(
                RoundedRectangle(cornerRadius: Theme.Radius.lg, style: .continuous)
                    .fill(Theme.Palette.surface)
            )
            .cozyShadow()
            .padding(.horizontal, 28)
        }
        .transition(.opacity.combined(with: .scale(scale: 0.92)))
    }
}
