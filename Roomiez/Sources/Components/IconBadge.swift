import SwiftUI

/// Rounded squircle holding an SF Symbol — the replacement for emoji
/// "icons" used on chore cards, grocery rows, achievement tiles, and the
/// activity feed. Three sizes via the `size` enum.
struct IconBadge: View {
    enum Size { case xs, sm, md, lg
        var box: CGFloat {
            switch self {
            case .xs: 26
            case .sm: 34
            case .md: 44
            case .lg: 56
            }
        }
        var glyph: CGFloat {
            switch self {
            case .xs: 12
            case .sm: 15
            case .md: 19
            case .lg: 26
            }
        }
        var radius: CGFloat {
            switch self {
            case .xs: 8
            case .sm: 11
            case .md: 14
            case .lg: 18
            }
        }
    }

    var systemName: String
    var tint: Color
    var size: Size = .md
    var style: Style = .soft

    enum Style { case soft, solid, outline }

    var body: some View {
        ZStack {
            switch style {
            case .soft:
                RoundedRectangle(cornerRadius: size.radius, style: .continuous)
                    .fill(tint.opacity(0.18))
                RoundedRectangle(cornerRadius: size.radius, style: .continuous)
                    .stroke(tint.opacity(0.30), lineWidth: 1)
            case .solid:
                // Glass-cushion background: white at the top, soft tint at
                // the bottom — lets the colourful icon sit on a clean
                // light surface like a sticker on glass.
                RoundedRectangle(cornerRadius: size.radius, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [Color.white, tint.opacity(0.22)],
                            startPoint: .top,
                            endPoint:   .bottom
                        )
                    )
                RoundedRectangle(cornerRadius: size.radius, style: .continuous)
                    .strokeBorder(.white.opacity(0.85), lineWidth: 1)
            case .outline:
                RoundedRectangle(cornerRadius: size.radius, style: .continuous)
                    .stroke(tint.opacity(0.55), lineWidth: 1.4)
            }

            iconImage
        }
        .frame(width: size.box, height: size.box)
        .shadow(color: shadowColor, radius: shadowRadius, x: 0, y: shadowY)
    }

    /// Multicolour SF Symbol for solid tiles; otherwise tint-coloured
    /// hierarchical glyph. Multicolour gives the "painted emoji" look —
    /// each symbol's native palette (green leaves, blue drops, orange
    /// flame, etc.) shines through.
    @ViewBuilder
    private var iconImage: some View {
        switch style {
        case .solid:
            Image(systemName: systemName)
                .symbolRenderingMode(.multicolor)
                .foregroundStyle(tint, tint.darker(by: 0.18))
                .font(.system(size: size.glyph + 2, weight: .semibold))
        case .soft, .outline:
            Image(systemName: systemName)
                .symbolRenderingMode(.hierarchical)
                .foregroundStyle(tint)
                .font(.system(size: size.glyph, weight: .semibold))
        }
    }

    private var shadowColor: Color {
        style == .solid ? tint.opacity(0.20) : .clear
    }
    private var shadowRadius: CGFloat {
        style == .solid ? 4 : 0
    }
    private var shadowY: CGFloat {
        style == .solid ? 2 : 0
    }
}

/// A small stat pill ("+12 XP", "Lv 3"). Replaces the old emoji "XP" badge.
struct StatPill: View {
    var label: String
    var systemImage: String? = nil
    var tint: Color = Theme.Palette.ochre

    var body: some View {
        HStack(spacing: 4) {
            if let systemImage {
                // Special-case the streak flame so every StatPill that
                // represents a streak (chore-card inline pill, leaderboard
                // rows, etc.) gets the animated fire treatment for free —
                // no caller-side changes needed.
                if systemImage == "flame.fill" {
                    AnimatedFlame(size: 10, renderMode: .monochrome, tint: tint)
                } else {
                    Image(systemName: systemImage)
                        .font(.system(size: 10, weight: .bold))
                }
            }
            Text(label)
                .font(.cozy(11, weight: .bold))
        }
        .padding(.horizontal, 9).padding(.vertical, 4)
        .foregroundStyle(tint)
        .background(
            Capsule().fill(tint.opacity(0.18))
        )
        .overlay(
            Capsule().stroke(tint.opacity(0.32), lineWidth: 0.5)
        )
    }
}
