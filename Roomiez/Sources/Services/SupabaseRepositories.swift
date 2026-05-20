import Foundation
import Supabase

/// Real Supabase-backed repositories. Table names match the SQL migration in
/// `Supabase/schema.sql`.
///
/// All methods are async and use Supabase's PostgREST + Realtime APIs.
@MainActor
final class SupabaseRepositories: ChoreRepository, GroceryRepository, NoteRepository,
                                  HouseholdRepository, AchievementRepository,
                                  ChoreGroupRepository {

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

    // MARK: Chore groups

    func loadGroups(householdId: UUID) async throws -> [ChoreGroup] {
        try await client.from("chore_groups")
            .select()
            .eq("household_id", value: householdId)
            .order("created_at", ascending: true)
            .execute()
            .value
    }

    func loadMembers(groupId: UUID) async throws -> [ChoreGroupMember] {
        try await client.from("chore_group_members")
            .select()
            .eq("group_id", value: groupId)
            .order("order_index", ascending: true)
            .execute()
            .value
    }

    func upsert(_ group: ChoreGroup) async throws -> ChoreGroup {
        try await client.from("chore_groups")
            .upsert(group)
            .select()
            .single()
            .execute()
            .value
    }

    func delete(_ group: ChoreGroup) async throws {
        // Postgres handles the rest:
        //   • chore_group_members → ON DELETE CASCADE
        //   • chores.group_id     → ON DELETE SET NULL
        try await client.from("chore_groups")
            .delete()
            .eq("id", value: group.id)
            .execute()
    }

    func setMembers(_ members: [ChoreGroupMember], for groupId: UUID) async throws {
        // Replace the roster atomically: delete then insert. Wrapped in a
        // single round-trip-block so partial failure leaves the bag empty
        // for the next runRotation to repopulate naturally.
        try await client.from("chore_group_members")
            .delete()
            .eq("group_id", value: groupId)
            .execute()
        guard !members.isEmpty else { return }
        try await client.from("chore_group_members")
            .insert(members)
            .execute()
    }

    func resetBag(groupId: UUID) async throws {
        struct BagPatch: Encodable { let bag_picked: Bool }
        try await client.from("chore_group_members")
            .update(BagPatch(bag_picked: false))
            .eq("group_id", value: groupId)
            .execute()
    }

    func markPicked(groupId: UUID, userId: UUID) async throws {
        struct BagPatch: Encodable { let bag_picked: Bool }
        try await client.from("chore_group_members")
            .update(BagPatch(bag_picked: true))
            .eq("group_id", value: groupId)
            .eq("user_id", value: userId)
            .execute()
    }
}
