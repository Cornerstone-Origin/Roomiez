import SwiftUI

/// "Home" tab — the household's own profile page.
/// House details (hero) · Roommates · House rules · Recent updates.
struct DashboardView: View {
    @EnvironmentObject private var appState: AppState
    @EnvironmentObject private var router: TabRouter
    @StateObject private var vm: DashboardViewModel

    @State private var showingInvite = false
    @State private var showingEditHousehold = false
    @State private var showingLevels = false
    @State private var showingHistory = false
    /// Chore currently animating its completion in the Today list.
    @State private var completingTodayId: UUID? = nil

    init(appState: AppState) {
        _vm = StateObject(wrappedValue: DashboardViewModel(appState: appState))
    }

    var body: some View {
        ZStack {
            PearlBackground()

            ScrollView {
                VStack(spacing: Theme.Spacing.lg) {
                    greetingHeader
                    heroCard
                    todaySection
                    pulseSection
                    roommatesSection
                    rulesSection
                    activitySection
                }
                .padding(.horizontal, Theme.Spacing.md)
                .padding(.top, Theme.Spacing.sm)
                .padding(.bottom, 120)
            }
            .refreshable { await vm.load() }
        }
        .task { await vm.load() }
        .sheet(isPresented: $showingInvite) {
            InviteRoomieSheet()
                .presentationDetents([.medium])
                .presentationCornerRadius(28)
        }
        .sheet(isPresented: $showingEditHousehold) {
            EditHouseholdSheet(
                household: appState.household,
                members: appState.members,
                currentUserId: appState.currentUser.id
            ) { updated in
                Task { await appState.updateHousehold(updated) }
            }
            .presentationDetents([.large])
            .presentationCornerRadius(28)
        }
        .sheet(isPresented: $showingLevels) {
            HouseLevelsSheet(currentLevel: appState.household.level)
                .presentationDetents([.large])
                .presentationCornerRadius(28)
        }
        .sheet(isPresented: $showingHistory) {
            HouseHistorySheet()
                .presentationDetents([.large])
                .presentationCornerRadius(28)
        }
    }

    // MARK: - Header

    private var greetingHeader: some View {
        HStack(alignment: .top, spacing: 10) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Your household")
                    .font(.cozyCaption)
                    .foregroundStyle(Theme.Palette.textSoft)
                Text(appState.household.name)
                    .font(.cozyDisplay)
                    .foregroundStyle(Theme.Palette.text)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }
            Spacer()
            Button {
                Haptics.selection()
                showingHistory = true
            } label: {
                Image(systemName: "clock.arrow.circlepath")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(Theme.Palette.text)
                    .frame(width: 32, height: 32)
                    .background(Circle().fill(Theme.Palette.surface))
                    .overlay(Circle().stroke(Theme.Palette.divider, lineWidth: 1))
            }
            .buttonStyle(.plain)
            Button {
                Haptics.selection()
                showingEditHousehold = true
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
        .padding(.top, 8)
    }

    // MARK: - Today (your chores, right at the top)

