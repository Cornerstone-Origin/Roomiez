import SwiftUI

/// Initials avatar — soft jewel-toned circle with a subtle two-stop
/// gradient and a thin contrast ring. Replaces the old emoji avatars.
struct AvatarView: View {
    var user: RoomieUser?
    var size: CGFloat = 36
    var showsRing: Bool = true

    private var tint: Color {
        user?.accent ?? Theme.Palette.indigo
    }
    private var initials: String {
        user?.initials ?? "·"
    }

    var body: some View {
        ZStack {
            Circle()
                .fill(
                    LinearGradient(
                        colors: [tint, tint.opacity(0.78)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

            // Subtle highlight crescent — gives the disc a soft 3D feel
            // without going into skeuomorphism.
            Circle()
                .trim(from: 0, to: 0.45)
                .stroke(.white.opacity(0.18), lineWidth: size * 0.06)
                .rotationEffect(.degrees(-140))
                .blur(radius: 0.5)

            Text(initials.prefix(2))
                .font(.system(size: size * 0.42,
                              weight: .bold,
                              design: .rounded))
                .kerning(-0.5)
                .foregroundStyle(.white)
        }
        .frame(width: size, height: size)
        .overlay(
            Group {
                if showsRing {
                    Circle().stroke(
                        Theme.Palette.background,
                        lineWidth: max(1.5, size * 0.06)
                    )
                }
            }
        )
        .shadow(color: tint.opacity(0.28),
                radius: size * 0.12,
                x: 0, y: size * 0.05)
    }
}

/// Stack of avatars overlapping, used in card footers.
struct AvatarStack: View {
    var users: [RoomieUser]
    var size: CGFloat = 28

    var body: some View {
        HStack(spacing: -size * 0.35) {
            ForEach(users.prefix(4)) { user in
                AvatarView(user: user, size: size)
            }
            if users.count > 4 {
                ZStack {
                    Circle().fill(Theme.Palette.indigo.opacity(0.18))
                    Circle().stroke(Theme.Palette.background, lineWidth: 2)
                    Text("+\(users.count - 4)")
                        .font(.cozyTag)
                        .foregroundStyle(Theme.Palette.indigo)
                }
                .frame(width: size, height: size)
            }
        }
    }
}
