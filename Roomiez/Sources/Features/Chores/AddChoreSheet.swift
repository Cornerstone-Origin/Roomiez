import SwiftUI

/// Top-level mode of `AddChoreSheet`. `.single` builds a one-off `Chore`
/// (existing behavior). `.group` builds a `ChoreGroup` + members and the
/// scheduler materializes a weekly assignment Chore from it.
enum ChoreEntryMode: String, CaseIterable, Identifiable, Sendable {
    case single, group
    var id: String { rawValue }
    var label: String { self == .single ? "Single" : "Group" }
    var icon: String { self == .single ? "checkmark.circle" : "arrow.triangle.2.circlepath" }
}

struct AddChoreSheet: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var appState: AppState

    // Mode toggle is only shown when creating new (initial == nil). Editing
    // an existing Chore stays in .single regardless.
    @State private var mode: ChoreEntryMode
    @AppStorage("chore.lastEntryMode") private var lastEntryModeRaw: String =
        ChoreEntryMode.single.rawValue
    @Namespace private var modeIndicator

    // Single-mode state
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

    // Group-mode state
    @State private var groupFrequency: GroupFrequency = .weekly
    @State private var groupMemberIds: Set<UUID> = []
    @State private var rotationStyle: RotationStyle = .classic
    @State private var customOrder: [UUID] = []
    @State private var startDate: Date

    private let initial: Chore?
    private let onSave: (Chore) -> Void
    private let onSaveGroup: ((ChoreGroup, [ChoreGroupMember]) -> Void)?

    init(initial: Chore?,
         onSave: @escaping (Chore) -> Void,
         onSaveGroup: ((ChoreGroup, [ChoreGroupMember]) -> Void)? = nil) {
        self.initial = initial
        self.onSave = onSave
        self.onSaveGroup = onSaveGroup
        // Edit flow is always single-mode. New-chore flow remembers the
        // user's last choice via @AppStorage.
        let storedMode = ChoreEntryMode(
            rawValue: UserDefaults.standard.string(forKey: "chore.lastEntryMode") ?? ""
        ) ?? .single
        _mode           = State(initialValue: initial == nil ? storedMode : .single)
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
        _startDate      = State(initialValue: Self.defaultStartDate(for: .now))
    }

    /// Default start date for a new group chore: next Monday at 00:00.
    /// If today is Monday, use today.
    private static func defaultStartDate(for now: Date) -> Date {
        var cal = Calendar.current
        cal.firstWeekday = 2
        let comps = cal.dateComponents([.yearForWeekOfYear, .weekOfYear], from: now)
        return cal.date(from: comps) ?? cal.startOfDay(for: now)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.Palette.background.ignoresSafeArea()
                ScrollView {
                    VStack(alignment: .leading, spacing: Theme.Spacing.lg) {
                        if initial == nil { modeToggle }
                        titleCard
                        presetsRow
                        iconPicker

                        if mode == .single {
                            prioritySection
                            recurrenceSection
                            assigneeSection
                            rotationOrderSection
                        } else {
                            frequencySection
                            membersSection
                            rotationStyleSection
                            if rotationStyle == .custom { customOrderSection }
                        }

                        difficultySection

                        if mode == .single { dueDateSection }
                        else               { startDateSection }

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
            .onChange(of: mode) { _, newMode in
                // Persist last choice so the next quick-add remembers it.
                lastEntryModeRaw = newMode.rawValue
                // First time switching to group mode — default to
                // "everyone selected" and seed custom order.
                if newMode == .group, groupMemberIds.isEmpty {
                    groupMemberIds = Set(appState.members.map(\.id))
                }
                if newMode == .group, customOrder.isEmpty {
                    customOrder = appState.members
                        .filter { groupMemberIds.contains($0.id) }
                        .map(\.id)
                }
            }
            .navigationTitle(navigationTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(saveButtonLabel, action: save)
                        .font(.cozy(15, weight: .bold))
                        .disabled(!isValid)
                }
            }
        }
    }

    private var navigationTitle: String {
        if initial != nil               { return "Edit chore" }
        return mode == .single ? "New chore" : "New rotation"
    }

    private var saveButtonLabel: String {
        if initial != nil               { return "Save" }
        return mode == .single ? "Add" : "Create"
    }

    private var isValid: Bool {
        guard !title.trimmingCharacters(in: .whitespaces).isEmpty else {
            return false
        }
        if mode == .group { return groupMemberIds.count >= 1 }
        return true
    }

    // MARK: - Mode toggle

    /// Two-segment Single | Group pill at the top of the sheet. Matched
    /// geometry effect slides the indicator between segments.
    private var modeToggle: some View {
        HStack(spacing: 0) {
            ForEach(ChoreEntryMode.allCases) { m in
                modeSegment(m)
            }
        }
        .padding(4)
        .background(
            Capsule(style: .continuous).fill(Theme.Palette.surface)
        )
        .overlay(
            Capsule(style: .continuous)
                .stroke(Theme.Palette.divider, lineWidth: 1)
        )
    }

    private func modeSegment(_ m: ChoreEntryMode) -> some View {
        let isSelected = mode == m
        return Button {
            Haptics.selection()
            withAnimation(Theme.Motion.spring) { mode = m }
        } label: {
            HStack(spacing: 6) {
                Image(systemName: m.icon)
                    .font(.system(size: 12, weight: .bold))
                Text(m.label)
                    .font(.cozy(13, weight: .semibold))
            }
            .foregroundStyle(isSelected ? .white
                             : Theme.Palette.text.opacity(0.7))
            .frame(maxWidth: .infinity)
            .padding(.vertical, 9)
            .background(
                ZStack {
                    if isSelected {
                        Capsule().fill(Theme.Gradients.accent)
                            .matchedGeometryEffect(id: "modeIndicator",
                                                   in: modeIndicator)
                    }
                }
            )
            .contentShape(Capsule())
        }
        .buttonStyle(.plain)
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

    // MARK: - Group-mode sections

    private var frequencySection: some View {
        SettingsRow(title: "Frequency") {
            HStack(spacing: 8) {
                ForEach(GroupFrequency.allCases) { f in
                    Button {
                        Haptics.selection()
                        withAnimation(Theme.Motion.spring) { groupFrequency = f }
                    } label: {
                        Text(f.label)
                            .font(.cozy(13, weight: .semibold))
                            .padding(.horizontal, 14).padding(.vertical, 8)
                            .frame(maxWidth: .infinity)
                            .background(
                                Capsule().fill(
                                    groupFrequency == f
                                    ? Theme.Palette.azure
                                    : Theme.Palette.azure.opacity(0.14)
                                )
                            )
                            .foregroundStyle(
                                groupFrequency == f ? .white : Theme.Palette.azure
                            )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private var membersSection: some View {
        SettingsRow(title: "Members") {
            VStack(alignment: .leading, spacing: 10) {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        ForEach(appState.members) { user in
                            memberToggleTile(user)
                        }
                    }
                }
                rotationPreview
            }
        }
    }

    private func memberToggleTile(_ user: RoomieUser) -> some View {
        let isOn = groupMemberIds.contains(user.id)
        return Button {
            Haptics.soft()
            withAnimation(Theme.Motion.spring) {
                if isOn { groupMemberIds.remove(user.id) }
                else    { groupMemberIds.insert(user.id) }
                // Keep customOrder in sync with the selected set.
                customOrder.removeAll { !groupMemberIds.contains($0) }
                for id in groupMemberIds where !customOrder.contains(id) {
                    customOrder.append(id)
                }
            }
        } label: {
            VStack(spacing: 4) {
                ZStack(alignment: .bottomTrailing) {
                    AvatarView(user: user, size: 42,
                               showsRing: isOn)
                    if isOn {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundStyle(Theme.Palette.forest)
                            .background(
                                Circle()
                                    .fill(Theme.Palette.surface)
                                    .frame(width: 16, height: 16)
                            )
                            .offset(x: 2, y: 2)
                    }
                }
                Text(user.displayName)
                    .font(.cozyTag)
                    .foregroundStyle(Theme.Palette.text)
            }
            .opacity(isOn ? 1 : 0.5)
        }
        .buttonStyle(.plain)
    }

    /// Plain-English preview of how the rotation will play out next few
    /// cycles. Removes any ambiguity about how Classic / Shuffle / Custom
    /// will behave.
    private var rotationPreview: some View {
        let selected = appState.members.filter { groupMemberIds.contains($0.id) }
        let order: [RoomieUser] = {
            switch rotationStyle {
            case .classic:
                return selected
            case .custom:
                return customOrder.compactMap { id in
                    appState.members.first { $0.id == id }
                }
            case .shuffle:
                return []
            }
        }()
        return Group {
            if selected.isEmpty {
                Text("Pick at least one roomie to rotate this chore between.")
                    .font(.cozyCaption)
                    .foregroundStyle(Theme.Palette.textSoft)
            } else if rotationStyle == .shuffle {
                Text("Each cycle picks at random — but everyone goes once before anyone repeats.")
                    .font(.cozyCaption)
                    .foregroundStyle(Theme.Palette.textSoft)
                    .fixedSize(horizontal: false, vertical: true)
            } else if let first = order.first {
                let rest = order.dropFirst().prefix(2).map(\.displayName)
                let restClause = rest.isEmpty
                    ? ""
                    : " · Next: \(rest.joined(separator: ", then "))"
                Text("First up: \(first.displayName)\(restClause)")
                    .font(.cozyCaption)
                    .foregroundStyle(Theme.Palette.textSoft)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private var rotationStyleSection: some View {
        SettingsRow(title: "Rotation style") {
            VStack(alignment: .leading, spacing: 10) {
                HStack(spacing: 8) {
                    ForEach(RotationStyle.allCases) { s in
                        Button {
                            Haptics.selection()
                            withAnimation(Theme.Motion.spring) { rotationStyle = s }
                        } label: {
                            VStack(spacing: 4) {
                                Image(systemName: styleIcon(s))
                                    .font(.system(size: 13, weight: .bold))
                                Text(s.label)
                                    .font(.cozy(12, weight: .semibold))
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                            .foregroundStyle(rotationStyle == s ? .white : Theme.Palette.indigo)
                            .background(
                                RoundedRectangle(cornerRadius: Theme.Radius.sm,
                                                 style: .continuous)
                                    .fill(
                                        rotationStyle == s
                                        ? Theme.Palette.indigo
                                        : Theme.Palette.indigo.opacity(0.14)
                                    )
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
                Text(rotationStyle.blurb)
                    .font(.cozyCaption)
                    .foregroundStyle(Theme.Palette.textSoft)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private func styleIcon(_ s: RotationStyle) -> String {
        switch s {
        case .classic: "arrow.triangle.2.circlepath"
        case .shuffle: "shuffle"
        case .custom:  "list.number"
        }
    }

    @ViewBuilder
    private var customOrderSection: some View {
        SettingsRow(title: "Order") {
            VStack(alignment: .leading, spacing: 8) {
                Text("Drag-equivalent reorder — tap the arrows to set who goes first.")
                    .font(.cozyCaption)
                    .foregroundStyle(Theme.Palette.textSoft)
                    .fixedSize(horizontal: false, vertical: true)
                ForEach(Array(customOrder.enumerated()), id: \.element) { (index, id) in
                    if let member = appState.member(id: id) {
                        customOrderRow(index: index, member: member)
                    }
                }
            }
        }
    }

    private func customOrderRow(index: Int, member: RoomieUser) -> some View {
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
            customOrderArrow(direction: .up, index: index)
            customOrderArrow(direction: .down, index: index)
        }
        .padding(.vertical, 4)
    }

    private func customOrderArrow(direction: ReorderDirection, index: Int) -> some View {
        let isDisabled: Bool = {
            switch direction {
            case .up:   return index == 0
            case .down: return index == customOrder.count - 1
            }
        }()
        let symbol = direction == .up ? "chevron.up" : "chevron.down"
        return Button {
            Haptics.soft()
            withAnimation(Theme.Motion.snappy) {
                switch direction {
                case .up:   customOrder.swapAt(index, index - 1)
                case .down: customOrder.swapAt(index, index + 1)
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

    private var startDateSection: some View {
        SettingsRow(title: "Starts") {
            DatePicker("", selection: $startDate,
                       displayedComponents: [.date])
                .datePickerStyle(.compact)
                .labelsHidden()
        }
    }

    // MARK: - Save

    private func save() {
        switch mode {
        case .single: saveSingle()
        case .group:  saveGroup()
        }
    }

    private func saveSingle() {
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

    private func saveGroup() {
        guard let onSaveGroup else {
            // Misconfigured caller — fall back to single-chore save so the
            // user doesn't lose their input.
            saveSingle()
            return
        }

        let id = UUID()
        let group = ChoreGroup(
            id: id,
            householdId: appState.household.id,
            title: title.trimmingCharacters(in: .whitespacesAndNewlines),
            note: note.isEmpty ? nil : note,
            icon: icon,
            frequency: groupFrequency,
            rotationStyle: rotationStyle,
            xpReward: Int(xpReward),
            difficulty: difficulty,
            priority: .normal,
            rotationIndex: 0,
            lastAssignedAt: nil,
            nextDueAt: startDate,
            isPaused: false,
            pausedUntil: nil,
            createdById: appState.currentUser.id,
            createdAt: .now
        )

        // Membership rows. For classic / shuffle the order follows the
        // household member ordering; for custom we use the user's drag
        // order. Either way `bagPicked` starts false so shuffle starts
        // with a fresh bag.
        let orderedIds: [UUID] = {
            switch rotationStyle {
            case .custom: return customOrder.filter { groupMemberIds.contains($0) }
            default:      return appState.members
                                .map(\.id)
                                .filter { groupMemberIds.contains($0) }
            }
        }()

        let members = orderedIds.enumerated().map { (index, userId) in
            ChoreGroupMember(
                groupId: id,
                userId: userId,
                orderIndex: index,
                bagPicked: false
            )
        }

        onSaveGroup(group, members)
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
