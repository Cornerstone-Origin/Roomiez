import SwiftUI

struct AchievementsView: View {
    @EnvironmentObject private var appState: AppState
    @StateObject private var vm: GamificationViewModel

    init(appState: AppState) {
        _vm = StateObject(wrappedValue: GamificationViewModel(appState: appState))
    }

    private let columns = [
        GridItem(.flexible(), spacing: 14),
        GridItem(.flexible(), spacing: 14)
    ]

    var body: some View {
        ZStack {
            PearlBackground()

            ScrollView {
                VStack(alignment: .leading, spacing: Theme.Spacing.lg) {
                    header
                    leaderboardCard
                    achievementsGrid
                    cosmeticRewardsCard
                }
                .padding(.horizontal, Theme.Spacing.md)
                .padding(.vertical, Theme.Spacing.lg)
                .padding(.bottom, 80)
            }
        }
        .task { await vm.load() }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Trophy room")
                .font(.cozyDisplay)
                .foregroundStyle(Theme.Palette.text)
            Text("Earn cozy little badges for keeping the house happy.")
                .font(.cozyCaption)
                .foregroundStyle(Theme.Palette.textSoft)
        }
    }

    private var leaderboardCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "Household leaderboard",
                          systemImage: "chart.bar.fill",
                          tint: Theme.Palette.ochre)
            CozyCard(tint: Theme.Palette.amber, padding: 16) {
                VStack(spacing: 12) {
                    ForEach(Array(appState.members
                                    .sorted { $0.personalXP > $1.personalXP }
                                    .enumerated()), id: \.element.id) { (i, user) in
                        HStack(spacing: 12) {
                            Text(rank(i))
                                .font(.cozyChipStrong)
                                .foregroundStyle(Theme.Palette.text)
                                .frame(width: 28)
                            AvatarView(user: user, size: 36)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(user.displayName)
                                    .font(.cozyBody)
                                    .foregroundStyle(Theme.Palette.text)
                                Text(user.levelTitle)
                                    .font(.cozyTag)
                                    .foregroundStyle(Theme.Palette.textSoft)
                            }
                            Spacer()
                            Text("\(user.personalXP) XP")
                                .font(.cozyCaptionStrong)
                                .foregroundStyle(Theme.Palette.text)
                                .padding(.horizontal, 10).padding(.vertical, 5)
                                .background(Capsule().fill(Theme.Palette.surface))
                        }
                    }
                }
            }
        }
    }

    private func rank(_ i: Int) -> String {
        switch i {
        case 0:  return "1st"
        case 1:  return "2nd"
        case 2:  return "3rd"
        default: return "#\(i + 1)"
        }
    }

    private var achievementsGrid: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "Achievements",
                          systemImage: "trophy.fill",
                          tint: Theme.Palette.ochre)
            LazyVGrid(columns: columns, spacing: 18) {
                ForEach(vm.mergedCatalog()) { ach in
                    CozyCard(tint: ach.tint, padding: 16, radius: Theme.Radius.md) {
                        AchievementBadge(achievement: ach)
                    }
                }
            }
        }
    }

    private var cosmeticRewardsCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "Cosmetic rewards",
                          systemImage: "paintbrush.fill",
                          tint: Theme.Palette.indigo)
            CozyCard(tint: Theme.Palette.indigo) {
                VStack(alignment: .leading, spacing: 14) {
                    Text("Themes, profile borders, and avatar accents unlock as you and your roomies hit milestones.")
                        .font(.cozyCaption)
                        .foregroundStyle(Theme.Palette.textSoft)

                    HStack(spacing: 14) {
                        cosmeticTile("moonphase.waxing.crescent",
                                     "Dusk theme", tint: Theme.Palette.indigo,
                                     unlocked: true)
                        cosmeticTile("circle.hexagongrid.fill",
                                     "Studio ring", tint: Theme.Palette.brick,
                                     unlocked: appState.household.harmony > 0.6)
                        cosmeticTile("sparkle",
                                     "Gold accent", tint: Theme.Palette.ochre,
                                     unlocked: appState.household.level >= 3)
                    }
                }
            }
        }
    }

    private func cosmeticTile(_ systemName: String, _ title: String,
                              tint: Color, unlocked: Bool) -> some View {
        VStack(spacing: 8) {
            ZStack {
                Circle()
                    .fill(unlocked ? tint.opacity(0.18)
                                   : Theme.Palette.text.opacity(0.06))
                    .frame(width: 60, height: 60)
                Image(systemName: systemName)
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundStyle(unlocked ? tint
                                              : Theme.Palette.text.opacity(0.4))
                if !unlocked {
                    Image(systemName: "lock.fill")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(.white)
                        .padding(5)
                        .background(Circle().fill(Theme.Palette.text.opacity(0.55)))
                        .offset(x: 18, y: 18)
                }
            }
            Text(title)
                .font(.cozyTag)
                .foregroundStyle(Theme.Palette.text)
        }
        .frame(maxWidth: .infinity)
    }
}
