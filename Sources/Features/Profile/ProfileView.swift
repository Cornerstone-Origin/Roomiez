import SwiftUI

struct ProfileView: View {
    @EnvironmentObject private var appState: AppState
    @EnvironmentObject private var auth: AuthService

    @State private var showingAchievements = false
    @State private var showingEditProfile = false

    var body: some View {
        ZStack {
            PearlBackground()

            ScrollView {
                VStack(spacing: Theme.Spacing.lg) {
                    profileCard
                    statsCard
                    householdCard
                    actionsCard
                }
                .padding(.horizontal, Theme.Spacing.md)
                .padding(.vertical, Theme.Spacing.lg)
                .padding(.bottom, 80)
            }
        }
        .sheet(isPresented: $showingAchievements) {
            NavigationStack { AchievementsView(appState: appState) }
                .presentationDetents([.large])
        }
        .sheet(isPresented: $showingEditProfile) {
            EditProfileSheet(
                user: appState.currentUser,
                unlockedTrophies: appState.unlockedAchievements
            ) { updated in
                Task { await appState.updateProfile(updated) }
            }
            .presentationDetents([.large])
            .presentationCornerRadius(28)
        }
    }

    // MARK: - Profile

    private var profileCard: some View {
        tile {
            VStack(spacing: 14) {
                ZStack(alignment: .topTrailing) {
                    AvatarView(user: appState.currentUser, size: 96)
                        .frame(maxWidth: .infinity)
                    Button {
                        Haptics.selection()
                        showingEditProfile = true
                    } label: {
                        Image(systemName: "pencil")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundStyle(Theme.Palette.text)
                            .frame(width: 32, height: 32)
                            .background(Circle().fill(Theme.Palette.surface))
                            .overlay(Circle().stroke(Theme.Palette.divider, lineWidth: 1))
                    }
                    .buttonStyle(.plain)
                }

                Text(appState.currentUser.displayName)
                    .font(.cozyTitle)
                    .foregroundStyle(Theme.Palette.text)
                Text(appState.currentUser.displayTitle)
                    .font(.cozyCaption)
                    .padding(.horizontal, 12).padding(.vertical, 4)
                    .overlay(Capsule().stroke(Theme.Palette.divider, lineWidth: 1))
                    .foregroundStyle(Theme.Palette.text)
                if let bio = appState.currentUser.bio, !bio.isEmpty {
                    Text(bio)
                        .font(.cozyCaption)
                        .foregroundStyle(Theme.Palette.textSoft)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 8)
                        .padding(.top, 2)
                }

                XPBar(
                    value: appState.currentUser.levelProgress,
                    label: "Lv \(appState.currentUser.level)",
                    trailingLabel: "\(appState.currentUser.personalXP) XP"
                )
                .padding(.top, 6)
            }
        }
    }

    // MARK: - Stats

    private var statsCard: some View {
        HStack(spacing: 10) {
            statTile(systemImage: "flame.fill",
                     value: "\(appState.currentUser.weeklyStreak)",
                     label: "Weekly streak",
                     tint: Theme.Palette.brick)
            statTile(systemImage: "heart.fill",
                     value: "\(Int(appState.household.harmony * 100))%",
                     label: "House harmony",
                     tint: Theme.Palette.forest)
            statTile(systemImage: "trophy.fill",
                     value: "\(appState.unlockedAchievements.count)",
                     label: "Trophies",
                     tint: Theme.Palette.ochre)
        }
    }

    private func statTile(systemImage: String, value: String,
                          label: String, tint: Color) -> some View {
        VStack(spacing: 8) {
            Image(systemName: systemImage)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(tint)
                .frame(width: 38, height: 38)
                .background(
                    RoundedRectangle(cornerRadius: Theme.Radius.sm,
                                     style: .continuous)
                        .fill(tint.opacity(0.12))
                )
            Text(value).font(.cozy(20, weight: .bold))
                .foregroundStyle(Theme.Palette.text)
            Text(label).font(.cozyTag)
                .foregroundStyle(Theme.Palette.textSoft)
                .multilineTextAlignment(.center)
        }
        .padding(.vertical, 16).padding(.horizontal, 8)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: Theme.Radius.md, style: .continuous)
                .fill(Theme.Palette.surface)
        )
        .overlay(
            RoundedRectangle(cornerRadius: Theme.Radius.md, style: .continuous)
                .stroke(Theme.Palette.divider, lineWidth: 1)
        )
    }

    // MARK: - Household

    private var householdCard: some View {
        tile {
            VStack(alignment: .leading, spacing: 14) {
                HStack(spacing: 8) {
                    Image(systemName: "house.fill")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(Theme.Palette.text)
                    Text("Your home").font(.cozyHeadline)
                        .foregroundStyle(Theme.Palette.text)
                    Spacer()
                    Text(appState.household.name)
                        .font(.cozyCaption)
                        .foregroundStyle(Theme.Palette.textSoft)
                }
                CozyDivider()
                ForEach(appState.members) { user in
                    HStack(spacing: 12) {
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
                        Text("Lv \(user.level)")
                            .font(.cozyCaption)
                            .padding(.horizontal, 8).padding(.vertical, 3)
                            .overlay(Capsule().stroke(Theme.Palette.divider, lineWidth: 1))
                            .foregroundStyle(Theme.Palette.text)
                    }
                }
            }
        }
    }

    /// White surface + hairline divider stroke — same recipe the chore
    /// cards use. Keeps every section visually consistent.
    @ViewBuilder
    private func tile<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        let shape = RoundedRectangle(cornerRadius: Theme.Radius.md,
                                     style: .continuous)
        ZStack {
            shape.fill(Theme.Palette.surface)
            content().padding(16)
        }
        .overlay(shape.stroke(Theme.Palette.divider, lineWidth: 1))
        .clipShape(shape)
    }

    // MARK: - Actions

    private var actionsCard: some View {
        VStack(spacing: 10) {
            PrimaryButton(title: "Trophy room",
                          icon: "trophy.fill",
                          style: .soft,
                          tint: Theme.Palette.amber) {
                showingAchievements = true
            }
            PrimaryButton(title: "Sign out",
                          icon: "rectangle.portrait.and.arrow.right",
                          style: .ghost,
                          tint: Theme.Palette.coral) {
                Task { await auth.signOut() }
            }
        }
    }
}

