import SwiftUI

struct GroceryListView: View {
    @EnvironmentObject private var appState: AppState
    @StateObject private var vm: GroceryViewModel
    @State private var showingAdd = false
    @State private var showingHistory = false
    @State private var editing: GroceryItem? = nil
    @State private var hideChecked = false
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

                    if vm.items.isEmpty {
                        EmptyStateView(
                            systemImage: "basket.fill",
                            tint: Theme.Palette.ochre,
                            title: "No baskets yet",
                            subtitle: "Type above to quick-add an item — it'll land in a basket.",
                            actionTitle: "Add item"
                        ) { showingAdd = true }
                        .padding(.top, 40)
                    } else if basketsToShow.isEmpty {
                        emptyFilterState
                    } else {
                        LazyVGrid(columns: basketColumns, spacing: 14) {
                            ForEach(basketsToShow, id: \.0) { (category, items) in
                                GroceryBasketCard(
                                    category: category,
                                    items: items,
                                    onToggle: { item in
                                        Task { await vm.toggle(item) }
                                    },
                                    onTapItem: { item in editing = item },
                                    onRemove: { item in
                                        Task { await vm.remove(item) }
                                    }
                                )
                                .transition(.scale.combined(with: .opacity))
                            }
                        }
                        .animation(Theme.Motion.spring, value: vm.items)

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

    // MARK: - Basket grid layout

    private let basketColumns: [GridItem] = [
        GridItem(.flexible(), spacing: 14, alignment: .top),
        GridItem(.flexible(), spacing: 14, alignment: .top)
    ]

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
            Image(systemName: "eye.slash.fill")
                .font(.system(size: 28, weight: .bold))
                .foregroundStyle(Theme.Palette.textSoft.opacity(0.6))
            Text("Every basket is empty")
                .font(.cozyHeadline)
                .foregroundStyle(Theme.Palette.text)
            Text("Toggle \"hide checked\" off or clear the search box to see the rest.")
                .font(.cozyCaption)
                .foregroundStyle(Theme.Palette.textSoft)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 28)
    }

    // MARK: - Derived data

    /// Baskets to render in the grid: one per category that currently
    /// has items. Applies the "hide checked" toggle and respects the
    /// smart-input search filter (which the view model already folded
    /// into `vm.grouped`).
    private var basketsToShow: [(GroceryCategory, [GroceryItem])] {
        vm.grouped.compactMap { (cat, items) in
            let visible = hideChecked
                ? items.filter { !$0.isChecked }
                : items
            return visible.isEmpty ? nil : (cat, visible)
        }
    }
}
