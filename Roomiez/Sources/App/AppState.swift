import SwiftUI
import Combine
import os

/// App-wide observable state. Holds the current user, household, and acts as
/// the dependency container for repositories and the realtime service.
///
/// Feature ViewModels reach for this via `@EnvironmentObject` and call into
/// repositories — they never instantiate Supabase directly.
@MainActor
final class AppState: ObservableObject {

    // MARK: Session

    @Published var currentUser: RoomieUser
    @Published var household: Household
    @Published var members: [RoomieUser]
    @Published var recentActivity: [ActivityEvent] = []
    @Published var unlockedAchievements: [Achievement] = []

    // MARK: Celebration

    @Published var celebration: Celebration? = nil
    struct Celebration: Identifiable, Equatable {
        let id = UUID()
        let title: String
        let message: String
        /// SF Symbol name shown inside the medallion.
        let systemImage: String
        /// Background tint for the medallion.
        let tint: Color
    }

    // MARK: Dependencies

    let choreRepo:        any ChoreRepository
    let groceryRepo:      any GroceryRepository
    let noteRepo:         any NoteRepository
    let householdRepo:    any HouseholdRepository
    let achievementRepo:  any AchievementRepository
    let groupRepo:        any ChoreGroupRepository
    let realtime:         RealtimeService

    // MARK: Init

    init() {
        let supabase = SupabaseManager.shared
        self.realtime = RealtimeService(manager: supabase)

        if let client = supabase.client {
            let repo = SupabaseRepositories(client: client)
            self.choreRepo       = repo
            self.groceryRepo     = repo
            self.noteRepo        = repo
            self.householdRepo   = repo
            self.achievementRepo = repo
            self.groupRepo       = repo
        } else {
            let repo = LocalSeedRepositories()
            self.choreRepo       = repo
            self.groceryRepo     = repo
            self.noteRepo        = repo
            self.householdRepo   = repo
            self.achievementRepo = repo
            self.groupRepo       = repo
        }

        // Optimistic UI: hydrate from seed immediately, then async refresh
        // pulls in real Supabase data if it's available.
        self.currentUser = PreviewData.currentUser
        self.household   = PreviewData.household
        self.members     = PreviewData.users

        Task { await initialLoad() }
    }

    // MARK: - Initial / refresh

    func initialLoad() async {
        // All repos are @MainActor — sequential awaits keep us on the same
        // actor and avoid Sendable-crossing constraints.
        do {
            self.household           = try await householdRepo.load(householdId: household.id)
            self.members             = try await householdRepo.members(householdId: household.id)
            self.recentActivity      = try await householdRepo.activity(householdId: household.id, limit: 25)
            self.unlockedAchievements = try await achievementRepo.unlocked(householdId: household.id)
        } catch {
            Log.app.error("initialLoad failed: \(error.localizedDescription, privacy: .public)")
        }

        // Materialize any rotation assignments for the current cycle *before*
        // the overdue sweep — otherwise a fresh assignment due today could
        // be penalized for being late on a prior, unrelated due date.
        await ChoreGroupService.runRotation(appState: self)

        await processOverduePenalties()

        await realtime.start(for: household.id) { [weak self] in
            Task { @MainActor in await self?.refreshActivityAndHousehold() }
        }
    }

    /// Public wrapper around `persistActivity` so services outside
    /// `AppState` (e.g. `ChoreGroupService`) can log bookkeeping events
    /// without touching XP / harmony.
    func logSystemEvent(kind: ActivityKind,
                        subject: String,
                        icon: String,
                        xpDelta: Int,
                        actorId: UUID?) async {
        await persistActivity(
            kind: kind, subject: subject,
            icon: icon, xpDelta: xpDelta,
            actorId: actorId
        )
    }

    func refreshActivityAndHousehold() async {
        do {
            self.household      = try await householdRepo.load(householdId: household.id)
            self.recentActivity = try await householdRepo.activity(householdId: household.id, limit: 25)
        } catch {
            Log.app.error("refresh failed: \(error.localizedDescription, privacy: .public)")
        }
    }

