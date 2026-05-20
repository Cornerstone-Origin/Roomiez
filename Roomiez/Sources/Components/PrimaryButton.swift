import SwiftUI

/// Pill button with bouncy feedback. Two flavors: filled (default) + soft.
struct PrimaryButton: View {
    enum Style { case filled, soft, ghost }

    var title: String
    var icon: String? = nil
    var style: Style = .filled
    var tint: Color = Theme.Palette.coral
    var fullWidth: Bool = true
    var action: () -> Void

    var body: some View {
        Button {
            Haptics.tap()
            action()
        } label: {
            HStack(spacing: 8) {
                if let icon { Image(systemName: icon) }
                Text(title)
            }
            .font(.cozy(16, weight: .semibold))
            .padding(.horizontal, 22).padding(.vertical, 14)
            .frame(maxWidth: fullWidth ? .infinity : nil)
            .foregroundStyle(foreground)
            .background(background)
            .overlay(
                Capsule().stroke(borderColor, lineWidth: borderWidth)
            )
            .clipShape(Capsule())
            .floatingShadow()
        }
        .buttonStyle(.plain)
        .pressable(scale: 0.96)
    }

    private var foreground: Color {
        switch style {
        case .filled: .white
        case .soft:   Theme.Palette.text
        case .ghost:  Theme.Palette.text
        }
    }

    @ViewBuilder
    private var background: some View {
        switch style {
        case .filled:
            LinearGradient(
                colors: [tint, tint.opacity(0.85)],
                startPoint: .topLeading, endPoint: .bottomTrailing
            )
        case .soft:
            tint.opacity(0.22)
        case .ghost:
            Color.clear
        }
    }

    private var borderColor: Color {
        switch style {
        case .filled: .white.opacity(0.4)
        case .soft:   tint.opacity(0.35)
        case .ghost:  Theme.Palette.text.opacity(0.18)
        }
    }
    private var borderWidth: CGFloat {
        style == .ghost ? 1.5 : 0.5
    }
}
