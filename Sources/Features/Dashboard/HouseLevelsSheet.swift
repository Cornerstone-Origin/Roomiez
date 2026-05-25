import SwiftUI

/// Modal that shows the full house-level ladder (10 tiers). Each row
/// shows the tier's icon, level, title, and blurb. The household's
/// current level is highlighted; higher levels appear locked but still
/// visible as a teaser.
struct HouseLevelsSheet: View {
    @Environment(\.dismiss) private var dismiss

    var currentLevel: Int

    var body: some View {
        ZStack {
            PearlBackground()

            ScrollView {
                VStack(alignment: .leading, spacing: Theme.Spacing.md) {
                    header
                    ForEach(LevelService.HouseTier.allCases, id: \.self) { tier in
                        row(tier)
                    }
                }
                .padding(.horizontal, Theme.Spacing.md)
                .padding(.top, Theme.Spacing.md)
                .padding(.bottom, 32)
            }
        }
    }

    // MARK: - Pieces

    private var header: some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 4) {
                Text("House levels")
                    .font(.cozyDisplay)
                    .foregroundStyle(Theme.Palette.text)
                Text("Earn XP together to climb the ladder.")
                    .font(.cozyCaption)
                    .foregroundStyle(Theme.Palette.textSoft)
            }
            Spacer()
            Button {
                Haptics.selection()
                dismiss()
            } label: {
                Text("Done")
                    .font(.cozyChipStrong)
                    .foregroundStyle(.white)
                    .padding(.horizontal, 16).padding(.vertical, 8)
                    .background(Capsule().fill(Theme.Palette.text))
            }
            .buttonStyle(.plain)
        }
        .padding(.bottom, 4)
    }

    private func row(_ tier: LevelService.HouseTier) -> some View {
        let lvl = tier.unlocksAtLevel
        let isCurrent = lvl == max(1, min(currentLevel, LevelService.HouseTier.allCases.count))
        let isLocked  = lvl > currentLevel

        return HStack(spacing: 14) {
            HouseTierImage(level: lvl, height: 56)
                .opacity(isLocked ? 0.4 : 1)

            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 8) {
                    Text("Lv \(lvl)")
                        .font(.cozyTag)
                        .foregroundStyle(isLocked
                                         ? Theme.Palette.textSoft
                                         : tier.tint)
                        .padding(.horizontal, 8).padding(.vertical, 2)
                        .overlay(
                            Capsule().stroke(
                                isLocked
                                    ? Theme.Palette.divider
                                    : tier.tint.opacity(0.55),
                                lineWidth: 1
                            )
                        )
                    Text(tier.title)
                        .font(.cozy(16, weight: .bold))
                        .foregroundStyle(isLocked
                                         ? Theme.Palette.textSoft
                                         : Theme.Palette.text)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                    if isCurrent {
                        Text("You're here")
                            .font(.cozyTag)
                            .foregroundStyle(.white)
                            .padding(.horizontal, 8).padding(.vertical, 2)
                            .background(Capsule().fill(tier.tint))
                    } else if isLocked {
                        Image(systemName: "lock.fill")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundStyle(Theme.Palette.textSoft.opacity(0.7))
                    }
                }
                Text(tier.blurb)
                    .font(.cozyCaption)
                    .foregroundStyle(Theme.Palette.textSoft)
                    .lineLimit(2)
            }
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 12).padding(.vertical, 12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: Theme.Radius.md, style: .continuous)
                .fill(Theme.Palette.surface)
        )
        .overlay(
            RoundedRectangle(cornerRadius: Theme.Radius.md, style: .continuous)
                .stroke(
                    isCurrent
                        ? tier.tint.opacity(0.55)
                        : Theme.Palette.divider,
                    lineWidth: isCurrent ? 1.5 : 1
                )
        )
    }
}
