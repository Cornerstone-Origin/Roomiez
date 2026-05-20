import Foundation
import os

/// Weekly (and biweekly / monthly) rotation scheduler for chore groups.
///
/// Stateless — every entry point takes the `AppState` it operates on.
/// Modeled after `LevelService`: pure math helpers + one orchestration
/// method that mutates state through the repository layer.
///
/// The single biggest design call: a "group assignment" is just a row in
/// the existing `chores` table tagged with `groupId` + `cycleAnchor`. That
/// way the existing chore board, XP economy, overdue penalty, streak, and
/// activity feed all work on group assignments unchanged.
enum ChoreGroupService {

    // MARK: - Cycle math (pure)

    /// The anchor (start) of the cycle that contains `date`, for the
    /// given frequency.
    ///
    /// • Weekly / biweekly → 00:00 on the most recent Monday on/before
    ///   `date`. Biweekly aligns to the same Monday boundaries — there's
    ///   no separate "biweekly epoch," the scheduler advances 14 days at a
    ///   time so cycles stay aligned naturally.
    /// • Monthly → 00:00 on the 1st of the month containing `date`.
    static func cycleAnchor(for frequency: GroupFrequency,
                            containing date: Date,
                            calendar: Calendar = .current) -> Date {
        var cal = calendar
        // Monday-first week so cycles match the project's mental model.
        cal.firstWeekday = 2
        switch frequency {
        case .weekly, .biweekly:
            let comps = cal.dateComponents([.yearForWeekOfYear, .weekOfYear],
                                           from: date)
            return cal.date(from: comps) ?? cal.startOfDay(for: date)
        case .monthly:
            let comps = cal.dateComponents([.year, .month], from: date)
            return cal.date(from: comps) ?? cal.startOfDay(for: date)
        }
    }

    /// Due date for an assignment whose cycle starts at `anchor`. The
    /// chore is due by end-of-day on the last day of the cycle — that
    /// keeps "this week" / "today" filters trivial.
    static func dueDate(for frequency: GroupFrequency,
                        cycleAnchor anchor: Date,
                        calendar: Calendar = .current) -> Date {
        var cal = calendar
        cal.firstWeekday = 2
        let days = frequency.cycleDays
        let end = cal.date(byAdding: .day, value: days - 1, to: anchor) ?? anchor
        // 23:59:59 on the last day of the cycle.
        return cal.date(bySettingHour: 23, minute: 59, second: 59,
                        of: end) ?? end
    }

    /// Pick the next assignee for a group without mutating state.
    /// Returns the picked member, the rotation index the group should
    /// advance to, and whether the shuffle bag was emptied (and needs to
    /// be reset). Returns nil if the group has no live members.
    static func nextAssignee(
        group: ChoreGroup,
        members: [ChoreGroupMember],
        householdMembers: [RoomieUser]
    ) -> (assignee: ChoreGroupMember,
          advancedIndex: Int,
          bagReset: Bool)? {

        let valid = Set(householdMembers.map(\.id))
        let live  = members.filter { valid.contains($0.userId) }
        guard !live.isEmpty else { return nil }

        switch group.rotationStyle {
        case .classic, .custom:
            // Both styles use order_index. .custom is just a user-authored
            // order; the algorithm is identical from here on.
            let sorted = live.sorted { $0.orderIndex < $1.orderIndex }
            let idx = ((group.rotationIndex % sorted.count) + sorted.count)
                        % sorted.count
            let pick = sorted[idx]
            let next = (idx + 1) % sorted.count
            return (pick, next, false)

        case .shuffle:
            // "Bag" shuffle — everyone goes once before anyone repeats.
            let unpicked = live.filter { !$0.bagPicked }
            if let pick = unpicked.randomElement() {
                return (pick, group.rotationIndex, false)
            }
            // Bag empty → reshuffle, pick fresh, and signal a bag reset.
            guard let pick = live.randomElement() else { return nil }
            return (pick, group.rotationIndex, true)
        }
    }

    // MARK: - Scheduler

