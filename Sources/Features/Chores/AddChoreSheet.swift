import SwiftUI

struct AddChoreSheet: View {
    enum Mode: String, CaseIterable, Identifiable {
        case single, group
        var id: String { rawValue }
        var label: String { self == .single ? "Single" : "Group" }
    }

    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var appState: AppState

    // Mode + shared single-chore state
    @State private var mode: Mode = .single
    @State private var title: String
    @State private var note: String
    @State private var icon: String
    @State private var priority: ChorePriority
    @State private var recurrence: ChoreRecurrence
    @State private var assigneeId: UUID?
    @State private var rotationOrder: [UUID]
    @State private var difficulty: ChoreDifficulty
    @State private var xpReward: Double
    @State private var dueDate: Date
    @State private var hasDueDate: Bool

    // Group-mode state — only relevant when `mode == .group`
    @State private var groupDrafts: [GroupChoreDraft] = [GroupChoreDraft()]
    @State private var groupRecurrence: ChoreRecurrence = .weekly
    @State private var groupRotation: [UUID] = []
    @State private var groupRandomOrder: Bool = false
    @State private var groupStartDate: Date = .now
    @State private var groupHasStartDate: Bool = true

    private let initial: Chore?
    /// Other chores in the same group as `initial`. Empty if the chore
    /// is standalone or this is a new-chore sheet. Used to surface and
    /// edit group-level settings.
    private let peers: [Chore]
    private let onSave: ([Chore]) -> Void