    private var todaySection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .firstTextBaseline) {
                Text("Today")
                    .font(.cozyTitle)
                    .foregroundStyle(Theme.Palette.text)
                Spacer()
                Text(todayDateLabel)
                    .font(.cozyCaption)
                    .foregroundStyle(Theme.Palette.textSoft)
            }

            if vm.todaysChoresForMe.isEmpty {
                todayCaughtUp
            } else {
                VStack(spacing: 8) {
                    ForEach(vm.todaysChoresForMe) { chore in
                        todayRow(chore)
                            .transition(.asymmetric(
                                insertion: .scale.combined(with: .opacity),
                                removal:   .move(edge: .leading).combined(with: .opacity)
                            ))
                    }
                }
                .animation(Theme.Motion.spring, value: vm.todaysChoresForMe)
            }
        }
    }

    private var todayDateLabel: String {
        let f = DateFormatter()
        f.dateFormat = "EEE, MMM d"
        return f.string(from: .now)
    }

    private func todayRow(_ chore: Chore) -> some View {
        let isCompleting = completingTodayId == chore.id
        return HStack(spacing: 12) {
            Image(systemName: chore.icon)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(chore.iconTint)
                .frame(width: 38, height: 38)
                .background(
                    RoundedRectangle(cornerRadius: Theme.Radius.sm,
                                     style: .continuous)
                        .fill(chore.iconTint.opacity(0.12))
                )

            VStack(alignment: .leading, spacing: 2) {
                Text(chore.title)
                    .font(.cozy(15, weight: .semibold))
                    .foregroundStyle(Theme.Palette.text)
                    .lineLimit(1)
                HStack(spacing: 6) {
                    if chore.isOverdue {
                        Label("Late", systemImage: "exclamationmark.triangle.fill")
                            .font(.cozyTag)
                            .foregroundStyle(Theme.Palette.rose)
                    } else if let due = chore.dueDate {
                        Label(due.friendlyShort(), systemImage: "calendar")
                            .font(.cozyTag)
                            .foregroundStyle(Theme.Palette.textSoft)
                    }
                    Text("+\(chore.xpReward) XP")
                        .font(.cozyTag)
                        .foregroundStyle(Theme.Palette.textSoft)
                }
            }

            Spacer()

            Button {
                guard !isCompleting else { return }
                Haptics.success()
                withAnimation(Theme.Motion.bouncy) {
                    completingTodayId = chore.id
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.55) {
                    Task {
                        await vm.completeChore(chore)
                        completingTodayId = nil
                    }
                }
            } label: {
                Image(systemName: "checkmark")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(Theme.Palette.forest)
                    .frame(width: 30, height: 30)
                    .background(Circle().fill(Theme.Palette.surface))
                    .overlay(Circle().stroke(
                        Theme.Palette.forest.opacity(0.55), lineWidth: 1.5))
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 12).padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: Theme.Radius.sm, style: .continuous)
                .fill(Theme.Palette.surface)
        )
        .overlay(
            RoundedRectangle(cornerRadius: Theme.Radius.sm, style: .continuous)
                .stroke(Theme.Palette.divider, lineWidth: 1)
        )
        .opacity(isCompleting ? 0.4 : 1)
        .scaleEffect(isCompleting ? 0.94 : 1)
        .overlay {
            if isCompleting {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 48, weight: .bold))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Theme.Palette.forest,
                                     Theme.Palette.marigold],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .transition(.scale.combined(with: .opacity))
            }
        }
    }

    private var todayCaughtUp: some View {
        HStack(spacing: 12) {
            Image(systemName: "sparkles")
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(Theme.Palette.marigold)
                .frame(width: 38, height: 38)
                .background(
                    RoundedRectangle(cornerRadius: Theme.Radius.sm,
                                     style: .continuous)
                        .fill(Theme.Palette.marigold.opacity(0.12))
                )
            VStack(alignment: .leading, spacing: 2) {
                Text("You're caught up")
                    .font(.cozy(15, weight: .semibold))
                    .foregroundStyle(Theme.Palette.text)
                Text("Nothing due for you today. Take a victory lap.")
                    .font(.cozyTag)
                    .foregroundStyle(Theme.Palette.textSoft)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            Spacer()
        }
        .padding(.horizontal, 12).padding(.vertical, 12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: Theme.Radius.sm, style: .continuous)
                .fill(Theme.Palette.surface)
        )
        .overlay(
            RoundedRectangle(cornerRadius: Theme.Radius.sm, style: .continuous)
                .stroke(Theme.Palette.divider, lineWidth: 1)
        )
    }

    // MARK: - Hero (house details)

    private var heroCard: some View {
        let radius: CGFloat = 28
        let shape = RoundedRectangle(cornerRadius: radius, style: .continuous)
        // Phase is re-computed each frame inside TimeOfDayBackdrop. We
        // also derive it here so the foreground text + stroke + shadow
        // match the sky's mood; refreshed every minute via TimelineView
        // so a viewer who lingers across a phase boundary sees the swap.
        return TimelineView(.everyMinute) { context in
            let phase = DayPhase(date: context.date)
            ZStack(alignment: .topLeading) {
                // Animated, time-of-day-aware atmosphere — sun, moon,
                // stars, clouds, embers, and matching hills.
                TimeOfDayBackdrop()

                // Illustrated tier-house watermark on the right — sits
                // below the XP bar so it doesn't overlap.
                VStack {
                    Spacer().frame(height: 50)
                    HStack {
                        Spacer()
                        HouseTierImage(level: appState.household.level,
                                       height: 110)
                            .padding(.trailing, 8)
                    }
                    Spacer(minLength: 0)
                }
                .allowsHitTesting(false)

                // Foreground content
                VStack(alignment: .leading, spacing: 10) {
                    HStack(spacing: 10) {
                        Button {
                            Haptics.selection()
                            showingLevels = true
                        } label: {
                            Text("Lv \(appState.household.level)")
                                .font(.cozy(12, weight: .bold))
                                .foregroundStyle(appState.household.tier.tint)
                                .padding(.horizontal, 10).padding(.vertical, 4)
                                .background(Capsule().fill(Color.white))
                                .overlay(
                                    Capsule().stroke(appState.household.tier.tint.opacity(0.45),
                                                     lineWidth: 1)
                                )
                        }
                        .buttonStyle(.plain)

                        xpBar
                    }

                    Text(appState.household.levelTitle)
                        .font(.cozy(22, weight: .heavy))
                        .foregroundStyle(phase.contentTint)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)

                    Text(appState.household.tier.blurb)
                        .font(.cozyTag)
                        .foregroundStyle(phase.subContentTint)
                        .lineLimit(2)

                    Spacer(minLength: 0)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(18)
                .frame(minHeight: 150)
            }
            .clipShape(shape)
            .overlay(
                shape.stroke(phase.accentColor.opacity(0.55),
                             lineWidth: 1.5)
            )
            .shadow(color: phase.accentColor.opacity(0.28),
                    radius: 12, x: 0, y: 6)
            .shadow(color: Color.black.opacity(0.05),
                    radius: 2, x: 0, y: 1)
        }
    }

    /// Slim XP bar showing progress to the next house level. Bar only —
    /// no number labels.
    private var xpBar: some View {
        let progress = max(0, min(1, appState.household.levelProgress))
        return GeometryReader { proxy in
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(Color.white.opacity(0.6))
                    .overlay(Capsule().stroke(Theme.Palette.divider, lineWidth: 1))
                Capsule()
                    .fill(appState.household.tier.tint)
                    .frame(width: max(6, proxy.size.width * progress))
            }
        }
        .frame(height: 8)
    }

    // MARK: - House pulse

    private var pulseSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionHeader(title: "House pulse",
                          systemImage: "chart.bar.fill",
                          tint: Theme.Palette.marigold)

            highlightsCard

            leaderboardCard

            if !vm.overdueChores.isEmpty {
                overdueCard
            }
        }
    }

    /// Three quick-glance chips: top performer · most consistent · overdue.
    private var highlightsCard: some View {
        HStack(spacing: 10) {
            highlightTile(
                icon: "star.fill",
                tint: Theme.Palette.marigold,
                title: "Top this week",
                value: topPerformer?.displayName ?? "—",
                detail: topPerformer.map { "\(vm.completedThisWeek(by: $0.id)) done" } ?? "Nothing yet"
            )
            highlightTile(
                icon: "flame.fill",
                tint: Theme.Palette.coral,
                title: "Most consistent",
                value: mostConsistent?.displayName ?? "—",
                detail: mostConsistent.map { "\($0.weeklyStreak)-day streak" } ?? "—"
            )
            highlightTile(
                icon: vm.overdueChores.isEmpty ? "checkmark.seal.fill" : "exclamationmark.triangle.fill",
                tint: vm.overdueChores.isEmpty ? Theme.Palette.mint : Theme.Palette.rose,
                title: vm.overdueChores.isEmpty ? "All caught up" : "Overdue",
                value: vm.overdueChores.isEmpty ? "Nice." : "\(vm.overdueChores.count)",
                detail: vm.overdueChores.isEmpty
                    ? "Nothing past due"
                    : "chore\(vm.overdueChores.count == 1 ? "" : "s")"
            )
        }
    }

    private func highlightTile(icon: String, tint: Color,
                               title: String, value: String,
                               detail: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(width: 20, height: 20)
                    .background(Circle().fill(tint))
                Text(title)
                    .font(.cozyTag)
                    .foregroundStyle(Theme.Palette.textSoft)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }
            Text(value)
                .font(.cozy(15, weight: .bold))
                .foregroundStyle(Theme.Palette.text)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            Text(detail)
                .font(.cozyTag)
                .foregroundStyle(Theme.Palette.textSoft)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        .padding(.horizontal, 12).padding(.vertical, 12)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(
            RoundedRectangle(cornerRadius: Theme.Radius.sm, style: .continuous)
                .fill(Theme.Palette.surface)
        )
        .overlay(
            RoundedRectangle(cornerRadius: Theme.Radius.sm, style: .continuous)
                .stroke(tint.opacity(0.35), lineWidth: 1)
        )
    }

    /// Member with the most completed chores this week (nil if tied at 0).
    private var topPerformer: RoomieUser? {
        let scored = appState.members.map {
            (user: $0, count: vm.completedThisWeek(by: $0.id))
        }
        guard let max = scored.max(by: { $0.count < $1.count }),
              max.count > 0 else { return nil }
        return max.user
    }

    /// Member with the highest weekly streak.
    private var mostConsistent: RoomieUser? {
        appState.members.max(by: { $0.weeklyStreak < $1.weeklyStreak })
    }

    /// Bar-chart-style leaderboard for this week's completions.
    private var leaderboardCard: some View {
        let sorted = appState.members.sorted {
            vm.completedThisWeek(by: $0.id) > vm.completedThisWeek(by: $1.id)
        }
        let maxCount = max(
            sorted.map { vm.completedThisWeek(by: $0.id) }.max() ?? 1,
            1
        )

        return VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("This week's leaderboard")
                    .font(.cozy(13, weight: .bold))
                    .foregroundStyle(Theme.Palette.textSoft)
                Spacer()
                Text("\(vm.totalCompletedThisWeek) total")
                    .font(.cozyTag)
                    .foregroundStyle(Theme.Palette.textSoft)
            }
            .padding(.horizontal, 4)

            ListCard {
                ForEach(sorted) { user in
                    leaderboardRow(
                        member: user,
                        count: vm.completedThisWeek(by: user.id),
                        maxCount: maxCount
                    )
                }
            }
        }
    }

    private func leaderboardRow(member: RoomieUser, count: Int, maxCount: Int) -> some View {
        let fraction = max(Double(count) / Double(maxCount), 0.04)
        return HStack(spacing: 12) {
            AvatarView(user: member, size: 32, showsRing: false)
            Text(member.displayName)
                .font(.cozy(14, weight: .semibold))
                .foregroundStyle(Theme.Palette.text)
                .frame(width: 70, alignment: .leading)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(member.accent.opacity(0.18))
                    .frame(height: 8)
                Capsule()
                    .fill(member.accent)
                    .frame(width: max(8, CGFloat(fraction) * 100),
                           height: 8)
            }
            .frame(maxWidth: .infinity)
            Text("\(count)")
                .font(.cozy(14, weight: .bold))
                .foregroundStyle(Theme.Palette.text)
                .frame(width: 22, alignment: .trailing)
        }
        .padding(.horizontal, 14).padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: Theme.Radius.sm, style: .continuous)
                .fill(Theme.Palette.surface)
        )
        .overlay(
            RoundedRectangle(cornerRadius: Theme.Radius.sm, style: .continuous)
                .stroke(Theme.Palette.divider, lineWidth: 1)
        )
    }

    /// List of overdue chores — only rendered when at least one exists.
    private var overdueCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Needs attention")
                .font(.cozy(13, weight: .bold))
                .foregroundStyle(Theme.Palette.textSoft)
                .padding(.horizontal, 4)

            ListCard {
                ForEach(Array(vm.overdueChores.prefix(4))) { chore in
                    ListItemRow(
                        icon: chore.icon,
                        tint: chore.iconTint,
                        title: chore.title,
                        subtitle: overdueSubtitle(chore),
                        showsChevron: false,
                        onTap: { router.go(.chores) }
                    )
                }
            }
        }
    }

    private func overdueSubtitle(_ chore: Chore) -> String {
        var parts: [String] = []
        if let due = chore.dueDate {
            parts.append("Was due \(due.friendlyShort())")
        }
        if let assignee = appState.member(id: chore.assigneeId) {
            parts.append(assignee.displayName)
        }
        return parts.joined(separator: " · ")
    }

    // MARK: - Roommates

    private var roommatesSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionHeader(
                title: "Roommates",
                systemImage: "person.2.fill",
                tint: Theme.Palette.periwinkle,
                trailingTitle: "Invite",
                trailingAction: { showingInvite = true }
            )

            ListCard {
                ForEach(appState.members) { user in
                    roommateRow(user)
                }
            }
        }
    }

    private func roommateRow(_ user: RoomieUser) -> some View {
        HStack(spacing: 14) {
            AvatarView(user: user, size: 40)
            VStack(alignment: .leading, spacing: 2) {
                Text(user.displayName)
                    .font(.cozy(15, weight: .semibold))
                    .foregroundStyle(Theme.Palette.text)
                Text(user.levelTitle)
                    .font(.cozyCaption)
                    .foregroundStyle(Theme.Palette.textSoft)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 4) {
                StatPill(label: "Lv \(user.level)",
                         systemImage: "sparkle",
                         tint: user.accent)
                StatPill(label: "\(user.weeklyStreak)",
                         systemImage: "flame.fill",
                         tint: Theme.Palette.coral)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: Theme.Radius.sm, style: .continuous)
                .fill(Theme.Palette.surface)
        )
        .overlay(
            RoundedRectangle(cornerRadius: Theme.Radius.sm, style: .continuous)
                .stroke(Theme.Palette.divider, lineWidth: 1)
        )
    }

    // MARK: - Rules

    private var rulesSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionHeader(
                title: "House rules",
                systemImage: "list.bullet.rectangle.fill",
                tint: Theme.Palette.coral
            )

            if appState.household.rules.isEmpty {
                emptyRow(icon: "list.bullet.rectangle.fill",
                         tint: Theme.Palette.coral,
                         title: "No rules yet",
                         subtitle: "House feels free for now.")
            } else {
                ListCard {
                    ForEach(Array(appState.household.rules.enumerated()), id: \.offset) { (index, rule) in
                        ruleRow(index: index, text: rule)
                    }
                }
            }
        }
    }

    private func ruleRow(index: Int, text: String) -> some View {
        HStack(alignment: .center, spacing: 12) {
            Text("\(index + 1)")
                .font(.cozy(13, weight: .bold))
                .foregroundStyle(.white)
                .frame(width: 28, height: 28)
                .background(
                    Circle().fill(
                        LinearGradient(
                            colors: [
                                Theme.Palette.coral,
                                Theme.Palette.coral.darker(by: 0.20)
                            ],
                            startPoint: .top, endPoint: .bottom
                        )
                    )
                )
            Text(text)
                .font(.cozyBody)
                .foregroundStyle(Theme.Palette.text)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: Theme.Radius.sm, style: .continuous)
                .fill(Theme.Palette.surface)
        )
        .overlay(
            RoundedRectangle(cornerRadius: Theme.Radius.sm, style: .continuous)
                .stroke(Theme.Palette.divider, lineWidth: 1)
        )
    }

    // MARK: - Activity (updates)

    private var activitySection: some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionHeader(title: "Recent updates",
                          systemImage: "tray.full.fill",
                          tint: Theme.Palette.azure)

            if appState.recentActivity.isEmpty {
                emptyRow(icon: "tray.full.fill",
                         tint: Theme.Palette.azure,
                         title: "Quiet on the home front",
                         subtitle: "Activity will show up here.")
            } else {
                ListCard {
                    ForEach(Array(appState.recentActivity.prefix(5))) { event in
                        activityRow(event)
                    }
                }
            }
        }
    }

    /// Activity-feed row using the chore-card flat icon recipe
    /// (rounded square, `tint.opacity(0.12)` fill, tint glyph).
    private func activityRow(_ event: ActivityEvent) -> some View {
        let tint = activityTint(for: event.kind)
        return HStack(spacing: 12) {
            Image(systemName: event.icon)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(tint)
                .frame(width: 38, height: 38)
                .background(
                    RoundedRectangle(cornerRadius: Theme.Radius.sm,
                                     style: .continuous)
                        .fill(tint.opacity(0.12))
                )
            VStack(alignment: .leading, spacing: 2) {
                Text(activityHeadline(event))
                    .font(.cozy(15, weight: .semibold))
                    .foregroundStyle(Theme.Palette.text)
                    .lineLimit(1)
                Text(event.createdAt.relative())
                    .font(.cozyCaption)
                    .foregroundStyle(Theme.Palette.textSoft)
                    .lineLimit(1)
            }
            Spacer()
            if event.xpDelta > 0 {
                XPBadge(amount: event.xpDelta)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: Theme.Radius.sm, style: .continuous)
                .fill(Theme.Palette.surface)
        )
        .overlay(
            RoundedRectangle(cornerRadius: Theme.Radius.sm, style: .continuous)
                .stroke(Theme.Palette.divider, lineWidth: 1)
        )
    }

    private func activityTint(for kind: ActivityKind) -> Color {
        switch kind {
        case .choreCompleted, .choreAdded, .choreAssigned: return Theme.Palette.mint
        case .groceryAdded, .groceryChecked:               return Theme.Palette.marigold
        case .noteAdded:                                   return Theme.Palette.coral
        case .achievementUnlocked, .levelUp:               return Theme.Palette.periwinkle
        case .streakSaved:                                 return Theme.Palette.rose
        case .levelDown:                                   return Theme.Palette.rose
        case .overduePenalty:                              return Theme.Palette.rose
        case .choreReverted:                               return Theme.Palette.coral
        }
    }

    private func activityHeadline(_ event: ActivityEvent) -> String {
        let who = appState.member(id: event.actorId)?.displayName ?? "Someone"
        switch event.kind {
        case .choreCompleted:      return "\(who) completed \(event.subject)"
        case .choreAdded:          return "\(who) added \(event.subject)"
        case .choreAssigned:       return "\(who) was assigned \(event.subject)"
        case .groceryAdded:        return "\(who) added \(event.subject)"
        case .groceryChecked:      return "\(who) checked off \(event.subject)"
        case .noteAdded:           return "\(who) posted \(event.subject)"
        case .achievementUnlocked: return "\(who) unlocked \(event.subject)"
        case .levelUp:             return "House leveled up — \(event.subject)"
        case .levelDown:           return "House dropped to \(event.subject)"
        case .streakSaved:         return "\(who) saved a streak"
        case .overduePenalty:      return "\(event.subject) went unfinished"
        case .choreReverted:       return "\(who) un-did \(event.subject)"
        }
    }

    // MARK: - Empty row helper

    private func emptyRow(icon: String, tint: Color,
                          title: String, subtitle: String) -> some View {
        ListCard {
            ListItemRow(
                icon: icon, tint: tint,
                title: title, subtitle: subtitle,
                showsChevron: false
            )
        }
    }
}
