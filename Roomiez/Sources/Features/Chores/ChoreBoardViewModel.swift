import SwiftUI
import Combine

@MainActor
final class ChoreBoardViewModel: ObservableObject {
    @Published var chores: [Chore] = []
    @Published var isLoading = false
    @Published var error: String?

    private let appState: AppState

    init(appState: AppState) { self.appState = appState }

    var todo:       [Chore] { chores.filter { $0.status == .todo } }
    var inProgress: [Chore] { chores.filter { $0.status == .inProgress } }
    var done:       [Chore] { chores.filter { $0.status == .done } }

    func load() async {
        isLoading = true; defer { isLoading = false }
        // Rotation sweep first — newly materialized assignments should be
        // visible the moment the board appears.
        await ChoreGroupService.runRotation(appState: appState)
        await appState.processOverduePenalties()
        do {
            chores = try await appState.choreRepo.loadChores(
                householdId: appState.household.id
            )
        } catch {
            self.error = error.localizedDescription
        }
    }

    func complete(_ chore: Chore) async {
        var updated = chore
        updated.status = .done
        updated.completedAt = .now
        updated.streak += 1
        updated.lastPenaltyAt = nil
        await save(updated)

        await appState.logEvent(
            kind: .choreCompleted,
            subject: chore.title,
            icon: chore.icon,
            xp: chore.xpReward
        )

        // Streak-bonus + celebration
        if updated.streak > 0, updated.streak % 5 == 0 {
            await appState.logEvent(
                kind: .streakSaved,
                subject: chore.title,
                icon: "flame.fill",
                xp: LevelService.Reward.streakBonus
            )
            appState.celebrate(
                title: "\(updated.streak)-day streak",
                message: "Roaring through \(chore.title.lowercased()).",
                systemImage: "flame.fill",
                tint: Theme.Palette.brick
            )
        } else {
            appState.celebrate(
                title: "+\(chore.xpReward) XP",
                message: "\(chore.title) — well done.",
                systemImage: chore.icon,
                tint: Theme.Palette.forest
            )
        }

        // Recurring chores re-spawn at next due date with the next assignee.
        if chore.recurrence != .once {
            let respawn = Chore(
                id: UUID(),
                householdId: chore.householdId,
                title: chore.title,
                note: chore.note,
                icon: chore.icon,
                status: .todo,
                priority: chore.priority,
                recurrence: chore.recurrence,
                assigneeId: ChoreBoardViewModel.rotatedAssignee(
                    current: chore.assigneeId,
                    rotationOrder: chore.rotationOrder,
                    fallbackMembers: appState.members
                ),
                rotationOrder: chore.rotationOrder,
                xpReward: chore.xpReward,
                dueDate: ChoreBoardViewModel.nextDueDate(from: chore),
                completedAt: nil,
                streak: updated.streak,
                createdAt: .now
            )
            await save(respawn)
        }
    }

    func advance(_ chore: Chore, to status: ChoreStatus) async {
        if status == .done {
            await complete(chore)
            return
        }

        let wasDone = chore.status == .done
        var updated = chore
        updated.status = status
        if wasDone {
            // Reverting a completion — clear the timestamp and back off
            // the streak that completion awarded.
            updated.completedAt = nil
            updated.streak = max(0, updated.streak - 1)
        }
        await save(updated)

        if wasDone {
            await appState.refundChoreXP(chore)
        }
    }

    func add(_ chore: Chore) async {
        await save(chore)
        await appState.logEvent(
            kind: .choreAdded, subject: chore.title,
            icon: chore.icon, xp: 0
        )
        await appState.processOverduePenalties()
    }

    func update(_ chore: Chore) async {
        await save(chore)
        await appState.processOverduePenalties()
    }

    func remove(_ chore: Chore) async {
        do {
            try await appState.choreRepo.delete(chore)
            chores.removeAll { $0.id == chore.id }
        } catch {
            self.error = error.localizedDescription
        }
    }

    /// Persist a brand-new rotation group + its membership, then immediately
    /// run the scheduler so the first cycle's assignment Chore appears
    /// on the board without waiting for the next load().
    func createGroup(_ group: ChoreGroup,
                     members: [ChoreGroupMember]) async {
        do {
            let saved = try await appState.groupRepo.upsert(group)
            try await appState.groupRepo.setMembers(members, for: saved.id)
            await ChoreGroupService.runRotation(appState: appState)
            await appState.logEvent(
                kind: .choreAdded, subject: group.title,
                icon: group.icon, xp: 0
            )
            // Refresh local chore list so the freshly materialized
            // assignment shows up immediately.
            chores = (try? await appState.choreRepo.loadChores(
                householdId: appState.household.id
            )) ?? chores
        } catch {
            self.error = error.localizedDescription
        }
    }

    // MARK: - Helpers

    private func save(_ chore: Chore) async {
        do {
            let saved = try await appState.choreRepo.upsert(chore)
            if let idx = chores.firstIndex(where: { $0.id == saved.id }) {
                chores[idx] = saved
            } else {
                chores.append(saved)
            }
        } catch {
            self.error = error.localizedDescription
        }
    }

    private static func nextDueDate(from chore: Chore) -> Date? {
        let cal = Calendar.current
        let base = chore.dueDate ?? .now
        switch chore.recurrence {
        case .once:     return nil
        case .daily:    return cal.date(byAdding: .day,    value: 1, to: base)
        case .weekly:   return cal.date(byAdding: .day,    value: 7, to: base)
        case .biweekly: return cal.date(byAdding: .day,    value: 14, to: base)
        case .monthly:  return cal.date(byAdding: .month,  value: 1, to: base)
        }
    }

    /// Round-robin rotation. If the chore has a custom `rotationOrder`,
    /// rotate through that explicit sequence; otherwise fall back to the
    /// household's natural member order. Stale IDs (members who have
    /// left) are filtered out automatically.
    private static func rotatedAssignee(
        current: UUID?,
        rotationOrder: [UUID],
        fallbackMembers: [RoomieUser]
    ) -> UUID? {
        let validIds = Set(fallbackMembers.map(\.id))
        let order = rotationOrder.isEmpty
            ? fallbackMembers.map(\.id)
            : rotationOrder.filter { validIds.contains($0) }
        guard !order.isEmpty else { return nil }
        if let current, let idx = order.firstIndex(of: current) {
            return order[(idx + 1) % order.count]
        }
        return order.first
    }
}
