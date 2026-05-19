import Foundation
import Supabase

/// Real Supabase-backed repositories. Table names match the SQL migration in
/// `Supabase/schema.sql`.
///
/// All methods are async and use Supabase's PostgREST + Realtime APIs.
@MainActor
final class SupabaseRepositories: ChoreRepository, GroceryRepository, NoteRepository,
                                  HouseholdRepository, AchievementRepository {

    private let client: SupabaseClient
    init(client: SupabaseClient) { self.client = client }

    // MARK: Chores

    func loadChores(householdId: UUID) async throws -> [Chore] {
        try await client.from("chores")
            .select()
            .eq("household_id", value: householdId)
            .order("created_at", ascending: false)
            .execute()
            .value
    }

    func upsert(_ chore: Chore) async throws -> Chore {
        try await client.from("chores")
            .upsert(chore)
            .select()
            .single()
            .execute()
            .value
    }

    func delete(_ chore: Chore) async throws {
        try await client.from("chores")
            .delete()
            .eq("id", value: chore.id)
            .execute()
    }

    // MARK: Grocery

    func loadItems(householdId: UUID) async throws -> [GroceryItem] {
        try await client.from("grocery_items")
            .select()
            .eq("household_id", value: householdId)
            .order("added_at", ascending: false)
            .execute()
            .value
    }

    func upsert(_ item: GroceryItem) async throws -> GroceryItem {
        try await client.from("grocery_items")
            .upsert(item)
            .select()
            .single()
            .execute()
            .value
    }

    func delete(_ item: GroceryItem) async throws {
        try await client.from("grocery_items")
            .delete()
            .eq("id", value: item.id)
            .execute()
    }

    // MARK: Notes

    func loadNotes(householdId: UUID) async throws -> [Note] {
        try await client.from("notes")
            .select()
            .eq("household_id", value: householdId)
            .order("order_index", ascending: true)
            .execute()
            .value
    }

    func upsert(_ note: Note) async throws -> Note {
        try await client.from("notes")
            .upsert(note)
            .select()
            .single()
            .execute()
            .value
    }

    func delete(_ note: Note) async throws {
        try await client.from("notes")
            .delete()
            .eq("id", value: note.id)
            .execute()
    }

    // MARK: Household

    func load(householdId: UUID) async throws -> Household {
        try await client.from("households")
            .select()
            .eq("id", value: householdId)
            .single()
            .execute()
            .value
    }

    func members(householdId: UUID) async throws -> [RoomieUser] {
        try await client.from("users")
            .select()
            .eq("household_id", value: householdId)
            .execute()
            .value
    }

    func activity(householdId: UUID, limit: Int) async throws -> [ActivityEvent] {
        try await client.from("activity_events")
            .select()
            .eq("household_id", value: householdId)
            .order("created_at", ascending: false)
            .limit(limit)
            .execute()
            .value
    }

    func log(event: ActivityEvent) async throws {
        try await client.from("activity_events")
            .insert(event)
            .execute()
    }

    func updateHarmony(householdId: UUID, harmony: Double, xpDelta: Int) async throws {
        struct HarmonyPatch: Encodable { let harmony: Double; let house_xp_delta: Int }
        try await client.rpc("bump_household_harmony",
                             params: HarmonyPatch(harmony: harmony, house_xp_delta: xpDelta))
            .execute()
    }

    func updateUser(_ user: RoomieUser) async throws -> RoomieUser {
        try await client.from("users")
            .upsert(user)
            .select()
            .single()
            .execute()
            .value
    }

    func updateHousehold(_ household: Household) async throws -> Household {
        try await client.from("households")
            .upsert(household)
            .select()
            .single()
            .execute()
            .value
    }

    // MARK: Achievements

    func unlocked(householdId: UUID) async throws -> [Achievement] {
        try await client.from("achievements")
            .select()
            .eq("household_id", value: householdId)
            .not("unlocked_at", operator: .is, value: "null")
            .execute()
            .value
    }

    func unlock(_ achievement: Achievement, householdId: UUID) async throws {
        var copy = achievement
        copy.unlockedAt = .now
        try await client.from("achievements")
            .upsert(copy)
            .execute()
    }
}