    // MARK: - Mutations / XP plumbing

    func logEvent(kind: ActivityKind, subject: String, icon: String, xp: Int) async {
        let event = ActivityEvent(
            id: UUID(), householdId: household.id,
            actorId: currentUser.id, kind: kind, subject: subject,
            icon: icon, xpDelta: xp, createdAt: .now
        )

        try? await householdRepo.log(event: event)
        recentActivity.insert(event, at: 0)

        // Bump personal XP, house XP, and harmony.
        currentUser.personalXP += xp
        let prevLevel = household.level
        let newHarmony = min(1.0, household.harmony + LevelService.harmonyDelta(for: kind))
        let harmonyXP  = max(xp, 0)
        try? await householdRepo.updateHarmony(
            householdId: household.id,
            harmony: newHarmony,
            xpDelta: harmonyXP
        )
        household.harmony = newHarmony
        household.houseXP += harmonyXP
        await recordLevelChange(from: prevLevel, actorId: currentUser.id)
    }

    /// Persist a one-off event without touching XP / harmony. Used for
    /// bookkeeping kinds (level changes, overdue penalties, reverts).
    private func persistActivity(kind: ActivityKind,
                                 subject: String,
                                 icon: String,
                                 xpDelta: Int,
                                 actorId: UUID?) async {
        let event = ActivityEvent(
            id: UUID(),
            householdId: household.id,
            actorId: actorId,
            kind: kind, subject: subject,
            icon: icon, xpDelta: xpDelta, createdAt: .now
        )
        try? await householdRepo.log(event: event)
        recentActivity.insert(event, at: 0)
    }

    /// Compare the level before and after an XP mutation; log a
    /// `.levelUp` or `.levelDown` activity event if it crossed a
    /// threshold.
    private func recordLevelChange(from oldLevel: Int,
                                   actorId: UUID?) async {
        let newLevel = household.level
        guard newLevel != oldLevel else { return }
        await persistActivity(
            kind: newLevel > oldLevel ? .levelUp : .levelDown,
            subject: household.levelTitle,
            icon: household.tier.icon,
            xpDelta: 0,
            actorId: actorId
        )
    }

    func celebrate(title: String,
                   message: String,
                   systemImage: String = "checkmark.seal.fill",
                   tint: Color = Theme.Palette.forest) {
        withAnimation(Theme.Motion.spring) {
            celebration = Celebration(
                title: title, message: message,
                systemImage: systemImage,
                tint: tint
            )
        }
        Haptics.success()
        Task {
            try? await Task.sleep(nanoseconds: 2_400_000_000)
            withAnimation(Theme.Motion.gentle) { self.celebration = nil }
        }
    }

    // MARK: Chore reversal

    /// Refund the XP and harmony that were awarded when a chore was
    /// completed — used when the user moves a chore from Done back to
    /// To Do / In Progress. The xpReward is subtracted from house XP
    /// and the corresponding harmony delta is rolled back.
    func refundChoreXP(_ chore: Chore) async {
        let xpRefund = chore.xpReward
        guard xpRefund > 0 else { return }
        let prevLevel  = household.level
        let newXP      = max(0, household.houseXP - xpRefund)
        let newHarmony = max(0, household.harmony
                              - LevelService.harmonyDelta(for: .choreCompleted))
        do {
            try await householdRepo.updateHarmony(
                householdId: household.id,
                harmony: newHarmony,
                xpDelta: -xpRefund
            )
            household.houseXP = newXP
            household.harmony = newHarmony
            await persistActivity(
                kind: .choreReverted,
                subject: chore.title,
                icon: chore.icon,
                xpDelta: -xpRefund,
                actorId: currentUser.id
            )
            await recordLevelChange(from: prevLevel, actorId: currentUser.id)
        } catch {
            Log.app.error("refundChoreXP failed: \(error.localizedDescription, privacy: .public)")
        }
    }

    // MARK: Overdue penalties

