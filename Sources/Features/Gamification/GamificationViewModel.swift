import SwiftUI
import Combine

@MainActor
final class GamificationViewModel: ObservableObject {
    @Published var allAchievements: [Achievement] = AchievementCatalog.all
    @Published var unlocked: [Achievement] = []

    private let appState: AppState
    init(appState: AppState) { self.appState = appState }

    func load() async {
        do {
            unlocked = try await appState.achievementRepo
                .unlocked(householdId: appState.household.id)
        } catch {
            unlocked = []
        }
    }

    func mergedCatalog() -> [Achievement] {
        allAchievements.map { item in
            if let live = unlocked.first(where: { $0.key == item.key }) {
                return live
            }
            return item
        }
    }
}
