import SwiftUI

struct ChoreCard: View {
    var chore: Chore
    var assignee: RoomieUser?
    var onMove: (ChoreStatus) -> Void
    /// Called when the user taps the explicit edit button in the
    /// bottom-right corner. The tile body itself is no longer a tap
    /// target — only swipes (status change) and the edit button
    /// produce action.
    var onEdit: () -> Void

    @State private var showingStatusPicker = false
    @State private var completing = false
    @State private var dragOffset: CGFloat = 0

    var body: some View {
        let shape = RoundedRectangle(cornerRadius: Theme.Radius.md, style: .continuous)
        return ZStack {
            swipeBackground(shape: shape)
            cardContent(shape: shape)
                .offset(x: dragOffset)
        }
        .simultaneousGesture(swipeGesture)
        // The `completing` flag is the transient "I'm being marked
        // done" state — it should not survive past the chore actually
        // landing in `.done`. SwiftUI happily reuses the same card
        // view across segment switches, so without this the giant
        // checkmark overlay sticks around on every Done card the user
        // finished via swipe.
        .onChange(of: chore.status) { _, newStatus in
            if newStatus != .todo { completing = false }
        }
    }

    /// The visible tile content — extracted out of the body so the
    /// gesture / offset logic stays readable. No longer wrapped in a
    /// Button: edits happen via the explicit pencil button below.
    private func cardContent(shape: RoundedRectangle) -> some View {
        ZStack {
            // Soft floating shadow — matches the home-page tiles
            // and replaces the older glass-border treatment for a
            // unified app-wide tile language.
            shape
                .fill(Theme.Palette.surface)
                .shadow(color: Color.black.opacity(0.08),
                        radius: 8, x: 0, y: 4)
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
                        if chore.isOverdue {
                            LatePill()
                        }
                    }
                    Spacer()
                    XPBadge(amount: chore.xpReward)
                }