    /// Walk every active chore and, for any whose `dueDate` is in the
    /// past, deduct the day-by-day XP penalty that has accumulated
    /// since the last time we charged the chore. The deduction
    /// compounds: day 1 overdue costs 10% of the chore's XP, day 2
    /// costs 20%, … capped at 100%/day. `lastPenaltyAt` on each chore
    /// tracks the last day already accounted for so the same penalty
    /// is never applied twice.
    func processOverduePenalties() async {
        let cal = Calendar.current
        let today = cal.startOfDay(for: .now)

        do {
            let chores = try await choreRepo.loadChores(householdId: household.id)
            var totalPenalty = 0
            var updates: [Chore] = []
            var entries: [(chore: Chore, penalty: Int)] = []

            for chore in chores {
                guard chore.status != .done,
                      let due = chore.dueDate else { continue }
                let dueDay = cal.startOfDay(for: due)
                let daysOverdue = cal.dateComponents([.day],
                                                     from: dueDay,
                                                     to: today).day ?? 0
                guard daysOverdue > 0 else { continue }

                let lastPenalizedDay: Int = {
                    guard let last = chore.lastPenaltyAt else { return 0 }
                    let lastDay = cal.startOfDay(for: last)
                    return max(0, cal.dateComponents([.day],
                                                     from: dueDay,
                                                     to: lastDay).day ?? 0)
                }()

                let penalty = LevelService.accumulatedOverduePenalty(
                    xpReward: chore.xpReward,
                    totalDaysOverdue: daysOverdue,
                    lastPenalizedDay: lastPenalizedDay
                )
                guard penalty > 0 else { continue }

                totalPenalty += penalty
                var updated = chore
                updated.lastPenaltyAt = today
                updates.append(updated)
                entries.append((chore: chore, penalty: penalty))
            }

            guard totalPenalty > 0 else { return }

            // Persist chore updates first so the bookkeeping is correct
            // even if the harmony call fails.
            for c in updates {
                _ = try? await choreRepo.upsert(c)
            }

            let prevLevel  = household.level
            let newXP      = max(0, household.houseXP - totalPenalty)
            let newHarmony = max(0, household.harmony - Double(totalPenalty) * 0.004)
            try await householdRepo.updateHarmony(
                householdId: household.id,
                harmony: newHarmony,
                xpDelta: -totalPenalty
            )
            household.houseXP = newXP
            household.harmony = newHarmony

            // Log one .overduePenalty event per chore so the history
            // shows what was unfinished and who was on the hook.
            for entry in entries {
                await persistActivity(
                    kind: .overduePenalty,
                    subject: entry.chore.title,
                    icon: entry.chore.icon,
                    xpDelta: -entry.penalty,
                    actorId: entry.chore.assigneeId
                )
            }

            await recordLevelChange(from: prevLevel, actorId: nil)

            Log.app.info("Overdue penalty applied: \(totalPenalty) XP across \(updates.count) chore(s)")
        } catch {
            Log.app.error("processOverduePenalties failed: \(error.localizedDescription, privacy: .public)")
        }
    }

    // MARK: Profile

    /// Persist a profile edit and refresh local state. Used by the Edit
    /// Profile sheet.
    func updateProfile(_ updated: RoomieUser) async {
        do {
            let saved = try await householdRepo.updateUser(updated)
            currentUser = saved
            if let idx = members.firstIndex(where: { $0.id == saved.id }) {
                members[idx] = saved
            }
        } catch {
            Log.app.error("updateProfile failed: \(error.localizedDescription, privacy: .public)")
        }
    }

    // MARK: Household

    /// Persist edits to the household (name, rules, member roster).
    func updateHousehold(_ updated: Household) async {
        do {
            let saved = try await householdRepo.updateHousehold(updated)
            household = saved
            members.removeAll { !saved.memberIds.contains($0.id) }
        } catch {
            Log.app.error("updateHousehold failed: \(error.localizedDescription, privacy: .public)")
        }
    }

    // MARK: Helpers

    func member(id: UUID?) -> RoomieUser? {
        guard let id else { return nil }
        return members.first(where: { $0.id == id })
    }
}
