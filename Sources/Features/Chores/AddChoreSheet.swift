import SwiftUI

struct AddChoreSheet: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var appState: AppState

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

    private let initial: Chore?
    private let onSave: (Chore) -> Void

    init(initial: Chore?, onSave: @escaping (Chore) -> Void) {
        self.initial = initial
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
        _dueDate        = State(initialValue: initial?.dueDate ?? .now)
        _hasDueDate     = State(initialValue: initial?.dueDate != nil)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.Palette.background.ignoresSafeArea()
                ScrollView {
                    VStack(alignment: .leading, spacing: Theme.Spacing.lg) {
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
                    }
                    .padding(.horizontal, Theme.Spacing.md)
                    .padding(.vertical, Theme.Spacing.lg)
                }
            }
            .onChange(of: icon) { _, newIcon in
                // Picking a category — snap difficulty + XP bar to
                // that category's typical effort level. User can
                // fine-tune via the slider or a difficulty chip after.
                applyDifficulty(ChoreIcon.defaultDifficulty(for: newIcon))
            }
            .onChange(of: title) { _, newTitle in
                // Picking a specific preset chip — override with the
                // preset's known effort. Free-text titles are ignored.
                if let preset = ChoreIcon.presetDifficulty(for: newTitle) {
                    applyDifficulty(preset)
                }
            }
            .navigationTitle(initial == nil ? "New chore" : "Edit chore")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(initial == nil ? "Add" : "Save", action: save)
                        .font(.cozy(15, weight: .bold))
                        .disabled(title.trimmingCharacters(in: .whitespaces).isEmpty)
                }
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
                    DatePicker("", selection: $dueDate,
                               displayedComponents: [.date, .hourAndMinute])
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
            createdAt: initial?.createdAt ?? .now
        )
        onSave(chore)
        dismiss()
    }
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