    /// Sweep all unpaused groups, materializing one assignment Chore per
    /// missed cycle. Idempotent — safe to call on every app load and
    /// inside every view-model `load()`. The unique `(group_id,
    /// cycle_anchor)` index on `chores` is the ultimate safety net; the
    /// `last_assigned_at` fast-path lets us short-circuit on the hot path.
    @MainActor
    static func runRotation(appState: AppState, now: Date = .now) async {
        let groupRepo = appState.groupRepo

        let groups: [ChoreGroup]
        do {
            groups = try await groupRepo.loadGroups(
                householdId: appState.household.id
            )
        } catch {
            Log.app.error("runRotation loadGroups failed: \(error.localizedDescription, privacy: .public)")
            return
        }

        let householdMembers = appState.members
        var cal = Calendar.current
        cal.firstWeekday = 2

        for group in groups {
            await processGroup(
                group,
                now: now,
                calendar: cal,
                householdMembers: householdMembers,
                appState: appState,
                groupRepo: groupRepo
            )
        }
    }

    @MainActor
    private static func processGroup(
        _ group: ChoreGroup,
        now: Date,
        calendar cal: Calendar,
        householdMembers: [RoomieUser],
        appState: AppState,
        groupRepo: any ChoreGroupRepository
    ) async {
        guard !group.isPaused else { return }
        if let until = group.pausedUntil, until > now { return }

        let currentAnchor = cycleAnchor(for: group.frequency, containing: now)

        // Has this cycle already been served? Fast path before touching DB.
        if let last = group.lastAssignedAt {
            let lastAnchor = cycleAnchor(for: group.frequency, containing: last)
            if lastAnchor >= currentAnchor { return }
        }
        // Not yet due (start_date in the future).
        guard currentAnchor >= cycleAnchor(for: group.frequency,
                                           containing: group.nextDueAt)
        else { return }

        let members: [ChoreGroupMember]
        do {
            members = try await groupRepo.loadMembers(groupId: group.id)
        } catch {
            Log.app.error("runRotation loadMembers failed: \(error.localizedDescription, privacy: .public)")
            return
        }

        guard let pick = nextAssignee(
            group: group,
            members: members,
            householdMembers: householdMembers
        ) else { return }

        // 1 — Materialize the assignment as a regular Chore.
        let assignment = Chore(
            id: UUID(),
            householdId: group.householdId,
            title: group.title,
            note: group.note,
            icon: group.icon,
            status: .todo,
            priority: group.priority,
            recurrence: .once,            // the group owns recurrence
            assigneeId: pick.assignee.userId,
            rotationOrder: [],            // the group owns rotation
            xpReward: group.xpReward,
            difficulty: group.difficulty,
            dueDate: dueDate(for: group.frequency, cycleAnchor: currentAnchor),
            completedAt: nil,
            streak: 0,
            createdAt: now,
            lastPenaltyAt: nil,
            groupId: group.id,
            cycleAnchor: currentAnchor,
            autoAssigned: true
        )
        do {
            _ = try await appState.choreRepo.upsert(assignment)
        } catch {
            // Unique-index conflict on (group_id, cycle_anchor) is the
            // intended idempotency guard — another device beat us to it.
            // Either way we should still advance our local pointer so we
            // don't hammer the DB next call. Log and continue.
            Log.app.info("runRotation skipped (race or duplicate): \(error.localizedDescription, privacy: .public)")
        }

        // 2 — Advance the group's rotation bookkeeping.
        var advanced = group
        advanced.rotationIndex = pick.advancedIndex
        advanced.lastAssignedAt = now
        advanced.nextDueAt = cal.date(
            byAdding: .day,
            value: group.frequency.cycleDays,
            to: currentAnchor
        ) ?? currentAnchor

        do {
            _ = try await groupRepo.upsert(advanced)
            if pick.bagReset {
                try await groupRepo.resetBag(groupId: group.id)
            }
            try await groupRepo.markPicked(
                groupId: group.id,
                userId: pick.assignee.userId
            )
        } catch {
            Log.app.error("runRotation advance failed: \(error.localizedDescription, privacy: .public)")
        }

        // 3 — Activity feed entry so roommates see who's up.
        let assigneeName = householdMembers
            .first(where: { $0.id == pick.assignee.userId })?
            .displayName ?? "Someone"
        await appState.logSystemEvent(
            kind: .choreAssigned,
            subject: "\(group.title) → \(assigneeName)",
            icon: group.icon,
            xpDelta: 0,
            actorId: nil
        )
    }
}