                HStack(spacing: 10) {
                    AvatarView(user: assignee, size: 26)
                    if chore.isOverdue, let due = chore.dueDate {
                        Label("Was due \(due.friendlyShort())",
                              systemImage: "calendar")
                            .font(.cozyCaption)
                            .foregroundStyle(Theme.Palette.orange)
                    }
                    if chore.streak > 1 {
                        StreakInline(streak: chore.streak)
                    }
                    Spacer()
                    editButton
                }
            }
            .padding(12)
        }
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

    /// Small circular pencil button anchored to the bottom-right of
    /// each tile. The only path to the edit sheet — taps on the rest
    /// of the tile do nothing.
    private var editButton: some View {
        Button {
            Haptics.selection()
            onEdit()
        } label: {
            Image(systemName: "pencil")
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(Theme.Palette.textSoft)
                .frame(width: 28, height: 28)
                .background(Circle().fill(Theme.Palette.subtle))
                .overlay(
                    Circle().stroke(Theme.Palette.hairline, lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Edit chore")
    }

    /// One swipe target — the destination status plus the colour /
    /// glyph / label shown on the swipe pad while dragging.
    private struct SwipeAction {
        let status: ChoreStatus
        let label: String
        let icon: String
        let tint: Color
    }

    /// Action revealed when the user drags **left → right** (positive
    /// offset). Always the "more complete" of the two non-current
    /// statuses — Done if available, otherwise In Progress.
    private var rightSwipeAction: SwipeAction {
        switch chore.status {
        case .todo, .inProgress:
            return SwipeAction(status: .done,
                               label: "Done",
                               icon: "checkmark.circle.fill",
                               tint: Theme.Palette.emerald)
        case .done:
            return SwipeAction(status: .inProgress,
                               label: "In Progress",
                               icon: "timer",
                               tint: Theme.Palette.marigold)
        }
    }

    /// Action revealed when the user drags **right → left** (negative
    /// offset). Always the "less complete" of the two non-current
    /// statuses — To Do if available, otherwise In Progress.
    private var leftSwipeAction: SwipeAction {
        switch chore.status {
        case .todo:
            return SwipeAction(status: .inProgress,
                               label: "In Progress",
                               icon: "timer",
                               tint: Theme.Palette.marigold)
        case .inProgress, .done:
            return SwipeAction(status: .todo,
                               label: "To Do",
                               icon: "circle",
                               tint: Theme.Palette.alizarin)
        }
    }

    /// Coloured pad that sits behind the card while the user drags.
    /// Right swipe reveals `rightSwipeAction` on the leading edge,
    /// left swipe reveals `leftSwipeAction` on the trailing edge. The
    /// action options depend on the chore's current status.
    @ViewBuilder
    private func swipeBackground(shape: RoundedRectangle) -> some View {
        if dragOffset > 0 {
            let action = rightSwipeAction
            ZStack(alignment: .leading) {
                shape.fill(action.tint)
                HStack(spacing: 8) {
                    Image(systemName: action.icon)
                        .font(.system(size: 22, weight: .bold))
                    Text(action.label)
                        .font(.cozyChipStrong)
                }
                .foregroundStyle(.white)
                .padding(.leading, 22)
            }
            .transition(.opacity)
        } else if dragOffset < 0 {
            let action = leftSwipeAction
            ZStack(alignment: .trailing) {
                shape.fill(action.tint)
                HStack(spacing: 8) {
                    Text(action.label)
                        .font(.cozyChipStrong)
                    Image(systemName: action.icon)
                        .font(.system(size: 22, weight: .bold))
                }
                .foregroundStyle(.white)
                .padding(.trailing, 22)
            }
            .transition(.opacity)
        }
    }

    /// Drag gesture wired as a `simultaneousGesture` so the parent
    /// ScrollView still gets vertical drags. Active for all statuses —
    /// the swipe targets come from `rightSwipeAction` / `leftSwipeAction`
    /// which depend on the chore's current status. Only horizontal
    /// drags move the card; vertical motions fall through to scroll.
    private var swipeGesture: some Gesture {
        DragGesture(minimumDistance: 15)
            .onChanged { value in
                guard !completing else { return }
                let dx = value.translation.width
                let dy = value.translation.height
                guard abs(dx) > abs(dy) * 1.5 else { return }
                // Light rubber-band so the card can't drag forever.
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
                    commitSwipe(rightSwipeAction)
                } else if dx < -threshold {
                    commitSwipe(leftSwipeAction)
                } else {
                    withAnimation(Theme.Motion.spring) {
                        dragOffset = 0
                    }
                }
            }
    }

    /// Apply a committed swipe — runs the celebratory completion
    /// animation when the destination is `.done`, otherwise just moves
    /// the chore to the new status with a selection haptic.
    private func commitSwipe(_ action: SwipeAction) {
        if action.status == .done {
            Haptics.success()
            withAnimation(Theme.Motion.bouncy) {
                completing = true
                dragOffset = 0
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.55) {
                onMove(.done)
            }
        } else {
            Haptics.selection()
            withAnimation(Theme.Motion.spring) {
                dragOffset = 0
            }
            onMove(action.status)
        }
    }

    /// Pill showing the chore's current status. Tap to open a popover
    /// styled like the chore tile — white surface, hairline stroke,
    /// themed rows. Picking a row moves the chore to that status.
    private var statusMenu: some View {
        let accent: Color = chore.status == .todo
            ? Theme.Palette.orange
            : Theme.Palette.skyBlue
        return Button {
            Haptics.selection()
            showingStatusPicker = true
        } label: {
            HStack(spacing: 6) {
                Image(systemName: chore.status.icon)
                    .font(.system(size: 13, weight: .bold))
                Text(chore.status.shortTitle)
                    .font(.cozyCaptionStrong)
                Image(systemName: "chevron.down")
                    .font(.system(size: 10, weight: .bold))
            }
            .foregroundStyle(accent)
            .padding(.horizontal, 12).padding(.vertical, 8)
            .background(Capsule().fill(accent.opacity(0.14)))
            .overlay(Capsule().stroke(accent.opacity(0.55), lineWidth: 1))
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
                            .font(.cozyChip)
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

/// Orange "Late" pill — surfaces past-due chores at a glance.
struct LatePill: View {
    var body: some View {
        Label("Late", systemImage: "exclamationmark.triangle.fill")
            .font(.cozyTag)
            .lineLimit(1)
            .fixedSize(horizontal: true, vertical: false)
            .padding(.horizontal, 8).padding(.vertical, 3)
            .background(Capsule().fill(Theme.Palette.orange.opacity(0.18)))
            .overlay(Capsule().stroke(Theme.Palette.orange.opacity(0.45), lineWidth: 0.5))
            .foregroundStyle(Theme.Palette.orange)
    }
}

struct PriorityChip: View {
    var priority: ChorePriority
    private var tint: Color {
        switch priority {
        case .low:    return Theme.Palette.skyBlue
        case .normal: return Theme.Palette.skyBlue
        case .high:   return Theme.Palette.orange
        }
    }
    var body: some View {
        Text(priority.label.uppercased())
            .font(.cozyTag)
            .lineLimit(1)
            .fixedSize(horizontal: true, vertical: false)
            .padding(.horizontal, 8).padding(.vertical, 3)
            .background(Capsule().fill(tint.opacity(0.18)))
            .overlay(Capsule().stroke(tint.opacity(0.45), lineWidth: 0.5))
            .foregroundStyle(tint)
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
            .background(Capsule().fill(Theme.Palette.skyBlue.opacity(0.14)))
            .overlay(Capsule().stroke(Theme.Palette.skyBlue.opacity(0.45), lineWidth: 0.5))
            .foregroundStyle(Theme.Palette.skyBlue)
    }
}

struct XPBadge: View {
    var amount: Int
    var body: some View {
        Text("+\(amount) XP")
            .font(.cozyTag)
            .lineLimit(1)
            .fixedSize(horizontal: true, vertical: false)
            .padding(.horizontal, 10).padding(.vertical, 5)
            .foregroundStyle(Theme.Palette.text)
            .background(Capsule().fill(Theme.Palette.surface))
            .overlay(Capsule().stroke(Theme.Palette.orange, lineWidth: 1.5))
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
