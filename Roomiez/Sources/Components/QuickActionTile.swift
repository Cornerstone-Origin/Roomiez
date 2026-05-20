import SwiftUI

/// Quick action tile — same look as a grocery category section header
/// scaled to a tile: tinted fill + hairline border, with a vibrant solid
/// IconBadge inside for the call-to-action.
struct QuickActionTile: View {
    /// SF Symbol name.
    var systemName: String
    var title: String
    var tint: Color
    var action: () -> Void

    private let radius: CGFloat = Theme.Radius.md

    private var shape: RoundedRectangle {
        RoundedRectangle(cornerRadius: radius, style: .continuous)
    }

    var body: some View {
        Button {
            Haptics.tap()
            action()
        } label: {
            VStack(spacing: 10) {
                IconBadge(systemName: systemName,
                          tint: tint,
                          size: .md,
                          style: .solid)
                Text(title)
                    .font(.cozy(13, weight: .semibold))
                    .foregroundStyle(Theme.Palette.text)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 18).padding(.horizontal, 8)
            .background(shape.fill(tint.opacity(0.18)))
            .overlay(shape.stroke(tint.opacity(0.35), lineWidth: 1))
            .clipShape(shape)
        }
        .buttonStyle(.plain)
        .pressable(scale: 0.95)
    }
}

/// Streak chip — soft Tomato fill + matching stroke so the streak
/// indicator reads as the primary brand colour rather than a grey
/// outline. The flame is animated (`AnimatedFlame`) so it actually
/// feels like a real fire: SF Symbols' variable-colour effect flickers
/// the inner gradient while a TimelineView wobble dances scale,
/// rotation, and lift.
struct StreakChip: View {
    var streak: Int
    var body: some View {
        HStack(spacing: 6) {
            AnimatedFlame(size: 12)
            Text("\(streak)-day streak")
                .font(.cozy(13, weight: .bold))
                .foregroundStyle(Theme.Palette.text)
        }
        .padding(.horizontal, 12).padding(.vertical, 7)
        .background(Capsule().fill(Theme.Palette.coral.opacity(0.12)))
        .overlay(Capsule().stroke(Theme.Palette.coral.opacity(0.40),
                                  lineWidth: 1))
    }
}
