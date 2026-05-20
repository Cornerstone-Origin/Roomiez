import SwiftUI

/// How chores should be ordered within a status. Lives next to the
/// filter sheet because the sheet is where the user picks it.
enum ChoreSortOrder: String, CaseIterable, Identifiable, Sendable {
    case dueDate, priority, xp, title

    var id: String { rawValue }
    var label: String {
        switch self {
        case .dueDate:  "Due date"
        case .priority: "Priority"
        case .xp:       "XP reward"
        case .title:    "Title A–Z"
        }
    }
    var icon: String {
        switch self {
        case .dueDate:  "calendar"
        case .priority: "exclamationmark.circle.fill"
        case .xp:       "sparkle"
        case .title:    "textformat.abc"
        }
    }
}

/// Filter & sort settings for the Chore Board.
struct ChoreFilterSheet: View {
    @Binding var selectedAssigneeId: UUID?
    @Binding var selectedPriority: ChorePriority?
    @Binding var selectedRecurrence: ChoreRecurrence?
    @Binding var sortOrder: ChoreSortOrder
    var members: [RoomieUser]
    var currentUserId: UUID

    @Environment(\.dismiss) private var dismiss

    private var orderedMembers: [RoomieUser] {
        guard let me = members.first(where: { $0.id == currentUserId }) else {
            return members
        }
        let others = members.filter { $0.id != currentUserId }
        return [me] + others
    }

    private var hasActiveFilters: Bool {
        selectedAssigneeId != nil
            || selectedPriority != nil
            || selectedRecurrence != nil
    }

    var body: some View {
        ZStack {
            PearlBackground()

            ScrollView {
                VStack(alignment: .leading, spacing: Theme.Spacing.lg) {
                    header
                    assigneeSection
                    prioritySection
                    rateSection
                    sortSection
                    if hasActiveFilters { resetButton }
                }
                .padding(.horizontal, Theme.Spacing.md)
                .padding(.top, Theme.Spacing.md)
                .padding(.bottom, 40)
            }
        }
    }

    // MARK: - Header

