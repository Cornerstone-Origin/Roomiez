import SwiftUI

struct ChoreBoardView: View {
    @EnvironmentObject private var appState: AppState
    @StateObject private var vm: ChoreBoardViewModel

    @State private var showingAdd = false
    @State private var showingFilter = false
    @State private var selectedStatus: ChoreStatus = .todo
    @State private var selectedDate: Date = .now.startOfDay
    @State private var selectedAssigneeId: UUID? = nil   // nil → all
    @State private var selectedPriority: ChorePriority? = nil
    @State private var selectedRecurrence: ChoreRecurrence? = nil
    @State private var sortOrder: ChoreSortOrder = .dueDate
    @State private var editing: Chore? = nil
    @Namespace private var statusIndicator

    init(appState: AppState) {
        _vm = StateObject(wrappedValue: ChoreBoardViewModel(appState: appState))
    }

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            PearlBackground()

            ScrollView {
                VStack(alignment: .leading, spacing: Theme.Spacing.md) {
                    header
                    ChoreCalendarStrip(selectedDate: $selectedDate,
                                       chores: vm.chores)
                    statusPicker
                    boardColumn
                }
                .padding(.horizontal, Theme.Spacing.md)
                .padding(.top, 0)
                .padding(.bottom, FloatingButtonClearance.bottom + 60)
            }
            .refreshable { await vm.load() }

