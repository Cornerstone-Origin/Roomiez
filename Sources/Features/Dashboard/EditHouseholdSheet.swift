import SwiftUI

/// Edit the household profile from the home page. Lets the user rename
/// the house, manage rules (add / reorder / edit / delete), and remove
/// roommates. The current user can't remove themselves — that's an
/// account action, not a household one.
struct EditHouseholdSheet: View {
    @Environment(\.dismiss) private var dismiss

    @State private var name: String
    @State private var rules: [String]
    @State private var memberIds: [UUID]

    @State private var pendingRule: String = ""
    @State private var memberPendingRemoval: RoomieUser? = nil

    private let initial: Household
    private let allMembers: [RoomieUser]
    private let currentUserId: UUID
    private let onSave: (Household) -> Void

    init(household: Household,
         members: [RoomieUser],
         currentUserId: UUID,
         onSave: @escaping (Household) -> Void) {
        self.initial = household
        self.allMembers = members
        self.currentUserId = currentUserId
        self.onSave = onSave
        _name      = State(initialValue: household.name)
        _rules     = State(initialValue: household.rules)
        _memberIds = State(initialValue: household.memberIds)
    }

    private var visibleMembers: [RoomieUser] {
        memberIds.compactMap { id in allMembers.first { $0.id == id } }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                PearlBackground()

                ScrollView {
                    VStack(alignment: .leading, spacing: Theme.Spacing.lg) {
                        nameSection
                        rulesSection
                        membersSection
                        inviteCodeSection
                    }
                    .padding(.horizontal, Theme.Spacing.md)
                    .padding(.top, Theme.Spacing.md)
                    .padding(.bottom, 40)
                }
            }
            .navigationTitle("Edit household")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save", action: save)
                        .font(.cozy(15, weight: .bold))
                        .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
            .confirmationDialog(
                memberPendingRemoval.map { "Remove \($0.displayName)?" } ?? "",
                isPresented: Binding(
                    get: { memberPendingRemoval != nil },
                    set: { if !$0 { memberPendingRemoval = nil } }
                ),
                titleVisibility: .visible
            ) {
                Button("Remove from household", role: .destructive) {
                    if let m = memberPendingRemoval {
                        memberIds.removeAll { $0 == m.id }
                    }
                    memberPendingRemoval = nil
                }
                Button("Cancel", role: .cancel) {
                    memberPendingRemoval = nil
                }
            } message: {
                Text("They'll lose access to this household. They can rejoin with the invite code.")
            }
        }
    }

    // MARK: - Sections

    private var nameSection: some View {
        SettingsRow(title: "House name") {
            ModernInputField(
                placeholder: "e.g. The Sunny Loft",
                text: $name,
                systemImage: "house.fill",
                iconTint: Theme.Palette.coral,
                font: .cozy(20, weight: .semibold)
            )
        }
    }

    private var rulesSection: some View {
        SettingsRow(title: "House rules") {
            VStack(alignment: .leading, spacing: 8) {
                if rules.isEmpty {
                    Text("No rules yet. Add the first one below.")
                        .font(.cozyTag)
                        .foregroundStyle(Theme.Palette.textSoft)
                } else {
                    ForEach(Array(rules.enumerated()), id: \.offset) { (idx, _) in
                        ruleRow(index: idx)
                    }
                }

                HStack(spacing: 8) {
                    ModernInputField(
                        placeholder: "Add a new rule",
                        text: $pendingRule,
                        systemImage: "plus.circle.fill",
                        iconTint: Theme.Palette.coral
                    )
                    Button {
                        addPendingRule()
                    } label: {
                        Image(systemName: "checkmark")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundStyle(.white)
                            .frame(width: 44, height: 44)
                            .background(
                                Circle().fill(
                                    pendingRule.trimmingCharacters(in: .whitespaces).isEmpty
                                        ? Theme.Palette.coral.opacity(0.4)
                                        : Theme.Palette.coral
                                )
                            )
                    }
                    .buttonStyle(.plain)
                    .disabled(pendingRule.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
    }

    private func ruleRow(index: Int) -> some View {
        HStack(spacing: 10) {
            Text("\(index + 1)")
                .font(.cozy(12, weight: .bold))
                .foregroundStyle(.white)
                .frame(width: 26, height: 26)
                .background(Circle().fill(Theme.Palette.coral))

            ModernInputField(
                placeholder: "Rule",
                text: Binding(
                    get: { rules[index] },
                    set: { rules[index] = $0 }
                )
            )

            reorderArrow(direction: .up, index: index)
            reorderArrow(direction: .down, index: index)

            Button {
                Haptics.soft()
                withAnimation(Theme.Motion.snappy) {
                    _ = rules.remove(at: index)
                }
            } label: {
                Image(systemName: "trash.fill")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(Theme.Palette.rose)
                    .frame(width: 28, height: 28)
                    .background(Circle().fill(Theme.Palette.rose.opacity(0.12)))
            }
            .buttonStyle(.plain)
        }
    }

    private enum ReorderDirection { case up, down }

    private func reorderArrow(direction: ReorderDirection,
                              index: Int) -> some View {
        let isDisabled: Bool = {
            switch direction {
            case .up:   return index == 0
            case .down: return index == rules.count - 1
            }
        }()
        let symbol = direction == .up ? "chevron.up" : "chevron.down"
        return Button {
            Haptics.soft()
            withAnimation(Theme.Motion.snappy) {
                switch direction {
                case .up:   rules.swapAt(index, index - 1)
                case .down: rules.swapAt(index, index + 1)
                }
            }
        } label: {
            Image(systemName: symbol)
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(isDisabled
                                 ? Theme.Palette.textSoft.opacity(0.35)
                                 : Theme.Palette.text)
                .frame(width: 28, height: 28)
                .background(Circle().fill(Theme.Palette.surface))
                .overlay(Circle().stroke(Theme.Palette.divider, lineWidth: 1))
        }
        .buttonStyle(.plain)
        .disabled(isDisabled)
    }

    private var membersSection: some View {
        SettingsRow(title: "Roommates") {
            VStack(spacing: 8) {
                ForEach(visibleMembers) { user in
                    memberRow(user)
                }
                Text("To add a new roommate, share the invite code below.")
                    .font(.cozyTag)
                    .foregroundStyle(Theme.Palette.textSoft)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.top, 4)
            }
        }
    }

    private func memberRow(_ user: RoomieUser) -> some View {
        let isYou = user.id == currentUserId
        return HStack(spacing: 12) {
            AvatarView(user: user, size: 36)
            VStack(alignment: .leading, spacing: 2) {
                Text(isYou ? "\(user.displayName) (you)" : user.displayName)
                    .font(.cozy(15, weight: .semibold))
                    .foregroundStyle(Theme.Palette.text)
                Text(user.displayTitle)
                    .font(.cozyTag)
                    .foregroundStyle(Theme.Palette.textSoft)
                    .lineLimit(1)
            }
            Spacer()
            if !isYou {
                Button {
                    Haptics.soft()
                    memberPendingRemoval = user
                } label: {
                    Image(systemName: "person.fill.xmark")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(Theme.Palette.rose)
                        .frame(width: 32, height: 32)
                        .background(Circle().fill(Theme.Palette.rose.opacity(0.12)))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 12).padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: Theme.Radius.sm, style: .continuous)
                .fill(Theme.Palette.surface)
        )
        .overlay(
            RoundedRectangle(cornerRadius: Theme.Radius.sm, style: .continuous)
                .stroke(Theme.Palette.divider, lineWidth: 1)
        )
    }

    private var inviteCodeSection: some View {
        SettingsRow(title: "Invite code") {
            HStack(spacing: 12) {
                Text(initial.inviteCode)
                    .font(.cozy(20, weight: .bold))
                    .foregroundStyle(Theme.Palette.text)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 14).padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: Theme.Radius.sm,
                                         style: .continuous)
                            .fill(Theme.Palette.surface)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: Theme.Radius.sm,
                                         style: .continuous)
                            .stroke(Theme.Palette.divider, lineWidth: 1)
                    )
                Button {
                    UIPasteboard.general.string = initial.inviteCode
                    Haptics.success()
                } label: {
                    Image(systemName: "doc.on.doc")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(.white)
                        .frame(width: 44, height: 44)
                        .background(Circle().fill(Theme.Palette.coral))
                }
                .buttonStyle(.plain)
            }
        }
    }

    // MARK: - Mutations

    private func addPendingRule() {
        let trimmed = pendingRule.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        Haptics.soft()
        withAnimation(Theme.Motion.spring) {
            rules.append(trimmed)
            pendingRule = ""
        }
    }

    private func save() {
        var updated = initial
        updated.name = name.trimmingCharacters(in: .whitespacesAndNewlines)
        updated.rules = rules
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
        updated.memberIds = memberIds
        onSave(updated)
        dismiss()
    }
}
