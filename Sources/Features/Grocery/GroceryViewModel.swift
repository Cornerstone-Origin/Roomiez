import SwiftUI
import Combine

@MainActor
final class GroceryViewModel: ObservableObject {
    @Published var items: [GroceryItem] = []
    @Published var search: String = ""
    @Published var error: String?

    private let appState: AppState
    init(appState: AppState) { self.appState = appState }

    var grouped: [(GroceryCategory, [GroceryItem])] {
        let filtered = items.filter {
            search.isEmpty
            || $0.title.localizedCaseInsensitiveContains(search)
            || ($0.brand?.localizedCaseInsensitiveContains(search) ?? false)
        }
        let sorted = filtered.sorted { lhs, rhs in
            if lhs.isChecked != rhs.isChecked { return !lhs.isChecked }
            return lhs.addedAt > rhs.addedAt
        }
        let dict = Dictionary(grouping: sorted, by: \.category)
        return GroceryCategory.allCases.compactMap { cat in
            guard let arr = dict[cat], !arr.isEmpty else { return nil }
            return (cat, arr)
        }
    }

    var totalRemaining: Int { items.filter { !$0.isChecked }.count }

    func load() async {
        do {
            items = try await appState.groceryRepo.loadItems(
                householdId: appState.household.id
            )
        } catch { self.error = error.localizedDescription }
    }

    func toggle(_ item: GroceryItem) async {
        var updated = item
        updated.isChecked.toggle()
        await save(updated)
        if updated.isChecked {
            await appState.logEvent(
                kind: .groceryChecked, subject: item.title,
                icon: item.category.icon,
                xp: LevelService.Reward.groceryItemChecked
            )
        }
    }

    func add(_ item: GroceryItem) async {
        await save(item)
        await appState.logEvent(
            kind: .groceryAdded, subject: item.title,
            icon: item.category.icon,
            xp: LevelService.Reward.groceryItemAdded
        )
    }

    func update(_ item: GroceryItem) async { await save(item) }

    func remove(_ item: GroceryItem) async {
        do {
            try await appState.groceryRepo.delete(item)
            items.removeAll { $0.id == item.id }
        } catch { self.error = error.localizedDescription }
    }

    func clearChecked() async {
        let checked = items.filter(\.isChecked)
        for item in checked { await remove(item) }
        Haptics.success()
    }

    private func save(_ item: GroceryItem) async {
        do {
            let saved = try await appState.groceryRepo.upsert(item)
            if let idx = items.firstIndex(where: { $0.id == saved.id }) {
                items[idx] = saved
            } else {
                items.append(saved)
            }
        } catch { self.error = error.localizedDescription }
    }
}
