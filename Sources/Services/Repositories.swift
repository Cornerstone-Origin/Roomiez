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
