import SwiftUI

/// Animated XP / level bar. The fill is a pastel rainbow gradient; the bar
/// springs into place whenever `value` changes.
struct XPBar: View {
    var value: Double                       // 0…1
    var label: String
    var trailingLabel: String? = nil
    var height: CGFloat = 14

    @State private var renderedValue: Double = 0

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(label)
                    .font(.cozyCaption)
                    .foregroundStyle(Theme.Palette.textSoft)

                Spacer()

                if let trailingLabel {
                    Text(trailingLabel)
                        .font(.cozyCaption)
                        .foregroundStyle(Theme.Palette.text)
                }
            }

            GeometryReader { proxy in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Theme.Palette.text.opacity(0.07))

                    Capsule()
                        .fill(Theme.Gradients.xpBar)
                        .frame(width: max(8, proxy.size.width * renderedValue))
                        .overlay(
                            Capsule()
                                .stroke(.white.opacity(0.6), lineWidth: 1)
                                .blendMode(.overlay)
                        )
                        .shadow(color: Theme.Palette.coral.opacity(0.45),
                                radius: 8, x: 0, y: 4)
                }
            }
            .frame(height: height)
        }
        .onAppear { animate(to: value) }
        .onChange(of: value) { _, new in animate(to: new) }
    }

    private func animate(to v: Double) {
        withAnimation(Theme.Motion.spring) {
            renderedValue = min(max(v, 0), 1)
        }
    }
}