struct InviteRoomieSheet: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var appState: AppState

    var body: some View {
        VStack(spacing: 18) {
            Capsule()
                .fill(Theme.Palette.divider)
                .frame(width: 44, height: 5)
                .padding(.top, 8)

            Text("Invite a roomie")
                .font(.cozyTitle)
                .foregroundStyle(Theme.Palette.text)
            Text("Share this code with your roommates to join \(appState.household.name).")
                .font(.cozyCaption)
                .foregroundStyle(Theme.Palette.textSoft)
                .multilineTextAlignment(.center)

            Text(appState.household.inviteCode)
                .font(.cozy(28, weight: .bold))
                .padding(.horizontal, 22).padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: Theme.Radius.md, style: .continuous)
                        .fill(Theme.Palette.coral.opacity(0.4))
                )

            HStack(spacing: 10) {
                PrimaryButton(title: "Copy", icon: "doc.on.doc", style: .soft,
                              tint: Theme.Palette.coral) {
                    UIPasteboard.general.string = appState.household.inviteCode
                    Haptics.success()
                }
                PrimaryButton(title: "Done", style: .filled,
                              tint: Theme.Palette.teal) {
                    dismiss()
                }
            }
            .padding(.horizontal, 20)

            Spacer(minLength: 0)
        }
        .padding(.horizontal, 24).padding(.bottom, 24)
        .background(Theme.Palette.background.ignoresSafeArea())
    }
}