    /// - Parameter defaultDueDate: When the sheet opens for a NEW chore
    ///   (`initial == nil`), the Due Date field defaults to this day —
    ///   typically whatever the chore board's calendar strip currently
    ///   has selected. Ignored when editing an existing chore.
    init(initial: Chore?,
         peers: [Chore] = [],
         defaultDueDate: Date? = nil,
         onSave: @escaping ([Chore]) -> Void) {
        self.initial = initial
        self.peers = peers
        self.onSave = onSave
        _title          = State(initialValue: initial?.title ?? "")
        _note           = State(initialValue: initial?.note ?? "")
        _icon           = State(initialValue: initial?.icon ?? ChoreIcon.options[0].symbol)
        _priority       = State(initialValue: initial?.priority ?? .normal)
        _recurrence     = State(initialValue: initial?.recurrence ?? .weekly)
        _assigneeId     = State(initialValue: initial?.assigneeId)
        _rotationOrder  = State(initialValue: initial?.rotationOrder ?? [])
        let startDiff   = initial?.difficulty ?? .normal
        _difficulty     = State(initialValue: startDiff)
        _xpReward       = State(initialValue: Double(initial?.xpReward ?? startDiff.xp))
        // New chore → honour the calendar's selected day (falls back to
        // today's startOfDay if none supplied). Editing → keep the
        // chore's own due. We normalise the initial value to startOfDay
        // so the date-only picker doesn't carry over a stray time
        // component from `.now`.
        let rawDue = initial?.dueDate ?? defaultDueDate ?? .now
        _dueDate        = State(initialValue: Calendar.current.startOfDay(for: rawDue))
        // New chore inherits a due-date on by default whenever the
        // caller passes a `defaultDueDate`, matching the user's intent
        // of "this chore is for the day I picked on the calendar".
        let resolvedHasDue: Bool = {
            if initial != nil { return initial?.dueDate != nil }
            return defaultDueDate != nil
        }()
        _hasDueDate     = State(initialValue: resolvedHasDue)
        // Mirror onto the group-chore page so creating multiple chores
        // in a batch also lands them on the selected day.
        _groupStartDate    = State(initialValue: defaultDueDate ?? .now)
        _groupHasStartDate = State(initialValue: true)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.Palette.background.ignoresSafeArea()
                ScrollView {
                    VStack(alignment: .leading, spacing: Theme.Spacing.lg) {
                        if initial == nil {
                            modePicker
                        }
                        if mode == .single {
                            singleChorePage
                        } else {
                            groupChorePage
                        }
                    }
                    .padding(.horizontal, Theme.Spacing.md)
                    .padding(.vertical, Theme.Spacing.lg)
                }
            }
            .onChange(of: icon) { _, newIcon in
                // Picking a category — snap difficulty + XP bar to
                // that category's typical effort level.
                applyDifficulty(ChoreIcon.defaultDifficulty(for: newIcon))
            }
            .onChange(of: title) { _, newTitle in
                // Specific preset chip → snap to that preset's effort.
                if let preset = ChoreIcon.presetDifficulty(for: newTitle) {
                    applyDifficulty(preset)
                }
            }
            .onAppear {
                if groupRotation.isEmpty {
                    groupRotation = appState.members.map(\.id)
                }
            }
            .navigationTitle(navigationTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(confirmTitle) {
                        mode == .single ? save() : saveGroup()
                    }
                    .font(.cozy(15, weight: .bold))
                    .disabled(saveDisabled)
                }
            }
        }
    }

    private var navigationTitle: String {
        if initial != nil { return "Edit chore" }
        return mode == .single ? "New chore" : "Group chores"
    }

    private var confirmTitle: String {
        if initial != nil { return "Save" }
        if mode == .group {
            let n = groupDrafts.filter {
                !$0.title.trimmingCharacters(in: .whitespaces).isEmpty
            }.count
            return n > 1 ? "Add \(n)" : "Add"
        }
        return "Add"
    }

    private var saveDisabled: Bool {
        if mode == .single {
            return title.trimmingCharacters(in: .whitespaces).isEmpty
        }
        let valid = groupDrafts.contains {
            !$0.title.trimmingCharacters(in: .whitespaces).isEmpty
        }
        return !valid || groupRotation.isEmpty
    }

    // MARK: - Mode picker

    private var modePicker: some View {
        Picker("", selection: $mode) {
            ForEach(Mode.allCases) { m in
                Text(m.label).tag(m)
            }
        }
        .pickerStyle(.segmented)
    }

    // MARK: - Single-chore page (existing content)

    private var singleChorePage: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.lg) {
            if !peers.isEmpty {
                groupMembershipBanner
            }
            titleCard
            presetsRow
            iconPicker
            prioritySection
            recurrenceSection
            assigneeSection
            rotationOrderSection
            difficultySection
            dueDateSection
            notesSection
            if !peers.isEmpty {
                peersSection
            }
        }
    }

    /// Banner shown at the top of the single edit page when the chore
    /// belongs to a group. Clarifies that some fields are shared.
    private var groupMembershipBanner: some View {
        HStack(spacing: 12) {
            Image(systemName: "person.3.fill")
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(Theme.Palette.azure)
                .frame(width: 38, height: 38)
                .background(
                    RoundedRectangle(cornerRadius: Theme.Radius.sm,
                                     style: .continuous)
                        .fill(Theme.Palette.azure.opacity(0.12))
                )
            VStack(alignment: .leading, spacing: 2) {
                Text("Part of a \(peers.count + 1)-chore group")
                    .font(.cozy(15, weight: .bold))
                    .foregroundStyle(Theme.Palette.text)
                Text("Changes to rotation, repeats, and due date apply to every chore in the group.")
                    .font(.cozyTag)
                    .foregroundStyle(Theme.Palette.textSoft)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: Theme.Radius.md, style: .continuous)
                .fill(Theme.Palette.azure.opacity(0.10))
        )
        .overlay(
            RoundedRectangle(cornerRadius: Theme.Radius.md, style: .continuous)
                .stroke(Theme.Palette.azure.opacity(0.35), lineWidth: 1)
        )
    }

    /// Compact list of the chore's peers — read-only preview so the
    /// user can see what else is in the group.
    private var peersSection: some View {
        SettingsRow(title: "Other chores in this group") {
            VStack(spacing: 8) {
                ForEach(peers) { peer in
                    HStack(spacing: 10) {
                        Image(systemName: peer.icon)
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(peer.iconTint)
                            .frame(width: 30, height: 30)
                            .background(
                                RoundedRectangle(cornerRadius: 7, style: .continuous)
                                    .fill(peer.iconTint.opacity(0.14))
                            )
                        VStack(alignment: .leading, spacing: 1) {
                            Text(peer.title)
                                .font(.cozy(14, weight: .semibold))
                                .foregroundStyle(Theme.Palette.text)
                                .lineLimit(1)
                            if let assignee = appState.member(id: peer.assigneeId) {
                                Text("Starts with \(assignee.displayName)")
                                    .font(.cozyTag)
                                    .foregroundStyle(Theme.Palette.textSoft)
                                    .lineLimit(1)
                            }
                        }
                        Spacer()
                        Text("+\(peer.xpReward) XP")
                            .font(.cozyTag)
                            .foregroundStyle(Theme.Palette.textSoft)
                    }
                    .padding(.horizontal, 10).padding(.vertical, 8)
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
                }
                Text("Edit each of these individually to change its title, icon, or difficulty.")
                    .font(.cozyTag)
                    .foregroundStyle(Theme.Palette.textSoft)
                    .padding(.top, 4)
            }
        }
    }

    // MARK: - Sections

    private var titleCard: some View {
        ModernInputField(
            placeholder: "Chore name",
            text: $title,
            systemImage: icon,
            iconTint: ChoreIcon.tint(for: icon),
            font: .cozy(20, weight: .semibold)
        )
        .animation(Theme.Motion.spring, value: icon)
    }

    // MARK: - Preset suggestions

    private var presetsRow: some View {
        let presets = ChoreIcon.presets(for: icon)
        let tint = ChoreIcon.tint(for: icon)
        return VStack(alignment: .leading, spacing: 8) {
            Text("QUICK PRESETS")
                .font(.cozyTag)
                .foregroundStyle(Theme.Palette.textSoft)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(presets, id: \.self) { preset in
                        presetChip(preset, tint: tint)
                    }
                    customChip
                }
                .padding(.horizontal, 2)
                .padding(.vertical, 2)
            }
        }
        .animation(Theme.Motion.spring, value: icon)
    }

    private func presetChip(_ text: String, tint: Color) -> some View {
        let selected = title == text
        return Button {
            Haptics.soft()
            withAnimation(Theme.Motion.spring) { title = text }
        } label: {
            Text(text)
                .font(.cozy(12, weight: .semibold))
                .padding(.horizontal, 12).padding(.vertical, 8)
                .background(
                    Capsule().fill(selected ? tint : tint.opacity(0.14))
                )
                .overlay(
                    Capsule().stroke(tint.opacity(selected ? 0 : 0.35),
                                     lineWidth: 1)
                )
                .foregroundStyle(selected ? .white : tint)
        }
        .buttonStyle(.plain)
    }

    private var customChip: some View {
        Button {
            Haptics.soft()
            withAnimation(Theme.Motion.spring) { title = "" }
        } label: {
            HStack(spacing: 5) {
                Image(systemName: "pencil")
                    .font(.system(size: 11, weight: .semibold))
                Text("Custom")
                    .font(.cozy(12, weight: .semibold))
            }
            .padding(.horizontal, 12).padding(.vertical, 8)
            .background(Capsule().fill(Theme.Palette.surface))
            .overlay(Capsule().stroke(Theme.Palette.divider, lineWidth: 1))
            .foregroundStyle(Theme.Palette.textSoft)
        }
        .buttonStyle(.plain)
    }

    private var iconPicker: some View {
        SettingsRow(title: "Icon") {
            LazyVGrid(
                columns: Array(
                    repeating: GridItem(.flexible(), spacing: 8),
                    count: 3
                ),
                spacing: 8
            ) {
                ForEach(ChoreIcon.options, id: \.symbol) { option in
                    iconGridTile(option)
                }
            }
        }
    }

    private func iconGridTile(_ option: (label: String, symbol: String)) -> some View {
        let tint = ChoreIcon.tint(for: option.symbol)
        let selected = icon == option.symbol
        return Button {
            Haptics.soft()
            icon = option.symbol
        } label: {
            VStack(spacing: 6) {
                Image(systemName: option.symbol)
                    .font(.system(size: 18, weight: .semibold))
                Text(option.label).font(.cozyTag)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: Theme.Radius.sm,
                                 style: .continuous)
                    .fill(selected ? tint : tint.opacity(0.12))
            )
            .foregroundStyle(selected ? .white : tint)
        }
        .buttonStyle(.plain)
    }

    private var prioritySection: some View {
        SettingsRow(title: "Priority") {
            HStack(spacing: 8) {
                ForEach(ChorePriority.allCases) { p in
                    Button {
                        Haptics.selection()
                        priority = p
                    } label: {
                        Text(p.label)
                            .font(.cozy(13, weight: .semibold))
                            .padding(.horizontal, 14).padding(.vertical, 8)
                            .background(
                                Capsule().fill(
                                    priority == p ? p.tint.opacity(0.9) :
                                    Theme.Palette.background
                                )
                            )
                            .foregroundStyle(Theme.Palette.text)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private var recurrenceSection: some View {
        SettingsRow(title: "Repeats") {
            Picker("", selection: $recurrence) {
                ForEach(ChoreRecurrence.allCases) { r in
                    Text(r.label).tag(r)
                }
            }
            .tint(Theme.Palette.text)
        }
    }

    private var assigneeSection: some View {
        SettingsRow(title: "Assignee") {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    Button {
                        Haptics.soft(); assigneeId = nil
                    } label: {
                        VStack(spacing: 4) {
                            Circle()
                                .strokeBorder(Theme.Palette.text.opacity(0.3),
                                              style: StrokeStyle(lineWidth: 2, dash: [4]))
                                .frame(width: 38, height: 38)
                                .overlay(Image(systemName: "shuffle"))
                            Text("Rotate")
                                .font(.cozyTag)
                                .foregroundStyle(Theme.Palette.textSoft)
                        }
                        .opacity(assigneeId == nil ? 1 : 0.5)
                    }
                    .buttonStyle(.plain)

                    ForEach(appState.members) { user in
                        Button {
                            Haptics.soft(); assigneeId = user.id
                        } label: {
                            VStack(spacing: 4) {
                                AvatarView(user: user, size: 38,
                                           showsRing: assigneeId == user.id)
                                Text(user.displayName)
                                    .font(.cozyTag)
                                    .foregroundStyle(Theme.Palette.text)
                            }
                            .opacity(assigneeId == user.id ? 1 : 0.55)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }

    // MARK: - Rotation order

    @ViewBuilder
    private var rotationOrderSection: some View {
        if recurrence != .once, assigneeId == nil {
            SettingsRow(title: "Rotation order") {
                VStack(alignment: .leading, spacing: 8) {
                    Text("After each completion this chore will hand off to the next person in this list.")
                        .font(.cozyCaption)
                        .foregroundStyle(Theme.Palette.textSoft)
                        .fixedSize(horizontal: false, vertical: true)

                    ForEach(Array(rotationOrder.enumerated()), id: \.element) { (index, id) in
                        if let member = appState.member(id: id) {
                            rotationRow(index: index, member: member)
                        }
                    }
                }
            }
            .onAppear {
                if rotationOrder.isEmpty {
                    rotationOrder = appState.members.map(\.id)
                }
            }
        }
    }

    private func rotationRow(index: Int, member: RoomieUser) -> some View {
        HStack(spacing: 10) {
            Text("\(index + 1)")
                .font(.cozy(12, weight: .bold))
                .foregroundStyle(.white)
                .frame(width: 22, height: 22)
                .background(Circle().fill(Theme.Palette.indigo))
            AvatarView(user: member, size: 32, showsRing: false)
            Text(member.displayName)
                .font(.cozy(14, weight: .semibold))
                .foregroundStyle(Theme.Palette.text)
            Spacer()
            reorderArrow(direction: .up, index: index)
            reorderArrow(direction: .down, index: index)
        }
        .padding(.vertical, 4)
    }

    private enum ReorderDirection { case up, down }

    private func reorderArrow(direction: ReorderDirection, index: Int) -> some View {
        let isDisabled: Bool = {
            switch direction {
            case .up:   return index == 0
            case .down: return index == rotationOrder.count - 1
            }
        }()
        let symbol = direction == .up ? "chevron.up" : "chevron.down"
        return Button {
            Haptics.soft()
            withAnimation(Theme.Motion.snappy) {
                switch direction {
                case .up:   rotationOrder.swapAt(index, index - 1)
                case .down: rotationOrder.swapAt(index, index + 1)
                }
            }
        } label: {
            Image(systemName: symbol)
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(isDisabled
                                 ? Theme.Palette.textSoft.opacity(0.35)
                                 : Theme.Palette.indigo)
                .frame(width: 28, height: 28)
                .background(Circle().fill(Theme.Palette.background))
                .overlay(Circle().stroke(Theme.Palette.divider, lineWidth: 1))
        }
        .buttonStyle(.plain)
        .disabled(isDisabled)
    }

    private var difficultySection: some View {
        SettingsRow(title: "Difficulty") {
            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 8) {
                    ForEach(ChoreDifficulty.allCases) { d in
                        difficultyChip(d)
                    }
                }
                HStack(spacing: 10) {
                    Slider(value: $xpReward, in: 5...50, step: 1)
                        .tint(difficulty.tint)
                    Text("+\(Int(xpReward)) XP")
                        .font(.cozy(13, weight: .bold))
                        .frame(width: 64, alignment: .trailing)
                        .foregroundStyle(difficulty.tint)
                }
                Text(difficulty.blurb)
                    .font(.cozyCaption)
                    .foregroundStyle(Theme.Palette.textSoft)
            }
        }
    }

    /// Apply a difficulty + slide the XP bar to that difficulty's
    /// canonical reward. Animated so the slider visibly moves.
    private func applyDifficulty(_ d: ChoreDifficulty) {
        withAnimation(Theme.Motion.spring) {
            difficulty = d
            xpReward = Double(d.xp)
        }
    }

    private func difficultyChip(_ d: ChoreDifficulty) -> some View {
        let isSelected = difficulty == d
        return Button {
            Haptics.selection()
            applyDifficulty(d)
        } label: {
            VStack(spacing: 4) {
                Image(systemName: d.icon)
                    .font(.system(size: 13, weight: .bold))
                Text(d.label)
                    .font(.cozy(12, weight: .semibold))
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .foregroundStyle(isSelected ? .white : d.tint)
            .background(
                RoundedRectangle(cornerRadius: Theme.Radius.sm,
                                 style: .continuous)
                    .fill(isSelected ? d.tint : d.tint.opacity(0.14))
            )
            .overlay(
                RoundedRectangle(cornerRadius: Theme.Radius.sm,
                                 style: .continuous)
                    .stroke(d.tint.opacity(isSelected ? 0 : 0.45),
                            lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }

    private var dueDateSection: some View {
        SettingsRow(title: "Due") {
            VStack(alignment: .leading) {
                Toggle("Has due date", isOn: $hasDueDate.animation(Theme.Motion.spring))
                    .tint(Theme.Palette.teal)
                if hasDueDate {
                    // Date only — leave the time unset so chores aren't
                    // pinned to a specific hour-minute. (`Date` still
                    // stores 00:00 internally; the picker just doesn't
                    // surface a time wheel for the user to touch.)
                    DatePicker("", selection: $dueDate,
                               displayedComponents: [.date])
                        .datePickerStyle(.compact)
                        .labelsHidden()
                }
            }
        }
    }

    private var notesSection: some View {
        SettingsRow(title: "Note") {
            TextField("Optional", text: $note, axis: .vertical)
                .lineLimit(2...5)
                .font(.cozyBody)
        }
    }

    // MARK: - Save

    private func save() {
        // Only persist a custom rotation order if it actually differs
        // from the household default — keeps the data clean.
        let defaultOrder = appState.members.map(\.id)
        let storedOrder = (recurrence == .once || rotationOrder == defaultOrder)
            ? []
            : rotationOrder

        let chore = Chore(
            id: initial?.id ?? UUID(),
            householdId: appState.household.id,
            title: title.trimmingCharacters(in: .whitespacesAndNewlines),
            note: note.isEmpty ? nil : note,
            icon: icon,
            status: initial?.status ?? .todo,
            priority: priority,
            recurrence: recurrence,
            assigneeId: assigneeId,
            rotationOrder: storedOrder,
            xpReward: Int(xpReward),
            difficulty: difficulty,
            dueDate: hasDueDate ? dueDate : nil,
            completedAt: initial?.completedAt,
            streak: initial?.streak ?? 0,
            createdAt: initial?.createdAt ?? .now,
            lastPenaltyAt: initial?.lastPenaltyAt,
            groupId: initial?.groupId
        )

        // If this chore is part of a group, propagate the shared
        // settings (rotation / recurrence / due date) to every peer.
        var updates: [Chore] = [chore]
        if !peers.isEmpty {
            for var peer in peers {
                peer.rotationOrder = storedOrder
                peer.recurrence    = recurrence
                peer.dueDate       = hasDueDate ? dueDate : nil
                updates.append(peer)
            }
        }
        onSave(updates)
        dismiss()
    }

    // MARK: - Group chore page

    private var groupChorePage: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.lg) {
            groupBlurbCard
            groupChoresSection
            groupRotationSection
            groupRecurrenceSection
            groupStartDateSection
        }
    }

    /// Friendly explainer at the top of the group page.
    private var groupBlurbCard: some View {
        HStack(spacing: 12) {
            Image(systemName: "person.3.fill")
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(Theme.Palette.azure)
                .frame(width: 38, height: 38)
                .background(
                    RoundedRectangle(cornerRadius: Theme.Radius.sm,
                                     style: .continuous)
                        .fill(Theme.Palette.azure.opacity(0.12))
                )
            VStack(alignment: .leading, spacing: 2) {
                Text("Rotate together")
                    .font(.cozy(15, weight: .bold))
                    .foregroundStyle(Theme.Palette.text)
                Text("Add a batch of chores. Each cycles through your rotation, staggered so different people start with different chores.")
                    .font(.cozyTag)
                    .foregroundStyle(Theme.Palette.textSoft)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: Theme.Radius.md, style: .continuous)
                .fill(Theme.Palette.surface)
        )
        .overlay(
            RoundedRectangle(cornerRadius: Theme.Radius.md, style: .continuous)
                .stroke(Theme.Palette.divider, lineWidth: 1)
        )
    }

    private var groupRotationSection: some View {
        SettingsRow(title: "Rotation") {
            VStack(alignment: .leading, spacing: 12) {
                Text("Tap a roommate to add or remove them from the rotation.")
                    .font(.cozyTag)
                    .foregroundStyle(Theme.Palette.textSoft)
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        ForEach(appState.members) { user in
                            memberToggleChip(user)
                        }
                    }
                    .padding(.vertical, 2)
                    .padding(.horizontal, 2)
                }
                if groupRotation.isEmpty {
                    Text("Add at least one roommate to the rotation.")
                        .font(.cozyTag)
                        .foregroundStyle(Theme.Palette.rose)
                } else {
                    Toggle(isOn: $groupRandomOrder.animation(Theme.Motion.spring)) {
                        HStack(spacing: 6) {
                            Image(systemName: "shuffle")
                                .font(.system(size: 12, weight: .bold))
                            Text("Random order")
                                .font(.cozy(13, weight: .semibold))
                        }
                        .foregroundStyle(Theme.Palette.text)
                    }
                    .tint(Theme.Palette.azure)

                    if groupRandomOrder {
                        Text("Roommates will be shuffled into a random sequence when you add the chores.")
                            .font(.cozyTag)
                            .foregroundStyle(Theme.Palette.textSoft)
                    } else {
                        rotationOrderPreview
                    }
                }
            }
        }
    }

    /// Numbered list of rotation members in their current order, with
    /// up/down reorder controls. Only visible when `groupRandomOrder`
    /// is off (manual order).
    private var rotationOrderPreview: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("ORDER")
                .font(.cozyTag)
                .foregroundStyle(Theme.Palette.textSoft)
            ForEach(Array(groupRotation.enumerated()), id: \.element) { (idx, id) in
                if let user = appState.member(id: id) {
                    rotationOrderRow(index: idx, user: user)
                }
            }
        }
    }

    private func rotationOrderRow(index: Int, user: RoomieUser) -> some View {
        HStack(spacing: 10) {
            Text("\(index + 1)")
                .font(.cozy(12, weight: .bold))
                .foregroundStyle(.white)
                .frame(width: 22, height: 22)
                .background(Circle().fill(user.accent))
            AvatarView(user: user, size: 28, showsRing: false)
            Text(user.id == appState.currentUser.id ? "You" : user.displayName)
                .font(.cozy(14, weight: .semibold))
                .foregroundStyle(Theme.Palette.text)
            Spacer()
            rotationReorderArrow(direction: .up, index: index)
            rotationReorderArrow(direction: .down, index: index)
        }
        .padding(.vertical, 4)
    }

    private enum RotationReorderDirection { case up, down }

    private func rotationReorderArrow(direction: RotationReorderDirection,
                                      index: Int) -> some View {
        let isDisabled: Bool = {
            switch direction {
            case .up:   return index == 0
            case .down: return index == groupRotation.count - 1
            }
        }()
        let symbol = direction == .up ? "chevron.up" : "chevron.down"
        return Button {
            Haptics.soft()
            withAnimation(Theme.Motion.snappy) {
                switch direction {
                case .up:   groupRotation.swapAt(index, index - 1)
                case .down: groupRotation.swapAt(index, index + 1)
                }
            }
        } label: {
            Image(systemName: symbol)
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(isDisabled
                                 ? Theme.Palette.textSoft.opacity(0.35)
                                 : Theme.Palette.text)
                .frame(width: 26, height: 26)
                .background(Circle().fill(Theme.Palette.surface))
                .overlay(Circle().stroke(Theme.Palette.divider, lineWidth: 1))
        }
        .buttonStyle(.plain)
        .disabled(isDisabled)
    }

    private func memberToggleChip(_ user: RoomieUser) -> some View {
        let isIn = groupRotation.contains(user.id)
        return Button {
            Haptics.selection()
            withAnimation(Theme.Motion.spring) {
                if isIn {
                    groupRotation.removeAll { $0 == user.id }
                } else {
                    groupRotation.append(user.id)
                }
            }
        } label: {
            VStack(spacing: 4) {
                AvatarView(user: user, size: 44, showsRing: isIn)
                Text(user.id == appState.currentUser.id ? "You" : user.displayName)
                    .font(.cozyTag)
                    .foregroundStyle(Theme.Palette.text)
                    .lineLimit(1)
            }
            .padding(.horizontal, 8).padding(.vertical, 6)
            .background(
                RoundedRectangle(cornerRadius: Theme.Radius.sm,
                                 style: .continuous)
                    .fill(isIn
                          ? user.accent.opacity(0.18)
                          : Theme.Palette.surface)
            )
            .overlay(
                RoundedRectangle(cornerRadius: Theme.Radius.sm,
                                 style: .continuous)
                    .stroke(isIn
                            ? user.accent.opacity(0.55)
                            : Theme.Palette.divider,
                            lineWidth: 1)
            )
            .opacity(isIn ? 1 : 0.65)
        }
        .buttonStyle(.plain)
    }

    private var groupRecurrenceSection: some View {
        SettingsRow(title: "Repeats") {
            Picker("", selection: $groupRecurrence) {
                ForEach(ChoreRecurrence.allCases) { r in
                    Text(r.label).tag(r)
                }
            }
            .tint(Theme.Palette.text)
        }
    }

    private var groupStartDateSection: some View {
        SettingsRow(title: "Start") {
            VStack(alignment: .leading) {
                Toggle("Set a due date",
                       isOn: $groupHasStartDate.animation(Theme.Motion.spring))
                    .tint(Theme.Palette.teal)
                if groupHasStartDate {
                    DatePicker("", selection: $groupStartDate,
                               displayedComponents: [.date])
                        .datePickerStyle(.compact)
                        .labelsHidden()
                }
            }
        }
    }

    private var groupChoresSection: some View {
        SettingsRow(title: "Chores") {
            VStack(alignment: .leading, spacing: 10) {
                ForEach($groupDrafts) { $draft in
                    groupDraftRow($draft)
                }
                Button {
                    Haptics.soft()
                    withAnimation(Theme.Motion.spring) {
                        groupDrafts.append(GroupChoreDraft())
                    }
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "plus.circle.fill")
                        Text("Add another chore")
                    }
                    .font(.cozy(13, weight: .bold))
                    .foregroundStyle(Theme.Palette.azure)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(Capsule().fill(Theme.Palette.azure.opacity(0.12)))
                    .overlay(Capsule().stroke(Theme.Palette.azure.opacity(0.35),
                                              lineWidth: 1))
                }
                .buttonStyle(.plain)
            }
        }
    }

    private func groupDraftRow(_ draft: Binding<GroupChoreDraft>) -> some View {
        let tint = ChoreIcon.tint(for: draft.wrappedValue.icon)
        return VStack(spacing: 8) {
            HStack(spacing: 10) {
                // Icon picker (Menu)
                Menu {
                    ForEach(ChoreIcon.options, id: \.symbol) { opt in
                        Button {
                            draft.wrappedValue.icon = opt.symbol
                            draft.wrappedValue.difficulty =
                                ChoreIcon.defaultDifficulty(for: opt.symbol)
                        } label: {
                            Label(opt.label, systemImage: opt.symbol)
                        }
                    }
                } label: {
                    Image(systemName: draft.wrappedValue.icon)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(tint)
                        .frame(width: 38, height: 38)
                        .background(
                            RoundedRectangle(cornerRadius: Theme.Radius.sm,
                                             style: .continuous)
                                .fill(tint.opacity(0.12))
                        )
                }

                TextField("Chore name", text: draft.title)
                    .font(.cozyBody)
                    .padding(.horizontal, 12).padding(.vertical, 10)
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
                    .onChange(of: draft.wrappedValue.title) { _, newTitle in
                        if let preset = ChoreIcon.presetDifficulty(for: newTitle) {
                            draft.wrappedValue.difficulty = preset
                        }
                    }

                Text("+\(draft.wrappedValue.difficulty.xp)")
                    .font(.cozy(12, weight: .bold))
                    .foregroundStyle(draft.wrappedValue.difficulty.tint)
                    .padding(.horizontal, 8).padding(.vertical, 5)
                    .background(Capsule().fill(
                        draft.wrappedValue.difficulty.tint.opacity(0.14)))
                    .overlay(Capsule().stroke(
                        draft.wrappedValue.difficulty.tint.opacity(0.45),
                        lineWidth: 1))

                if groupDrafts.count > 1 {
                    Button {
                        Haptics.soft()
                        withAnimation(Theme.Motion.snappy) {
                            groupDrafts.removeAll { $0.id == draft.wrappedValue.id }
                        }
                    } label: {
                        Image(systemName: "trash.fill")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundStyle(Theme.Palette.rose)
                            .frame(width: 30, height: 30)
                            .background(Circle().fill(Theme.Palette.rose.opacity(0.12)))
                    }
                    .buttonStyle(.plain)
                }
            }
            // Preset chips for that icon
            let presets = ChoreIcon.presets(for: draft.wrappedValue.icon)
            if !presets.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 6) {
                        ForEach(presets, id: \.self) { preset in
                            Button {
                                Haptics.soft()
                                draft.wrappedValue.title = preset
                                if let d = ChoreIcon.presetDifficulty(for: preset) {
                                    draft.wrappedValue.difficulty = d
                                }
                            } label: {
                                Text(preset)
                                    .font(.cozy(11, weight: .semibold))
                                    .padding(.horizontal, 10).padding(.vertical, 5)
                                    .background(Capsule().fill(tint.opacity(0.14)))
                                    .overlay(Capsule().stroke(tint.opacity(0.35),
                                                              lineWidth: 1))
                                    .foregroundStyle(tint)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
        }
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: Theme.Radius.sm, style: .continuous)
                .fill(Theme.Palette.subtle)
        )
        .overlay(
            RoundedRectangle(cornerRadius: Theme.Radius.sm, style: .continuous)
                .stroke(Theme.Palette.divider, lineWidth: 1)
        )
    }

    private func saveGroup() {
        // Filter blank rows
        let valid = groupDrafts.filter {
            !$0.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        }
        guard !valid.isEmpty, !groupRotation.isEmpty else { return }

        // Apply the user's chosen order: random shuffle, or use the
        // manual sequence as-is. The shuffled order is then shared by
        // every chore in the group so rotations stay consistent.
        let order = groupRandomOrder ? groupRotation.shuffled() : groupRotation
        // One shared `groupId` so peers can find each other in the
        // edit sheet later.
        let sharedGroupId = UUID()

        // Stagger the initial assignee so different roommates start with
        // different chores in the cycle.
        let chores: [Chore] = valid.enumerated().map { (idx, draft) in
            let firstAssignee = order[idx % order.count]
            return Chore(
                id: UUID(),
                householdId: appState.household.id,
                title: draft.title.trimmingCharacters(in: .whitespacesAndNewlines),
                note: nil,
                icon: draft.icon,
                status: .todo,
                priority: .normal,
                recurrence: groupRecurrence,
                assigneeId: firstAssignee,
                rotationOrder: order,
                xpReward: draft.difficulty.xp,
                difficulty: draft.difficulty,
                dueDate: groupHasStartDate ? groupStartDate : nil,
                completedAt: nil,
                streak: 0,
                createdAt: .now,
                lastPenaltyAt: nil,
                groupId: sharedGroupId
            )
        }
        onSave(chores)
        dismiss()
    }
}

/// In-memory draft used by the group-chore page. Becomes a `Chore` on save.
struct GroupChoreDraft: Identifiable, Equatable {
    let id = UUID()
    var icon: String = ChoreIcon.options[0].symbol
    var title: String = ""
    var difficulty: ChoreDifficulty = .normal
}

/// Small generic row used in setting sheets across the app.
struct SettingsRow<Content: View>: View {
    var title: String
    @ViewBuilder var content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title.uppercased())
                .font(.cozyTag)
                .foregroundStyle(Theme.Palette.textSoft)
            content()
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: Theme.Radius.md, style: .continuous)
                .fill(Theme.Palette.surface)
        )
        .cozyShadow(intensity: 0.6)
    }
}