            FloatingAddButton(
                action: { showingAdd = true },
                gradient: LinearGradient(
                    colors: [Theme.Palette.orange, Theme.Palette.orange],
                    startPoint: .top, endPoint: .bottom
                )
            )
            .padding(.trailing, 20).padding(.bottom, FloatingButtonClearance.bottom)
        }
        .task { await vm.load() }
        .sheet(isPresented: $showingAdd) {
            // Pre-seed the Due Date with whatever day the calendar
            // strip currently has selected, so a chore added from a
            // chosen day lands on that day by default.
            AddChoreSheet(initial: nil,
                          defaultDueDate: selectedDate) { chores in
                Task {
                    for chore in chores { await vm.add(chore) }
                }
            }
            .presentationDetents([.large])
            .presentationCornerRadius(28)
        }
        .sheet(item: $editing) { chore in
            AddChoreSheet(
                initial: chore,
                peers: vm.chores.filter {
                    chore.groupId != nil
                        && $0.groupId == chore.groupId
                        && $0.id != chore.id
                }
            ) { updates in
                Task {
                    for u in updates { await vm.update(u) }
                }
            }
            .presentationDetents([.large])
            .presentationCornerRadius(28)
        }
        .sheet(isPresented: $showingFilter) {
            ChoreFilterSheet(
                selectedAssigneeId: $selectedAssigneeId,
                selectedPriority: $selectedPriority,
                selectedRecurrence: $selectedRecurrence,
                sortOrder: $sortOrder,
                members: appState.members,
                currentUserId: appState.currentUser.id
            )
            .presentationDetents([.large])
            .presentationCornerRadius(28)
        }
    }

    // MARK: - Pieces

    private var header: some View {
        HStack {
            Text("Chore Board")
                .font(.cozyDisplay)
                .foregroundStyle(Theme.Palette.text)
            Spacer()
            StreakChip(streak: appState.household.weeklyStreak)
        }
    }

    private var statusPicker: some View {
        HStack(spacing: 10) {
            filterButton
            statusSegmentedControl
        }
    }

    /// Single capsule with a sliding indicator that snaps to the active
    /// status. Each segment shows icon · label · count. The indicator
    /// uses the status's own tint so colour still communicates state.
    private var statusSegmentedControl: some View {
        HStack(spacing: 0) {
            ForEach(ChoreStatus.allCases) { status in
                statusSegment(status)
            }
        }
        .padding(4)
        .background(
            Capsule().fill(Theme.Palette.surface)
        )
        .overlay(
            Capsule().stroke(Theme.Gradients.glassBorder, lineWidth: 1.2)
        )
        .gesture(
            DragGesture(minimumDistance: 30)
                .onEnded { value in
                    let dx = value.translation.width
                    guard abs(dx) > 40 else { return }
                    if let idx = ChoreStatus.allCases.firstIndex(of: selectedStatus) {
                        let next = dx < 0
                            ? min(idx + 1, ChoreStatus.allCases.count - 1)
                            : max(idx - 1, 0)
                        if next != idx {
                            Haptics.selection()
                            withAnimation(Theme.Motion.spring) {
                                selectedStatus = ChoreStatus.allCases[next]
                            }
                        }
                    }
                }
        )
    }

    private func statusSegment(_ status: ChoreStatus) -> some View {
        let isSelected = selectedStatus == status
        let count = count(for: status)
        let tint = statusFill(for: status)
        return Button {
            Haptics.selection()
            withAnimation(Theme.Motion.spring) { selectedStatus = status }
        } label: {
            HStack(spacing: 6) {
                Image(systemName: status.icon)
                    .font(.system(size: 12, weight: .bold))
                Text(status.shortTitle)
                    .font(.cozy(13, weight: .semibold))
                    .lineLimit(1)
                if count > 0 {
                    Text("\(count)")
                        .font(.cozy(11, weight: .bold))
                        .foregroundStyle(isSelected ? .white : tint)
                        .padding(.horizontal, 6).padding(.vertical, 1)
                        .background(
                            Capsule().fill(
                                isSelected
                                    ? Color.white.opacity(0.30)
                                    : tint.opacity(0.18)
                            )
                        )
                }
            }
            .foregroundStyle(isSelected ? .white : tint)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 9)
            .background(
                ZStack {
                    if isSelected {
                        Capsule()
                            .fill(tint)
                            .matchedGeometryEffect(id: "statusIndicator",
                                                   in: statusIndicator)
                    }
                }
            )
            .contentShape(Capsule())
        }
        .buttonStyle(.plain)
    }

    /// Pill fill / accent per status — matches the swipe-pad colours
    /// on each chore card so the status row reads as the same palette.
    private func statusFill(for status: ChoreStatus) -> Color {
        switch status {
        case .todo:       return Theme.Palette.alizarin   // vivid red
        case .inProgress: return Theme.Palette.marigold   // vivid yellow
        case .done:       return Theme.Palette.emerald    // vivid green
        }
    }

    private func count(for status: ChoreStatus) -> Int {
        chores(for: status).count
    }

    /// Opens the filter sheet. Highlights when any filter is set.
    private var filterButton: some View {
        let isFiltering = selectedAssigneeId != nil
            || selectedPriority != nil
            || selectedRecurrence != nil
        return Button {
            Haptics.selection()
            showingFilter = true
        } label: {
            Image(systemName: "line.3.horizontal.decrease")
                .font(.system(size: 16, weight: .bold))
                .foregroundStyle(isFiltering ? .white : Theme.Palette.text)
                .frame(width: 42, height: 42)
                .background(
                    Circle().fill(
                        isFiltering
                            ? Theme.Palette.orange
                            : Theme.Palette.surface
                    )
                )
                .overlay(
                    Circle().stroke(
                        isFiltering
                            ? AnyShapeStyle(Color.clear)
                            : AnyShapeStyle(Theme.Gradients.glassBorder),
                        lineWidth: 1.2
                    )
                )
                .floatingShadow()
        }
        .buttonStyle(.plain)
        .pressable(scale: 0.94)
    }

    @ViewBuilder
    private var boardColumn: some View {
        let items = chores(for: selectedStatus)
        if items.isEmpty {
            let isToday = Calendar.current.isDateInToday(selectedDate)
            EmptyStateView(
                systemImage: "checkmark.seal.fill",
                tint: Theme.Palette.forest,
                title: isToday ? "Nothing here yet" : "Nothing scheduled",
                subtitle: isToday
                    ? "Tap + to add a chore. Roomiez rotates them for you."
                    : "No \(selectedStatus.title.lowercased()) chores due \(selectedDate.friendlyShort().lowercased()).",
                actionTitle: isToday ? "Add a chore" : nil
            ) { if isToday { showingAdd = true } }
            .padding(.top, 40)
        } else {
            LazyVStack(spacing: 10) {
                ForEach(items) { chore in
                    ChoreCard(
                        chore: chore,
                        assignee: appState.member(id: chore.assigneeId),
                        onMove: { newStatus in
                            Task { await vm.advance(chore, to: newStatus) }
                        },
                        onTap: { editing = chore }
                    )
                    .contextMenu {
                        ForEach(ChoreStatus.allCases) { status in
                            if status != chore.status {
                                Button {
                                    Task { await vm.advance(chore, to: status) }
                                } label: {
                                    Label("Move to \(status.title)",
                                          systemImage: "arrow.right")
                                }
                            }
                        }
                        Divider()
                        Button(role: .destructive) {
                            Task { await vm.remove(chore) }
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    }
                    .transition(.asymmetric(
                        insertion: .scale.combined(with: .opacity),
                        removal:   .move(edge: .leading).combined(with: .opacity)
                    ))
                }
            }
            .animation(Theme.Motion.spring, value: items)
        }
    }

    /// Returns the chores due on the selected day (no recurrence
    /// projection). When viewing today, past-due unfinished chores
    /// also surface — the card stamps them as "Late".
    ///
    /// Done chores are bucketed by **completion date**, not due date —
    /// otherwise a chore that was overdue from yesterday but finished
    /// today would invisibly stay under yesterday's Done segment.
    private func chores(for status: ChoreStatus) -> [Chore] {
        let cal = Calendar.current
        let isToday = cal.isDateInToday(selectedDate)
        let todayStart = cal.startOfDay(for: .now)

        let matches: [Chore] = vm.chores.compactMap { chore -> Chore? in
            guard chore.status == status else { return nil }
            if let p = selectedPriority, chore.priority != p { return nil }
            if let r = selectedRecurrence, chore.recurrence != r { return nil }
            if let filter = selectedAssigneeId,
               chore.assigneeId != filter { return nil }

            // Done segment — surface a completed chore on either the
            // day it was finished OR the day it was originally due, so
            // it's findable wherever the user looks. (Overdue chores
            // finished today, and early completions, both surface on
            // Today regardless of their stored `dueDate`.)
            if status == .done {
                if let completed = chore.completedAt,
                   cal.isDate(completed, inSameDayAs: selectedDate) {
                    return chore
                }
                if let due = chore.dueDate,
                   cal.isDate(due, inSameDayAs: selectedDate) {
                    return chore
                }
                // Stranded done chores with no dates at all → show on
                // today as a fallback so they don't vanish entirely.
                if chore.dueDate == nil && chore.completedAt == nil {
                    return isToday ? chore : nil
                }
                return nil
            }

            // To Do / In Progress — group by due date.
            if let due = chore.dueDate {
                if cal.isDate(due, inSameDayAs: selectedDate) { return chore }
                if isToday, due < todayStart { return chore }
                return nil
            }
            return isToday ? chore : nil
        }
        return matches.sorted(by: chosenSortComparator)
    }

    private func chosenSortComparator(_ a: Chore, _ b: Chore) -> Bool {
        switch sortOrder {
        case .dueDate:
            switch (a.dueDate, b.dueDate) {
            case let (l?, r?): return l < r
            case (_?, nil):    return true
            case (nil, _?):    return false
            case (nil, nil):   return a.title < b.title
            }
        case .priority:
            return priorityRank(a.priority) > priorityRank(b.priority)
        case .xp:
            return a.xpReward > b.xpReward
        case .title:
            return a.title.localizedCaseInsensitiveCompare(b.title) == .orderedAscending
        }
    }

    private func priorityRank(_ p: ChorePriority) -> Int {
        switch p {
        case .high:   return 2
        case .normal: return 1
        case .low:    return 0
        }
    }

}

struct FloatingAddButton: View {
    var action: () -> Void
    /// Override the default coral→azure gradient. Used by the Chore
    /// page to swap in its fox-orange / macaw-blue palette.
    var gradient: LinearGradient = Self.defaultGradient

    static let defaultGradient: LinearGradient = LinearGradient(
        colors: [
            Theme.Palette.coral.opacity(0.62),
            Theme.Palette.azure.opacity(0.62)
        ],
        startPoint: .topLeading, endPoint: .bottomTrailing
    )

    var body: some View {
        Button {
            Haptics.medium()
            action()
        } label: {
            Image(systemName: "plus")
                .font(.system(size: 22, weight: .bold))
                .foregroundStyle(.white)
                .frame(width: 60, height: 60)
                .background(
                    ZStack {
                        Circle().fill(.ultraThinMaterial)
                        Circle().fill(gradient)
                    }
                )
                .overlay(
                    Circle().strokeBorder(.white.opacity(0.55), lineWidth: 1)
                )
                .floatingShadow()
        }
        .buttonStyle(.plain)
        .pressable(scale: 0.92)
    }
}
