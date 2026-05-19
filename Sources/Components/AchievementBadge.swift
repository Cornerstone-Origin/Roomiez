import SwiftUI

struct AchievementBadge: View {
    var achievement: Achievement
    var compact: Bool = false

    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [achievement.tint.opacity(0.95),
                                     achievement.tint.opacity(0.55)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .opacity(achievement.isUnlocked ? 1 : 0.35)

                Image(systemName: achievement.icon)
                    .font(.system(size: compact ? 28 : 38,
                                  weight: .semibold))
                    .foregroundStyle(.white)
                    .opacity(achievement.isUnlocked ? 1 : 0.55)
                    .scaleEffect(achievement.isUnlocked ? 1 : 0.85)

                if !achievement.isUnlocked {
                    Image(systemName: "lock.fill")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(.white.opacity(0.95))
                        .padding(8)
                        .background(Circle().fill(Theme.Palette.text.opacity(0.5)))
                        .offset(x: compact ? 18 : 24, y: compact ? 18 : 24)
                }
            }
            .frame(width: compact ? 64 : 96, height: compact ? 64 : 96)
            .shadow(color: achievement.tint.opacity(0.45),
                    radius: 12, x: 0, y: 6)

            VStack(spacing: 2) {
                Text(achievement.title)
                    .font(.cozyCaption)
                    .foregroundStyle(Theme.Palette.text)
                    .multilineTextAlignment(.center)
                if !compact {
                    Text(achievement.blurb)
                        .font(.cozyTag)
                        .foregroundStyle(Theme.Palette.textSoft)
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                }
            }
        }
        .frame(width: compact ? 100 : 140)
    }
}
