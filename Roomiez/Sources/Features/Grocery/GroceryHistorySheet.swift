import SwiftUI

/// Modal listing every grocery item that's been checked off, with who
/// bought it and when. Sourced from the household activity feed
/// (`groceryChecked` events).
struct GroceryHistorySheet: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var appState: AppState

    private var entries: [ActivityEvent] {
        appState.recentActivity
            .filter { $0.kind == .groceryChecked }
            .sorted { $0.createdAt > $1.createdAt }
    }

    private var grouped: [(String, [ActivityEvent])] {
        let cal = Calendar.current
        let now = Date.now.startOfDay
        let yesterday = cal.date(byAdding: .day, value: -1, to: now)!
        let weekAgo  = cal.date(byAdding: .day, value: -7, to: now)!
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
        if !todayBucket.isEmpty      { out.append(("Today", todayBucket)) }
        if !yesterdayBucket.isEmpty  { out.append(("Yesterday", yesterdayBucket)) }
        if !weekBucket.isEmpty       { out.append(("Earlier this week", weekBucket)) }
        if !olderBucket.isEmpty      { out.append(("Older", olderBucket)) }
        return out
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
                Text("Bought history")
                    .font(.cozyDisplay)
                    .foregroundStyle(Theme.Palette.text)
                Text(entries.isEmpty
                     ? "Nothing checked off yet."
                     : "\(entries.count) item\(entries.count == 1 ? "" : "s") bought.")
                    .font(.cozyCaption)
                    .foregroundStyle(Theme.Palette.textSoft)
            }
            Spacer()
            Button {
                Haptics.selection()
                dismiss()
            } label: {
                Text("Done")
                    .font(.cozy(14, weight: .bold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 16).padding(.vertical, 8)
                    .background(Capsule().fill(Theme.Palette.text))
            }
            .buttonStyle(.plain)
        }
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
        let buyer = appState.member(id: event.actorId)
        return HStack(spacing: 12) {
            Image(systemName: event.icon)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(Theme.Palette.text)
                .frame(width: 38, height: 38)
                .background(
                    RoundedRectangle(cornerRadius: Theme.Radius.sm,
                                     style: .continuous)
                        .fill(Theme.Palette.divider.opacity(0.55))
                )

            VStack(alignment: .leading, spacing: 2) {
                Text(event.subject)
                    .font(.cozy(15, weight: .semibold))
                    .foregroundStyle(Theme.Palette.text)
                    .lineLimit(1)
                HStack(spacing: 4) {
                    Text(buyer?.displayName ?? "Someone")
                        .font(.cozyTag)
                        .foregroundStyle(Theme.Palette.text)
                    Text("·")
                        .font(.cozyTag)
                        .foregroundStyle(Theme.Palette.textSoft)
                    Text(event.createdAt.relative())
                        .font(.cozyTag)
                        .foregroundStyle(Theme.Palette.textSoft)
                }
                .lineLimit(1)
            }

            Spacer()

            if let buyer {
                AvatarView(user: buyer, size: 26, showsRing: false)
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

    private var emptyState: some View {
        VStack(spacing: 10) {
            Image(systemName: "checkmark.seal")
                .font(.system(size: 36, weight: .bold))
                .foregroundStyle(Theme.Palette.textSoft.opacity(0.6))
            Text("No items bought yet")
                .font(.cozyHeadline)
                .foregroundStyle(Theme.Palette.text)
            Text("Check items off your grocery list and they'll appear here with who bought them.")
                .font(.cozyCaption)
                .foregroundStyle(Theme.Palette.textSoft)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }
}
