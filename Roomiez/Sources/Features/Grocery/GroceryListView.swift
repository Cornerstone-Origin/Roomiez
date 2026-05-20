import SwiftUI

struct GroceryListView: View {
    @EnvironmentObject private var appState: AppState
    @StateObject private var vm: GroceryViewModel
    @State private var showingAdd = false
    @State private var showingHistory = false
    @State private var editing: GroceryItem? = nil
    @State private var hideChecked = false
    @State private var categoryFilter: GroceryCategory? = nil
    @State private var quickAddCategory: GroceryCategory = .produce
    @FocusState private var inputFocused: Bool

    init(appState: AppState) {
        _vm = StateObject(wrappedValue: GroceryViewModel(appState: appState))
    }

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            PearlBackground()

            ScrollView {
                VStack(alignment: .leading, spacing: Theme.Spacing.md) {
                    header
                    smartInputBar
                    if !presentCategories.isEmpty {
                        categoryFilterRow
                    }

                    if vm.items.isEmpty {
                        EmptyStateView(
                            systemImage: "cart.fill",
                            tint: Theme.Palette.ochre,
                            title: "Your list is empty",
                            subtitle: "Type above to quick-add, or use + for full details.",
                            actionTitle: "Add item"
                        ) { showingAdd = true }
                        .padding(.top, 40)
                    } else if displayGrouped.isEmpty {
                        emptyFilterState
                    } else {
                        ForEach(displayGrouped, id: \.0) { (category, list) in
                            categorySection(category: category, items: list)
                        }
                        if vm.items.contains(where: \.isChecked) {
                            clearCheckedButton
                        }
                    }
                }
                .padding(.horizontal, Theme.Spacing.md)
                .padding(.top, Theme.Spacing.sm)
                .padding(.bottom, FloatingButtonClearance.bottom + 60)
            }
            .refreshable { await vm.load() }

