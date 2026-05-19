import SwiftUI

struct ChoreCard: View {
    var chore: Chore
    var assignee: RoomieUser?
    var onMove: (ChoreStatus) -> Void
    var onTap: () -> Void

    @State private var showingStatusPicker = false
    @State private var completing = false

    var body: some View {
        let shape = RoundedRectangle(cornerRadius: Theme.Radius.md, style: .continuous)
        return Button {
            Haptics.tap()
            onTap()
        } label: {
            ZStack {
                shape.fill(Theme.Palette.surface)
                VStack(alignment: .leading, spacing: 8) {
                    HStack(alignment: .top, spacing: 10) {
                        Image(systemName: chore.icon)
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(chore.iconTint)
                            .frame(width: 38, height: 38)
                            .background(
                                RoundedRectangle(cornerRadius: Theme.Radius.sm,
                                                 style: .continuous)
                                    .fill(chore.iconTint.opacity(0.12))
                            )
                        VStack(alignment: .leading, spacing: 4) {
                            Text(chore.title)
                                .font(.cozyHeadline)
                                .foregroundStyle(Theme.Palette.text)
                                .lineLimit(2)
                            HStack(spacing: 6) {
                                if chore.isOverdue {
                                    LatePill()
                                }
                                PriorityChip(priority: chore.priority)
                                if chore.recurrence != .once {
                                    RecurrenceChip(recurrence: chore.recurrence)
                                }
                            }
                        }
                        Spacer()
                        XPBadge(amount: chore.xpReward)
                    }

                    HStack(spacing: 10) {
                        AvatarView(user: assignee, size: 26)
                        if let due = chore.dueDate {
                            Label(due.friendlyShort(), systemImage: "calendar")
                                .font(.cozyCaption)
                                .foregroundStyle(chore.isOverdue
                                                 ? Theme.Palette.brick
                                                 : Theme.Palette.textSoft)
                        }
                        if chore.streak > 1 {
                            StreakInline(streak: chore.streak)
                        }

                        Spacer()

                        statusMenu
                    }
                }
                .padding(12)
            }
            .overlay(shape.stroke(Theme.Palette.divider, lineWidth: 1))
            .clipShape(shape)
            .opacity(completing ? 0.4 : 1)
            .scaleEffect(completing ? 0.94 : 1)
            .overlay {
                if completing {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 64, weight: .bold))
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
        .buttonStyle(ChoreCardPressStyle())
    }

    /// Pill showing the chore's current status. Tap to open a popover
    /// styled like the chore tile — white surface, hairline stroke,
    /// themed rows. Picking a row moves the chore to that status.
    private var statusMenu: some View {
        Button {
            Haptics.selection()
            showingStatusPicker = true
        } label: {
            HStack(spacing: 6) {
                Image(systemName: chore.status.icon)
                    .font(.system(size: 13, weight: .bold))
                Text(chore.status.shortTitle)
                    .font(.cozy(13, weight: .bold))
                Image(systemName: "chevron.down")
                    .font(.system(size: 10, weight: .bold))
            }
            .foregroundStyle(chore.status.tint)
            .padding(.horizontal, 12).padding(.vertical, 8)
            .background(Capsule().fill(chore.status.tint.opacity(0.14)))
            .overlay(Capsule().stroke(chore.status.tint.opacity(0.45),
                                      lineWidth: 1))
        }
        .buttonStyle(.plain)
        .popover(isPresented: $showingStatusPicker,
                 attachmentAnchor: .point(.bottom),
                 arrowEdge: .top) {
            statusPickerContent
                .presentationCompactAdaptation(.popover)
        }
    }

    /// Popover body — three status rows in a card-themed container.
    private var statusPickerContent: some View {
        VStack(spacing: 4) {
            ForEach(ChoreStatus.allCases) { s in
                Button {
                    showingStatusPicker = false
                    if s != chore.status {
                        if s == .done {
                            Haptics.success()
                            withAnimation(Theme.Motion.bouncy) {
                                completing = true
                            }
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.55) {
                                onMove(s)
                            }
                        } else {
                            Haptics.selection()
                            onMove(s)
                        }
                    }
                } label: {
                    HStack(spacing: 10) {
                        Image(systemName: s.icon)
                            .font(.system(size: 13, weight: .bold))
                            .foregroundStyle(s.tint)
                            .frame(width: 18)
                        Text(s.title)
                            .font(.cozy(14, weight: .semibold))
                            .foregroundStyle(Theme.Palette.text)
                        Spacer()
                        if s == chore.status {
                            Image(systemName: "checkmark")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundStyle(s.tint)
                        }
                    }
                    .padding(.horizontal, 12).padding(.vertical, 10)
                    .frame(maxWidth: .infinity)
                    .background(
                        RoundedRectangle(cornerRadius: Theme.Radius.sm,
                                         style: .continuous)
                            .fill(
                                s == chore.status
                                    ? s.tint.opacity(0.12)
                                    : Color.clear
                            )
                    )
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
        }
        .padding(8)
        .frame(width: 200)
        .background(Theme.Palette.surface)
    }
}

/// Press style for the chore card — gives the scale-down feedback
/// without the simultaneous drag-gesture that `.pressable` uses (which
/// interferes with the parent ScrollView's vertical drag).
private struct ChoreCardPressStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
            .animation(Theme.Motion.snappy, value: configuration.isPressed)
    }
}

