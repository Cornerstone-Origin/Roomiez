import SwiftUI
import Combine

@MainActor
final class DashboardViewModel: ObservableObject {
    @Published var chores: [Chore] = []
    @Published var grocery: [GroceryItem] = []
    @Published var notes: [Note] = []

    private let appState: AppState
    init(appState: AppState) { self.appState = appState }

    var todaysChores: [Chore] {
        chores.filter { chore in
            guard chore.status != .done else { return false }
            guard let due = chore.dueDate else { return false }
            return Calendar.current.isDateInToday(due) || due < .now
        }
        .sorted { (lhs, rhs) in
            let lDate = lhs.dueDate ?? .now
            let rDate = rhs.dueDate ?? .now
            return lDate < rDate
        }
    }

    /// Chores due today (or already overdue) that are assigned to the
    /// signed-in user. Drives the "Today" section on the home page.
    var todaysChoresForMe: [Chore] {
        let myId = appState.currentUser.id
        return todaysChores.filter { $0.assigneeId == myId }
    }

    var groceryPreview: [GroceryItem] {
        Array(grocery.filter { !$0.isChecked }.prefix(4))
    }

    var notesPreview: [Note] {
        Array(notes.sorted { $0.updatedAt > $1.updatedAt }.prefix(3))
    }

    var greeting: String {
        let hour = Calendar.current.component(.hour, from: .now)
        switch hour {
        case 5..<12:  return "Good morning, Roomies."
        case 12..<17: return "Afternoon, Roomies."
        case 17..<21: return "Evening, Roomies."
        default:      return "Late night, Roomies."
        }
    }

    var subtitle: String {
        if appState.household.harmony > 0.75 {
            return "The house is in great rhythm."
        } else if appState.household.harmony > 0.45 {
            return "Steady week. A few small wins ahead."
        } else {
            return "A few small chores would lift things up."
        }
    }

    // MARK: - Stats

    /// Start of this calendar week.
    private var startOfWeek: Date {
        let cal = Calendar.current
        let comps = cal.dateComponents([.yearForWeekOfYear, .weekOfYear],
                                       from: .now)
        return cal.date(from: comps) ?? .now.startOfDay
    }

    /// Count of chores assigned to `memberId` that this week's
    /// completion stamp falls within.
    func completedThisWeek(by memberId: UUID) -> Int {
        chores.filter { chore in
            chore.status == .done
                && chore.assigneeId == memberId
                && (chore.completedAt ?? .distantPast) >= startOfWeek
        }.count
    }

    /// Total completions across the whole household this week.
    var totalCompletedThisWeek: Int {
        chores.filter {
            $0.status == .done
                && ($0.completedAt ?? .distantPast) >= startOfWeek
        }.count
    }

    /// Chores past their due date that haven't been done.
    var overdueChores: [Chore] {
        let today = Date.now.startOfDay
        return chores.filter { chore in
            guard chore.status != .done, let due = chore.dueDate else {
                return false
            }
            return due < today
        }
        .sorted { ($0.dueDate ?? .distantPast) < ($1.dueDate ?? .distantPast) }
    }

    func load() async {
        // Rotation sweep first so any newly auto-assigned chore appears in
        // the Today section the moment the dashboard refreshes.
        await ChoreGroupService.runRotation(appState: appState)
        await appState.processOverduePenalties()
        self.chores  = (try? await appState.choreRepo.loadChores(householdId: appState.household.id)) ?? []
        self.grocery = (try? await appState.groceryRepo.loadItems(householdId: appState.household.id)) ?? []
        self.notes   = (try? await appState.noteRepo.loadNotes(householdId: appState.household.id)) ?? []
    }

    func completeChore(_ chore: Chore) async {
        var updated = chore
        updated.status = .done
        updated.completedAt = .now
        updated.streak += 1
        _ = try? await appState.choreRepo.upsert(updated)
        if let idx = chores.firstIndex(where: { $0.id == chore.id }) {
            chores[idx] = updated
        }
        await appState.logEvent(
            kind: .choreCompleted, subject: chore.title,
            icon: chore.icon, xp: chore.xpReward
        )
        appState.celebrate(
            title: "+\(chore.xpReward) XP",
            message: "\(chore.title) done — house thanks you.",
            systemImage: chore.icon,
            tint: Theme.Palette.forest
        )
    }
}
