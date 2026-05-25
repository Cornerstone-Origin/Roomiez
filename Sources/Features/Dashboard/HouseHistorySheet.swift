import SwiftUI

/// Full XP / level-change history for the household. Lists every
/// activity event with the XP delta (positive or negative), who did it,
/// and when. Bucketed Today / Yesterday / This week / Older.
struct HouseHistorySheet: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var appState: AppState

    /// All events that move the house XP needle (or mark a level
    /// change), sorted newest first.
    private var entries: [ActivityEvent] {
        appState.recentActivity
            .filter { event in
                switch event.kind {
                case .levelUp, .levelDown:
                    return true
                default:
                    return event.xpDelta != 0
                }
            }
            .sorted { $0.createdAt > $1.createdAt }
    }

    private var grouped: [(String, [ActivityEvent])] {
        let cal = Calendar.current
        let today = Date.now.startOfDay
        let yesterday = cal.date(byAdding: .day, value: -1, to: today)!
        let weekAgo  = cal.date(byAdding: .day, value: -7, to: today)!
        var todayBucket:    [ActivityEvent] = []
        var yesterdayBucket:[ActivityEvent] = []
        var weekBucket:     [ActivityEvent] = []
        var olderBucket:    [ActivityEvent] = []
        for e in entries {
            if cal.isDateInToday(e.createdAt) {
                todayBucket.append(e)
            } else if e.createdAt >= yesterday {
                yesterdayBucket.append(e)
            } else if e.createdAt >= weekAgo {
                weekBucket.append(e)
            } else {
                olderBucket.append(e)
            }
        }
        var out: [(String, [ActivityEvent])] = []
        if !todayBucket.isEmpty     { out.append(("Today", todayBucket)) }
        if !yesterdayBucket.isEmpty { out.append(("Yesterday", yesterdayBucket)) }
        if !weekBucket.isEmpty      { out.append(("Earlier this week", weekBucket)) }
        if !olderBucket.isEmpty     { out.append(("Older", olderBucket)) }
        return out
    }

    /// Net XP change for everything visible. Used in the header.
    private var netDelta: Int {
        entries.reduce(0) { $0 + $1.xpDelta }
    }

    var body: some View {
        ZStack {
            PearlBackground()
            ScrollView {
                VStack(alignment: .leading, spacing: Theme.Spacing.md) {
                    header
                    if entries.isEmpty {
                        emptyState
                    } else {
                        ForEach(grouped, id: \.0) { (title, items) in
                            section(title: title, items: items)
                        }
                    }
                }
                .padding(.horizontal, Theme.Spacing.md)
                .padding(.top, Theme.Spacing.md)
                .padding(.bottom, 40)
            }
        }
    }

    // MARK: - Pieces

    private var header: some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 4) {
                Text("House history")
                    .font(.cozyDisplay)
                    .foregroundStyle(Theme.Palette.text)
                if entries.isEmpty {
                    Text("Nothing logged yet.")
                        .font(.cozyCaption)
                        .foregroundStyle(Theme.Palette.textSoft)
                } else {
                    HStack(spacing: 4) {
                        Text("Lv \(appState.household.level)")
                            .font(.cozyBadge)
                            .foregroundStyle(appState.household.tier.tint)
                            .padding(.horizontal, 8).padding(.vertical, 2)
                            .overlay(Capsule().stroke(
                                appState.household.tier.tint.opacity(0.45),
                                lineWidth: 1))
                        Text("·")
                            .foregroundStyle(Theme.Palette.textSoft)
                        Text(netLabel(netDelta))
                            .font(.cozyBadge)
                            .foregroundStyle(netDelta >= 0
                                             ? Theme.Palette.forest
                                             : Theme.Palette.rose)
                    }
                }
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
    }

    private func netLabel(_ value: Int) -> String {
        value >= 0 ? "+\(value) XP net" : "\(value) XP net"
    }

    private func section(title: String,
                         items: [ActivityEvent]) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.cozyTag)
                .foregroundStyle(Theme.Palette.textSoft)
                .padding(.horizontal, 4)

            ListCard {
                ForEach(items) { event in
                    row(event)
                }
            }
        }
    }

    private func row(_ event: ActivityEvent) -> some View {
        let actor = appState.member(id: event.actorId)
        let (icon, headline, tint) = display(for: event, actor: actor)
        let isLevel = event.kind == .levelUp || event.kind == .levelDown
        return HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(tint)
                .frame(width: 38, height: 38)
                .background(
                    RoundedRectangle(cornerRadius: Theme.Radius.sm,
                                     style: .continuous)
                        .fill(tint.opacity(0.12))
                )
            VStack(alignment: .leading, spacing: 2) {
                Text(headline)
                    .font(.cozyChip)
                    .foregroundStyle(Theme.Palette.text)
                    .lineLimit(2)
                Text(event.createdAt.relative())
                    .font(.cozyTag)
                    .foregroundStyle(Theme.Palette.textSoft)
                    .lineLimit(1)
            }
            Spacer()
            if isLevel {
                Image(systemName: event.kind == .levelUp
                      ? "arrow.up.right.circle.fill"
                      : "arrow.down.right.circle.fill")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundStyle(event.kind == .levelUp
                                     ? Theme.Palette.forest
                                     : Theme.Palette.rose)
            } else {
                xpDeltaPill(event.xpDelta)
            }
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
    }

    private func xpDeltaPill(_ delta: Int) -> some View {
        let positive = delta >= 0
        let color: Color = positive ? Theme.Palette.forest : Theme.Palette.rose
        let label = positive ? "+\(delta) XP" : "\(delta) XP"
        return Text(label)
            .font(.cozyTag)
            .lineLimit(1)
            .fixedSize(horizontal: true, vertical: false)
            .padding(.horizontal, 10).padding(.vertical, 5)
            .foregroundStyle(color)
            .background(Capsule().fill(Theme.Palette.surface))
            .overlay(Capsule().stroke(color.opacity(0.55), lineWidth: 1.2))
    }

    /// Returns the icon, headline string, and tint for an event row.
    private func display(for event: ActivityEvent,
                         actor: RoomieUser?) -> (String, String, Color) {
        let who = actor?.displayName ?? "Someone"
        switch event.kind {
        case .choreCompleted:
            return (event.icon, "\(who) completed \(event.subject)",
                    Theme.Palette.mint)
        case .choreAdded:
            return (event.icon, "\(who) added \(event.subject)",
                    Theme.Palette.mint)
        case .choreAssigned:
            return (event.icon, "\(who) was assigned \(event.subject)",
                    Theme.Palette.mint)
        case .choreReverted:
            return (event.icon, "\(who) un-did \(event.subject)",
                    Theme.Palette.coral)
        case .overduePenalty:
            return ("exclamationmark.triangle.fill",
                    "\(event.subject) — \(actor.map { "\($0.displayName) " } ?? "")didn't finish it",
                    Theme.Palette.rose)
        case .groceryAdded:
            return (event.icon, "\(who) added \(event.subject)",
                    Theme.Palette.marigold)
        case .groceryChecked:
            return (event.icon, "\(who) bought \(event.subject)",
                    Theme.Palette.marigold)
        case .noteAdded:
            return (event.icon, "\(who) posted \(event.subject)",
                    Theme.Palette.coral)
        case .achievementUnlocked:
            return (event.icon, "\(who) unlocked \(event.subject)",
                    Theme.Palette.periwinkle)
        case .streakSaved:
            return (event.icon, "\(who) saved a streak",
                    Theme.Palette.rose)
        case .levelUp:
            return (event.icon, "House leveled up — \(event.subject)",
                    Theme.Palette.forest)
        case .levelDown:
            return (event.icon, "House dropped to \(event.subject)",
                    Theme.Palette.rose)
        }
    }

    private var emptyState: some View {
        VStack(spacing: 10) {
            Image(systemName: "clock.arrow.circlepath")
                .font(.system(size: 36, weight: .bold))
                .foregroundStyle(Theme.Palette.textSoft.opacity(0.6))
            Text("No history yet")
                .font(.cozyHeadline)
                .foregroundStyle(Theme.Palette.text)
            Text("Finish chores, buy groceries, or miss a deadline — every XP move shows up here.")
                .font(.cozyCaption)
                .foregroundStyle(Theme.Palette.textSoft)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }
}