/// Red "Late" pill — surfaces past-due chores at a glance.
struct LatePill: View {
    var body: some View {
        Label("Late", systemImage: "exclamationmark.triangle.fill")
            .font(.cozyTag)
            .lineLimit(1)
            .fixedSize(horizontal: true, vertical: false)
            .padding(.horizontal, 8).padding(.vertical, 3)
            .background(Capsule().fill(Theme.Palette.rose.opacity(0.18)))
            .overlay(Capsule().stroke(Theme.Palette.rose.opacity(0.45), lineWidth: 0.5))
            .foregroundStyle(Theme.Palette.rose)
    }
}

struct PriorityChip: View {
    var priority: ChorePriority
    var body: some View {
        Text(priority.label.uppercased())
            .font(.cozyTag)
            .lineLimit(1)
            .fixedSize(horizontal: true, vertical: false)
            .padding(.horizontal, 8).padding(.vertical, 3)
            .background(Capsule().fill(priority.tint.opacity(0.18)))
            .overlay(Capsule().stroke(priority.tint.opacity(0.4), lineWidth: 0.5))
            .foregroundStyle(priority.tint)
    }
}

struct RecurrenceChip: View {
    var recurrence: ChoreRecurrence
    var body: some View {
        Label(recurrence.label, systemImage: "arrow.triangle.2.circlepath")
            .font(.cozyTag)
            .lineLimit(1)
            .fixedSize(horizontal: true, vertical: false)
            .padding(.horizontal, 8).padding(.vertical, 3)
            .background(Capsule().fill(Theme.Palette.azure.opacity(0.14)))
            .overlay(Capsule().stroke(Theme.Palette.azure.opacity(0.35), lineWidth: 0.5))
            .foregroundStyle(Theme.Palette.azure)
    }
}

struct XPBadge: View {
    var amount: Int
    var body: some View {
        Text("+\(amount) XP")
            .font(.cozy(11, weight: .bold))
            .lineLimit(1)
            .fixedSize(horizontal: true, vertical: false)
            .padding(.horizontal, 10).padding(.vertical, 5)
            .foregroundStyle(Theme.Palette.text)
            .background(Capsule().fill(Theme.Palette.surface))
            .overlay(Capsule().stroke(Theme.Palette.marigold, lineWidth: 1.5))
    }
}

/// Tiny inline streak pill — replaces the old 🔥 emoji.
struct StreakInline: View {
    var streak: Int
    var body: some View {
        StatPill(label: "\(streak)",
                 systemImage: "flame.fill",
                 tint: Theme.Palette.brick)
    }
}