            FloatingAddButton { showingAdd = true }
                .padding(.trailing, 20).padding(.bottom, FloatingButtonClearance.bottom)
        }
        .task { await vm.load() }
        .sheet(isPresented: $showingAdd) {
            AddGrocerySheet(initial: nil) { item in
                Task { await vm.add(item) }
            }
            .presentationDetents([.medium, .large])
            .presentationCornerRadius(28)
        }
        .sheet(item: $editing) { item in
            AddGrocerySheet(initial: item) { updated in
                Task { await vm.update(updated) }
            }
            .presentationDetents([.medium, .large])
            .presentationCornerRadius(28)
        }
        .sheet(isPresented: $showingHistory) {
            GroceryHistorySheet()
                .presentationDetents([.large])
                .presentationCornerRadius(28)
        }
    }

    // MARK: - Header

    private var header: some View {
        let done  = vm.items.count - vm.totalRemaining
        let total = vm.items.count
        let progress = total > 0 ? Double(done) / Double(total) : 0
        return VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .center, spacing: 8) {
                Text("Grocery")
                    .font(.cozyDisplay)
                    .foregroundStyle(Theme.Palette.text)
                Spacer()
                historyButton
                hideCheckedToggle
            }

            if total > 0 {
                HStack(spacing: 6) {
                    Text("\(vm.totalRemaining) to buy")
                        .font(.cozy(13, weight: .semibold))
                        .foregroundStyle(Theme.Palette.text)
                    if done > 0 {
                        Text("·").foregroundStyle(Theme.Palette.textSoft)
                        Text("\(done) done")
                            .font(.cozy(13, weight: .semibold))
                            .foregroundStyle(Theme.Palette.textSoft)
                    }
                    Spacer()
                }
                GeometryReader { proxy in
                    ZStack(alignment: .leading) {
                        Capsule().fill(Theme.Palette.divider.opacity(0.6))
                        Capsule()
                            .fill(LinearGradient(
                                colors: [Theme.Palette.coral, Theme.Palette.marigold],
                                startPoint: .leading, endPoint: .trailing
                            ))
                            .frame(width: max(6, proxy.size.width * progress))
                    }
                }
                .frame(height: 6)
            }
        }
    }

    private var historyButton: some View {
        Button {
            Haptics.selection()
            showingHistory = true
        } label: {
            Image(systemName: "clock.arrow.circlepath")
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(Theme.Palette.text)
                .frame(width: 32, height: 32)
                .background(Circle().fill(Theme.Palette.surface))
                .overlay(Circle().stroke(Theme.Palette.divider, lineWidth: 1))
        }
        .buttonStyle(.plain)
    }

    private var hideCheckedToggle: some View {
        Button {
            Haptics.selection()
            withAnimation(Theme.Motion.spring) { hideChecked.toggle() }
        } label: {
            Image(systemName: hideChecked ? "eye.slash.fill" : "eye.fill")
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(hideChecked ? .white : Theme.Palette.text)
                .frame(width: 32, height: 32)
                .background(
                    Circle().fill(hideChecked
                                  ? Theme.Palette.text
                                  : Theme.Palette.surface)
                )
                .overlay(Circle().stroke(Theme.Palette.divider, lineWidth: 1))
        }
        .buttonStyle(.plain)
    }

    // MARK: - Smart input bar (search + quick add)

    private var smartInputBar: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(Theme.Palette.textSoft)
            TextField("Add or search…", text: $vm.search)
                .font(.cozyBody)
                .focused($inputFocused)
                .submitLabel(.send)
                .onSubmit { addQuickItem() }
            if !vm.search.isEmpty {
                Button {
                    vm.search = ""
                    inputFocused = false
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(Theme.Palette.textSoft)
                }
                .buttonStyle(.plain)

                // Category picker + add — fires on tap (uses currently
                // selected `quickAddCategory`), or long-press a menu item
                // to override the category for this one item.
                Menu {
                    Picker("Add to", selection: $quickAddCategory) {
                        ForEach(GroceryCategory.allCases) { cat in
                            Label(cat.title, systemImage: cat.icon).tag(cat)
                        }
                    }
                    Button("Add to \(quickAddCategory.title)") { addQuickItem() }
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "plus")
                            .font(.system(size: 12, weight: .bold))
                        Image(systemName: quickAddCategory.icon)
                            .font(.system(size: 12, weight: .bold))
                    }
                    .foregroundStyle(.white)
                    .padding(.horizontal, 10).padding(.vertical, 6)
                    .background(Capsule().fill(quickAddCategory.tint))
                }
                .simultaneousGesture(TapGesture().onEnded { addQuickItem() })
            }
        }
        .padding(.horizontal, 14).padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: Theme.Radius.md, style: .continuous)
                .fill(Theme.Palette.surface)
        )
        .overlay(
            RoundedRectangle(cornerRadius: Theme.Radius.md, style: .continuous)
                .stroke(Theme.Palette.divider, lineWidth: 1)
        )
    }

    private func addQuickItem() {
        let trimmed = vm.search.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        let item = GroceryItem(
            id: UUID(),
            householdId: appState.household.id,
            title: trimmed,
            brand: nil,
            quantity: nil,
            category: quickAddCategory,
            isChecked: false,
            addedById: appState.currentUser.id,
            photoURL: nil,
            addedAt: .now
        )
        Task { await vm.add(item) }
        Haptics.success()
        vm.search = ""
        inputFocused = false
    }

    // MARK: - Category filter chips

    private var categoryFilterRow: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                filterChip(title: "All",
                           icon: "tray.full.fill",
                           tint: Theme.Palette.text,
                           count: vm.totalRemaining,
                           isSelected: categoryFilter == nil) {
                    categoryFilter = nil
                }
                ForEach(presentCategories) { cat in
                    filterChip(title: cat.title,
                               icon: cat.icon,
                               tint: cat.tint,
                               count: remainingCount(in: cat),
                               isSelected: categoryFilter == cat) {
                        categoryFilter = (categoryFilter == cat) ? nil : cat
                    }
                }
            }
            .padding(.horizontal, 2)
            .padding(.vertical, 2)
        }
    }

    private func filterChip(title: String, icon: String, tint: Color,
                            count: Int, isSelected: Bool,
                            onTap: @escaping () -> Void) -> some View {
        Button(action: { Haptics.selection(); onTap() }) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 11, weight: .bold))
                Text(title)
                    .font(.cozy(12, weight: .semibold))
                    .lineLimit(1)
                if count > 0 {
                    Text("\(count)")
                        .font(.cozy(10, weight: .bold))
                        .padding(.horizontal, 5).padding(.vertical, 1)
                        .background(Capsule().fill(
                            isSelected
                                ? Color.white.opacity(0.30)
                                : tint.opacity(0.20)
                        ))
                }
            }
            .foregroundStyle(isSelected ? .white : tint)
            .padding(.horizontal, 10).padding(.vertical, 7)
            .background(
                Capsule().fill(isSelected ? tint : Theme.Palette.surface)
            )
            .overlay(
                Capsule().stroke(tint.opacity(isSelected ? 0 : 0.35),
                                 lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Categories / rows

    private func categorySection(category: GroceryCategory,
                                 items: [GroceryItem]) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 10) {
                Image(systemName: category.icon)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(category.tint)
                    .frame(width: 28, height: 28)
                    .background(
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .fill(category.tint.opacity(0.18))
                    )
                Text(category.title)
                    .font(.cozyHeadline)
                    .foregroundStyle(Theme.Palette.text)
                Spacer()
                Text("\(items.count)")
                    .font(.cozyTag)
                    .padding(.horizontal, 8).padding(.vertical, 2)
                    .background(Capsule().fill(category.tint.opacity(0.20)))
                    .foregroundStyle(category.tint)
            }
            VStack(spacing: 8) {
                ForEach(items) { item in
                    GroceryItemRow(
                        item: item,
                        addedBy: appState.member(id: item.addedById),
                        onToggle: { Task { await vm.toggle(item) } },
                        onTap: { editing = item }
                    )
                    .contextMenu {
                        Button(role: .destructive) {
                            Task { await vm.remove(item) }
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    }
                    .transition(.opacity.combined(with: .move(edge: .leading)))
                }
            }
            .animation(Theme.Motion.spring, value: items)
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: Theme.Radius.lg, style: .continuous)
                .fill(category.tint.opacity(0.12))
        )
        .overlay(
            RoundedRectangle(cornerRadius: Theme.Radius.lg, style: .continuous)
                .stroke(category.tint.opacity(0.30), lineWidth: 1)
        )
    }

    // MARK: - Bottom button / empty filter

    private var clearCheckedButton: some View {
        Button {
            Task { await vm.clearChecked() }
        } label: {
            Label("Clear checked items",
                  systemImage: "checkmark.circle.trianglebadge.exclamationmark")
                .font(.cozyCaption)
                .foregroundStyle(Theme.Palette.textSoft)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(
                    RoundedRectangle(cornerRadius: Theme.Radius.md,
                                     style: .continuous)
                        .fill(Theme.Palette.surface.opacity(0.8))
                )
        }
        .buttonStyle(.plain)
    }

    private var emptyFilterState: some View {
        VStack(spacing: 8) {
            Image(systemName: "line.3.horizontal.decrease.circle")
                .font(.system(size: 28, weight: .bold))
                .foregroundStyle(Theme.Palette.textSoft.opacity(0.6))
            Text("Nothing matches")
                .font(.cozyHeadline)
                .foregroundStyle(Theme.Palette.text)
            Text("Try a different filter, or clear the search box.")
                .font(.cozyCaption)
                .foregroundStyle(Theme.Palette.textSoft)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 28)
    }

    // MARK: - Derived data

    /// Categories that currently contain at least one item.
    private var presentCategories: [GroceryCategory] {
        let used = Set(vm.items.map(\.category))
        return GroceryCategory.allCases.filter { used.contains($0) }
    }

    private func remainingCount(in cat: GroceryCategory) -> Int {
        vm.items.filter { $0.category == cat && !$0.isChecked }.count
    }

    /// The grouped list after the active category filter and the
    /// "hide checked" toggle are applied.
    private var displayGrouped: [(GroceryCategory, [GroceryItem])] {
        var groups = vm.grouped
        if let cat = categoryFilter {
            groups = groups.filter { $0.0 == cat }
        }
        if hideChecked {
            groups = groups.compactMap { (cat, items) in
                let remaining = items.filter { !$0.isChecked }
                return remaining.isEmpty ? nil : (cat, remaining)
            }
        }
        return groups
    }
}