    private var header: some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Filters")
                    .font(.cozyDisplay)
                    .foregroundStyle(Theme.Palette.text)
                Text("Scope and sort the chore list")
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
                    .background(Capsule().fill(Theme.Palette.azure))
            }
            .buttonStyle(.plain)
        }
    }

    // MARK: - Assigned to

    private var assigneeSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionHeader(title: "Assigned to",
                          systemImage: "person.2.fill",
                          tint: Theme.Palette.azure)

            ListCard {
                assigneeRow(
                    title: "Everyone",
                    systemImage: "tray.full.fill",
                    isSelected: selectedAssigneeId == nil,
                    onTap: {
                        Haptics.selection()
                        selectedAssigneeId = nil
                    }
                )
                ForEach(orderedMembers) { member in
                    memberRow(
                        member: member,
                        isYou: member.id == currentUserId,
                        isSelected: selectedAssigneeId == member.id
                    )
                }
            }
        }
    }

    private func assigneeRow(title: String,
                             systemImage: String,
                             isSelected: Bool,
                             onTap: @escaping () -> Void) -> some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                IconBadge(systemName: systemImage,
                          tint: Theme.Palette.azure,
                          size: .sm, style: .solid)
                Text(title)
                    .font(.cozy(15, weight: .semibold))
                    .foregroundStyle(Theme.Palette.text)
                Spacer()
                trailingMark(isSelected: isSelected, tint: Theme.Palette.azure)
            }
            .padding(.horizontal, 14).padding(.vertical, 12)
            .background(rowBackground(isSelected: isSelected,
                                      tint: Theme.Palette.azure))
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .pressable(scale: 0.98)
    }

    private func memberRow(member: RoomieUser,
                           isYou: Bool,
                           isSelected: Bool) -> some View {
        Button {
            Haptics.selection()
            selectedAssigneeId = member.id
        } label: {
            HStack(spacing: 12) {
                AvatarView(user: member, size: 34)
                VStack(alignment: .leading, spacing: 2) {
                    Text(isYou ? "You" : member.displayName)
                        .font(.cozy(15, weight: .semibold))
                        .foregroundStyle(Theme.Palette.text)
                    Text(member.levelTitle)
                        .font(.cozyCaption)
                        .foregroundStyle(Theme.Palette.textSoft)
                        .lineLimit(1)
                }
                Spacer()
                trailingMark(isSelected: isSelected, tint: Theme.Palette.azure)
            }
            .padding(.horizontal, 14).padding(.vertical, 10)
            .background(rowBackground(isSelected: isSelected,
                                      tint: Theme.Palette.azure))
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .pressable(scale: 0.98)
    }

    // MARK: - Priority

    private var prioritySection: some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionHeader(title: "Priority",
                          systemImage: "exclamationmark.circle.fill",
                          tint: Theme.Palette.coral)

            ChipGroup {
                chip(title: "All",
                     icon: nil,
                     tint: Theme.Palette.text,
                     isSelected: selectedPriority == nil) {
                    selectedPriority = nil
                }
                ForEach(ChorePriority.allCases) { p in
                    chip(title: p.label,
                         icon: "circle.fill",
                         tint: p.tint,
                         isSelected: selectedPriority == p) {
                        selectedPriority = p
                    }
                }
            }
        }
    }

    // MARK: - Rate (recurrence)

    private var rateSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionHeader(title: "Rate",
                          systemImage: "arrow.triangle.2.circlepath",
                          tint: Theme.Palette.azure)

            ChipGroup {
                chip(title: "Any",
                     icon: nil,
                     tint: Theme.Palette.text,
                     isSelected: selectedRecurrence == nil) {
                    selectedRecurrence = nil
                }
                ForEach(ChoreRecurrence.allCases) { r in
                    chip(title: r.label,
                         icon: nil,
                         tint: Theme.Palette.azure,
                         isSelected: selectedRecurrence == r) {
                        selectedRecurrence = r
                    }
                }
            }
        }
    }

    // MARK: - Sort

    private var sortSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionHeader(title: "Sort by",
                          systemImage: "arrow.up.arrow.down",
                          tint: Theme.Palette.marigold)

            ChipGroup {
                ForEach(ChoreSortOrder.allCases) { s in
                    chip(title: s.label,
                         icon: s.icon,
                         tint: Theme.Palette.marigold,
                         isSelected: sortOrder == s) {
                        sortOrder = s
                    }
                }
            }
        }
    }

    // MARK: - Reset

    private var resetButton: some View {
        Button {
            Haptics.medium()
            selectedAssigneeId = nil
            selectedPriority = nil
            selectedRecurrence = nil
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "arrow.counterclockwise")
                    .font(.system(size: 13, weight: .bold))
                Text("Reset all filters")
                    .font(.cozy(14, weight: .bold))
            }
            .foregroundStyle(Theme.Palette.rose)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(
                Capsule().fill(Theme.Palette.rose.opacity(0.10))
            )
            .overlay(
                Capsule().stroke(Theme.Palette.rose.opacity(0.35), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .pressable(scale: 0.97)
        .padding(.top, 4)
    }

    // MARK: - Reusable pieces

    private func chip(title: String,
                      icon: String?,
                      tint: Color,
                      isSelected: Bool,
                      onTap: @escaping () -> Void) -> some View {
        Button {
            Haptics.selection()
            onTap()
        } label: {
            HStack(spacing: 5) {
                if let icon {
                    Image(systemName: icon)
                        .font(.system(size: 10, weight: .bold))
                }
                Text(title)
                    .font(.cozy(13, weight: .semibold))
                    .lineLimit(1)
            }
            .foregroundStyle(isSelected ? .white : Theme.Palette.text)
            .padding(.horizontal, 12).padding(.vertical, 8)
            .background(
                Capsule().fill(isSelected ? tint : Theme.Palette.surface)
            )
            .overlay(
                Capsule().stroke(
                    isSelected ? Color.clear : Theme.Palette.divider,
                    lineWidth: 1
                )
            )
        }
        .buttonStyle(.plain)
        .pressable(scale: 0.96)
    }

    private func trailingMark(isSelected: Bool, tint: Color) -> some View {
        Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
            .font(.system(size: 20, weight: .semibold))
            .foregroundStyle(isSelected ? tint : Theme.Palette.textSoft.opacity(0.6))
    }

    private func rowBackground(isSelected: Bool, tint: Color) -> some View {
        let shape = RoundedRectangle(cornerRadius: Theme.Radius.sm,
                                     style: .continuous)
        return ZStack {
            shape.fill(Theme.Palette.surface)
            shape.stroke(
                isSelected ? tint.opacity(0.55) : Theme.Palette.divider,
                lineWidth: isSelected ? 1.5 : 1
            )
        }
    }
}

/// Wrap-able chip row. Uses `FlowLayout` so chips line up left-to-right
/// and wrap to a new line when they run out of space.
private struct ChipGroup<Content: View>: View {
    @ViewBuilder var content: () -> Content
    var body: some View {
        FlowLayout(spacing: 8, lineSpacing: 8) {
            content()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private struct FlowLayout: Layout {
    var spacing: CGFloat = 8
    var lineSpacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize,
                      subviews: Subviews,
                      cache: inout ()) -> CGSize {
        let maxWidth = proposal.width ?? .infinity
        var totalHeight: CGFloat = 0
        var lineWidth: CGFloat = 0
        var lineHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if lineWidth + size.width > maxWidth, lineWidth > 0 {
                totalHeight += lineHeight + lineSpacing
                lineWidth = size.width + spacing
                lineHeight = size.height
            } else {
                lineWidth += size.width + spacing
                lineHeight = max(lineHeight, size.height)
            }
        }
        totalHeight += lineHeight
        return CGSize(width: maxWidth.isFinite ? maxWidth : lineWidth,
                      height: totalHeight)
    }

    func placeSubviews(in bounds: CGRect,
                       proposal: ProposedViewSize,
                       subviews: Subviews,
                       cache: inout ()) {
        var x: CGFloat = bounds.minX
        var y: CGFloat = bounds.minY
        var lineHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x + size.width > bounds.maxX, x > bounds.minX {
                y += lineHeight + lineSpacing
                x = bounds.minX
                lineHeight = 0
            }
            subview.place(at: CGPoint(x: x, y: y),
                          anchor: .topLeading,
                          proposal: .unspecified)
            x += size.width + spacing
            lineHeight = max(lineHeight, size.height)
        }
    }
}
