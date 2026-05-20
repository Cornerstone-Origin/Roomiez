import Foundation

/// Protocols that the rest of the app talks to.
///
/// Two concrete implementations live in this folder:
///   • `LocalSeedRepositories` — used in previews and when Supabase isn't
///     configured. Holds data in memory.
///   • `SupabaseRepositories`  — hits real Postgres + Realtime when
///     `SupabaseConfig.plist` is filled in.
///
/// Views never see the implementation; they always go through `AppState`.

protocol ChoreRepository: AnyObject {
    func loadChores(householdId: UUID) async throws -> [Chore]
    func upsert(_ chore: Chore) async throws -> Chore
    func delete(_ chore: Chore) async throws
}

protocol GroceryRepository: AnyObject {
    func loadItems(householdId: UUID) async throws -> [GroceryItem]
    func upsert(_ item: GroceryItem) async throws -> GroceryItem
    func delete(_ item: GroceryItem) async throws
}

protocol NoteRepository: AnyObject {
    func loadNotes(householdId: UUID) async throws -> [Note]
    func upsert(_ note: Note) async throws -> Note
    func delete(_ note: Note) async throws
}

protocol HouseholdRepository: AnyObject {
    func load(householdId: UUID) async throws -> Household
    func members(householdId: UUID) async throws -> [RoomieUser]
    func activity(householdId: UUID, limit: Int) async throws -> [ActivityEvent]
    func log(event: ActivityEvent) async throws
    func updateHarmony(householdId: UUID, harmony: Double, xpDelta: Int) async throws
    func updateUser(_ user: RoomieUser) async throws -> RoomieUser
    func updateHousehold(_ household: Household) async throws -> Household
}

protocol AchievementRepository: AnyObject {
    func unlocked(householdId: UUID) async throws -> [Achievement]
    func unlock(_ achievement: Achievement, householdId: UUID) async throws
}

protocol ChoreGroupRepository: AnyObject {
    /// All rotation groups for a household. Ordered by createdAt ascending
    /// so newly created groups appear at the bottom (stable ordering).
    func loadGroups(householdId: UUID) async throws -> [ChoreGroup]

    /// Membership rows for one group, sorted by `orderIndex` ascending.
    func loadMembers(groupId: UUID) async throws -> [ChoreGroupMember]

    /// Insert or update a group.
    func upsert(_ group: ChoreGroup) async throws -> ChoreGroup

    /// Cascade-deletes membership rows (via FK on chore_group_members) and
    /// nulls out `chores.group_id` (via FK on chores). Past assignment
    /// Chores survive as orphan one-offs.
    func delete(_ group: ChoreGroup) async throws

    /// Replace the entire membership roster for a group in one shot. Caller
    /// is responsible for setting `orderIndex` on each row.
    func setMembers(_ members: [ChoreGroupMember], for groupId: UUID) async throws

    /// Shuffle-bag bookkeeping — reset every member's `bagPicked` to false.
    /// Called when the current shuffle bag is empty and we're starting a
    /// fresh round.
    func resetBag(groupId: UUID) async throws

    /// Shuffle-bag bookkeeping — mark a single member as picked in the
    /// current bag. Idempotent; safe to call after the scheduler advances.
    func markPicked(groupId: UUID, userId: UUID) async throws
}
