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
                    .overlay(Circle().stroke(Theme.Palette.hairline, lineWidth: 1)).shadow(color: Color.black.opacity(0.08), radius: 4, x: 0, y: 2)
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
                    .overlay(Circle().stroke(Theme.Palette.hairline, lineWidth: 1)).shadow(color: Color.black.opacity(0.08), radius: 4, x: 0, y: 2)
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
                    .font(.cozyCaptionEmph)
                    .foregroundStyle(Theme.Palette.textSoft)
            }

            if vm.todaysChoresForMe.isEmpty {
                todayCaughtUp
            } else {
                VStack(spacing: 8) {
                    ForEach(vm.todaysChoresForMe) { chore in
                        TodayChoreRow(
                            chore: chore,
                            onComplete: { Task { await vm.completeChore(chore) } },
                            onMoveToInProgress: {
                                Task { await vm.moveToInProgress(chore) }
                            }
                        )
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
                    .font(.cozyAction)
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
                .shadow(color: Color.black.opacity(0.08), radius: 8, x: 0, y: 4)
        )
    }

    // MARK: - Hero (house details)

    private var heroCard: some View {
        let radius: CGFloat = 28
        let shape = RoundedRectangle(cornerRadius: radius, style: .continuous)

        return ZStack(alignment: .topLeading) {
            // Brighter, more saturated periwinkle gradient so the tile
            // stands out from the other section cards.
            LinearGradient(
                colors: [
                    Theme.Palette.periwinkle.opacity(0.45),
                    Theme.Palette.periwinkle.opacity(0.22)
                ],
                startPoint: .topLeading,
                endPoint:   .bottomTrailing
            )

            // Cozy decoration sits behind the content.
            CozyHomeBackdrop()

            // Illustrated tier-house watermark on the right — sits
            // below the XP bar so it doesn't overlap.
            VStack {
                Spacer().frame(height: 36)
                HStack {
                    Spacer()
                    HouseTierImage(level: appState.household.level,
                                   height: 92)
                        .padding(.trailing, 12)
                }
                Spacer(minLength: 0)
            }
            .allowsHitTesting(false)

            // Foreground content
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 8) {
                    Button {
                        Haptics.selection()
                        showingLevels = true
                    } label: {
                        Text("Lv \(appState.household.level)")
                            .font(.cozyBadge)
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
                    // Inline XP progress label so the bar actually
                    // communicates a number, not just a sliver of
                    // colour.
                    Text("\(appState.household.houseXP % 250) / 250")
                        .font(.cozyTag)
                        .monospacedDigit()
                        .foregroundStyle(Theme.Palette.text.opacity(0.65))
                }

                Text(appState.household.levelTitle)
                    .font(.cozy(22, weight: .heavy))
                    .foregroundStyle(Theme.Palette.text)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)

                Text(appState.household.tier.blurb)
                    .font(.cozyTag)
                    .foregroundStyle(Theme.Palette.textSoft)
                    .lineLimit(2)

                Spacer(minLength: 0)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(14)
            .frame(minHeight: 128)
        }
        .clipShape(shape)
        .overlay(
            shape.stroke(Theme.Palette.periwinkle.opacity(0.55),
                         lineWidth: 1.5)
        )
        .shadow(color: Theme.Palette.periwinkle.opacity(0.28),
                radius: 12, x: 0, y: 6)
        .shadow(color: Color.black.opacity(0.05),
                radius: 2, x: 0, y: 1)
    }

    /// Slim XP bar showing progress to the next house level. Bar only —
    /// no number labels.
    private var xpBar: some View {
        let progress = max(0, min(1, appState.household.levelProgress))
        return GeometryReader { proxy in
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(Color.white.opacity(0.6))
                    .overlay(Capsule().stroke(Color.white.opacity(0.55), lineWidth: 1))
                Capsule()
                    .fill(appState.household.tier.tint)
                    .frame(width: max(8, proxy.size.width * progress))
            }
        }
        .frame(height: 10)
    }

    // MARK: - House pulse

    private var pulseSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionHeader(title: "House pulse",
                          systemImage: "chart.bar.fill",
                          tint: Theme.Palette.marigold)

            highlightsCard

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
                // Use the first overdue chore's title as the "value"
                // line so the chip has the same shape (name + status)
                // as Top this week / Most consistent. The count is
                // captured in the secondary detail line.
                value: vm.overdueChores.isEmpty
                    ? "Nice."
                    : (vm.overdueChores.first?.title ?? "—"),
                detail: vm.overdueChores.isEmpty
                    ? "Nothing past due"
                    : (vm.overdueChores.count > 1
                        ? "+\(vm.overdueChores.count - 1) more"
                        : "1 chore")
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
                .font(.cozyActionStrong)
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
// Leaderboard merged into the Household section below — each
    // roommate row now carries this week's completion bar inline.

    /// List of overdue chores — only rendered when at least one exists.
    private var overdueCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Needs attention")
                .font(.cozyCaptionStrong)
                .foregroundStyle(Theme.Palette.textSoft)
                .padding(.horizontal, 4)

            VStack(spacing: 10) {
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

    /// Unified household roster — replaces the previous Roommates +
    /// Leaderboard split. Each row carries the member's name, title,
    /// level, streak, AND this week's completion bar. Sorted by
    /// weekly count so the most active person sits at the top.
    private var roommatesSection: some View {
        let counts = appState.members.map {
            (user: $0, count: vm.completedThisWeek(by: $0.id))
        }
        let sorted = counts.sorted { $0.count > $1.count }
        let maxCount = max(counts.map(\.count).max() ?? 1, 1)
        return VStack(alignment: .leading, spacing: 10) {
            SectionHeader(
                title: "Household",
                systemImage: "person.2.fill",
                tint: Theme.Palette.periwinkle,
                trailingTitle: "Invite",
                trailingAction: { showingInvite = true }
            )

            VStack(spacing: 10) {
                ForEach(sorted, id: \.user.id) { entry in
                    roommateRow(entry.user,
                                weeklyCount: entry.count,
                                maxCount: maxCount)
                }
            }
        }
    }

    private func roommateRow(_ user: RoomieUser,
                             weeklyCount: Int,
                             maxCount: Int) -> some View {
        let fraction = max(Double(weeklyCount) / Double(maxCount), 0.04)
        return HStack(spacing: 14) {
            AvatarView(user: user, size: 40)
            VStack(alignment: .leading, spacing: 4) {
                Text(user.displayName)
                    .font(.cozyAction)
                    .foregroundStyle(Theme.Palette.text)
                Text(user.levelTitle)
                    .font(.cozyCaption)
                    .foregroundStyle(Theme.Palette.textSoft)
                // Inline weekly progress (replaces the standalone
                // leaderboard card).
                HStack(spacing: 8) {
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(user.accent.opacity(0.20))
                            .frame(height: 5)
                        Capsule()
                            .fill(user.accent)
                            .frame(width: max(6, CGFloat(fraction) * 100),
                                   height: 5)
                    }
                    .frame(maxWidth: 100)
                    Text("\(weeklyCount) this wk")
                        .font(.cozyTag)
                        .foregroundStyle(Theme.Palette.textSoft)
                }
                .padding(.top, 2)
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
                .shadow(color: Color.black.opacity(0.08), radius: 8, x: 0, y: 4)
        )
    }

    // MARK: - Rules

    /// All house rules live in a single tile now — numbered rows
    /// separated by hairline dividers. Same info, ~half the vertical
    /// scroll, and the whole list reads as one container.
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
                rulesTile
            }
        }
    }

    private var rulesTile: some View {
        VStack(spacing: 0) {
            ForEach(Array(appState.household.rules.enumerated()), id: \.offset) { (index, rule) in
                ruleRow(index: index, text: rule)
                if index < appState.household.rules.count - 1 {
                    Divider()
                        .background(Theme.Palette.hairline)
                        // Align with the rule text so the divider
                        // sits to the right of the numbered badge.
                        .padding(.leading, 14 + 28 + 12)
                }
            }
        }
        .background(
            RoundedRectangle(cornerRadius: Theme.Radius.sm, style: .continuous)
                .fill(Theme.Palette.surface)
                .shadow(color: Color.black.opacity(0.08), radius: 8, x: 0, y: 4)
        )
    }

    private func ruleRow(index: Int, text: String) -> some View {
        HStack(alignment: .center, spacing: 12) {
            Text("\(index + 1)")
                .font(.cozyCaptionStrong)
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
        // No per-row background — the parent `rulesTile` provides
        // the shared white surface + shadow now.
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
                VStack(spacing: 10) {
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
                    .font(.cozyAction)
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
                .shadow(color: Color.black.opacity(0.08), radius: 8, x: 0, y: 4)
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
        VStack(spacing: 10) {
            ListItemRow(
                icon: icon, tint: tint,
                title: title, subtitle: subtitle,
                showsChevron: false
            )
        }
    }
}

// MARK: - Today chore row

/// One row in the home page's Today section. Mirrors `ChoreCard`'s
/// swipe pattern but slimmed for a flat list row: right-swipe past
/// the threshold marks the chore Done (with the same celebratory
/// completion animation), left-swipe moves it to In Progress. The
/// existing outlined check button on the trailing edge still works
/// — it shares the same `triggerComplete` path as the right-swipe.
private struct TodayChoreRow: View {
    let chore: Chore
    let onComplete: () -> Void
    let onMoveToInProgress: () -> Void

    @State private var completing = false
    @State private var dragOffset: CGFloat = 0

    var body: some View {
        let shape = RoundedRectangle(cornerRadius: Theme.Radius.sm,
                                     style: .continuous)
        return ZStack {
            swipeBackground(shape: shape)
            rowContent(shape: shape)
                .offset(x: dragOffset)
        }
        .simultaneousGesture(swipeGesture)
    }

    // MARK: Swipe pad

    @ViewBuilder
    private func swipeBackground(shape: RoundedRectangle) -> some View {
        if dragOffset > 0 {
            ZStack(alignment: .leading) {
                shape.fill(Theme.Palette.emerald)
                HStack(spacing: 8) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 20, weight: .bold))
                    Text("Done").font(.cozyChipStrong)
                }
                .foregroundStyle(.white)
                .padding(.leading, 18)
            }
            .transition(.opacity)
        } else if dragOffset < 0 {
            ZStack(alignment: .trailing) {
                shape.fill(Theme.Palette.marigold)
                HStack(spacing: 8) {
                    Text("In Progress").font(.cozyChipStrong)
                    Image(systemName: "timer")
                        .font(.system(size: 20, weight: .bold))
                }
                .foregroundStyle(.white)
                .padding(.trailing, 18)
            }
            .transition(.opacity)
        }
    }

    // MARK: Row content

    private func rowContent(shape: RoundedRectangle) -> some View {
        HStack(spacing: 12) {
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
                    .font(.cozyAction)
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
                    XPBadge(amount: chore.xpReward)
                }
            }

            Spacer()
        }
        .padding(.horizontal, 12).padding(.vertical, 10)
        .background(
            shape
                .fill(Theme.Palette.surface)
                .shadow(color: Color.black.opacity(0.08),
                        radius: 8, x: 0, y: 4)
        )
        .opacity(completing ? 0.4 : 1)
        .scaleEffect(completing ? 0.94 : 1)
        .overlay {
            if completing {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 48, weight: .bold))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Theme.Palette.emerald,
                                     Theme.Palette.marigold],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .transition(.scale.combined(with: .opacity))
            }
        }
    }

    // MARK: Gestures

    /// Drag gesture wired as a `simultaneousGesture` so vertical
    /// scrolls of the home page pass through. Same arbitration rule
    /// as the chore-page cards: only horizontal motion claims the
    /// gesture (`|dx| > |dy| * 1.5`).
    private var swipeGesture: some Gesture {
        DragGesture(minimumDistance: 15)
            .onChanged { value in
                guard !completing else { return }
                let dx = value.translation.width
                let dy = value.translation.height
                guard abs(dx) > abs(dy) * 1.5 else { return }
                let damped = dx.sign == .plus
                    ? min(dx, 160)
                    : max(dx, -160)
                dragOffset = damped
            }
            .onEnded { value in
                guard !completing else {
                    withAnimation(Theme.Motion.spring) { dragOffset = 0 }
                    return
                }
                let dx = value.translation.width
                let threshold: CGFloat = 80
                if dx > threshold {
                    triggerComplete()
                } else if dx < -threshold {
                    Haptics.selection()
                    withAnimation(Theme.Motion.spring) { dragOffset = 0 }
                    onMoveToInProgress()
                } else {
                    withAnimation(Theme.Motion.spring) { dragOffset = 0 }
                }
            }
    }

    /// Shared by the right-swipe and the trailing check button so
    /// both paths run the same haptic + animation + delayed action.
    private func triggerComplete() {
        guard !completing else { return }
        Haptics.success()
        withAnimation(Theme.Motion.bouncy) {
            completing = true
            dragOffset = 0
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.55) {
            onComplete()
        }
    }
}
