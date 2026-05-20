import Foundation

/// In-memory repository used in SwiftUI previews and any time Supabase
/// credentials aren't configured. Pre-loaded from `PreviewData` so the app
/// looks alive on first launch.
///
/// `@MainActor` because seed data references `@MainActor`-inferred globals;
/// keeping everything on the main actor sidesteps the cross-isolation hop
/// without any practical downside (every write is fired by a `View` action
/// that's already on the main actor).
@MainActor
final class LocalSeedRepositories: ChoreRepository, GroceryRepository, NoteRepository,
                                   HouseholdRepository, AchievementRepository,
                                   ChoreGroupRepository {

    private var chores:       [Chore]             = PreviewData.chores
    private var grocery:      [GroceryItem]       = PreviewData.grocery
    private var notes:        [Note]              = PreviewData.notes
    private var activity:     [ActivityEvent]     = PreviewData.activity
    private var household:    Household           = PreviewData.household
    private var members:      [RoomieUser]        = PreviewData.users
    private var achievements: [Achievement]       = PreviewData.unlockedAchievements
    private var groups:       [ChoreGroup]        = []
    private var groupMembers: [ChoreGroupMember]  = []

    // MARK: Chores

    func loadChores(householdId: UUID) async throws -> [Chore] { chores }

    func upsert(_ chore: Chore) async throws -> Chore {
        if let idx = chores.firstIndex(where: { $0.id == chore.id }) {
            chores[idx] = chore
        } else {
            chores.append(chore)
        }
        return chore
    }

    func delete(_ chore: Chore) async throws {
        chores.removeAll { $0.id == chore.id }
    }

    // MARK: Grocery

    func loadItems(householdId: UUID) async throws -> [GroceryItem] { grocery }

    func upsert(_ item: GroceryItem) async throws -> GroceryItem {
        if let idx = grocery.firstIndex(where: { $0.id == item.id }) {
            grocery[idx] = item
        } else {
            grocery.append(item)
        }
        return item
    }

    func delete(_ item: GroceryItem) async throws {
        grocery.removeAll { $0.id == item.id }
    }

    // MARK: Notes

    func loadNotes(householdId: UUID) async throws -> [Note] {
        notes.sorted { $0.orderIndex < $1.orderIndex }
    }

    func upsert(_ note: Note) async throws -> Note {
        if let idx = notes.firstIndex(where: { $0.id == note.id }) {
            notes[idx] = note
        } else {
            notes.append(note)
        }
        return note
    }

    func delete(_ note: Note) async throws {
        notes.removeAll { $0.id == note.id }
    }

    // MARK: Household

    func load(householdId: UUID) async throws -> Household { household }
    func members(householdId: UUID) async throws -> [RoomieUser] { members }

    func activity(householdId: UUID, limit: Int) async throws -> [ActivityEvent] {
        Array(activity.sorted { $0.createdAt > $1.createdAt }.prefix(limit))
    }

    func log(event: ActivityEvent) async throws {
        activity.insert(event, at: 0)
    }

    func updateHarmony(householdId: UUID, harmony: Double, xpDelta: Int) async throws {
        household.harmony = min(max(harmony, 0), 1)
        household.houseXP = max(0, household.houseXP + xpDelta)
    }

    func updateUser(_ user: RoomieUser) async throws -> RoomieUser {
        if let idx = members.firstIndex(where: { $0.id == user.id }) {
            members[idx] = user
        } else {
            members.append(user)
        }
        return user
    }

    func updateHousehold(_ household: Household) async throws -> Household {
        self.household = household
        return household
    }

    // MARK: Achievements

    func unlocked(householdId: UUID) async throws -> [Achievement] { achievements }

    func unlock(_ achievement: Achievement, householdId: UUID) async throws {
        guard !achievements.contains(where: { $0.key == achievement.key }) else { return }
        var unlocked = achievement
        unlocked.unlockedAt = .now
        achievements.append(unlocked)
    }

    // MARK: Chore groups

    func loadGroups(householdId: UUID) async throws -> [ChoreGroup] {
        groups
            .filter { $0.householdId == householdId }
            .sorted { $0.createdAt < $1.createdAt }
    }

    func loadMembers(groupId: UUID) async throws -> [ChoreGroupMember] {
        groupMembers
            .filter { $0.groupId == groupId }
            .sorted { $0.orderIndex < $1.orderIndex }
    }

    func upsert(_ group: ChoreGroup) async throws -> ChoreGroup {
        if let idx = groups.firstIndex(where: { $0.id == group.id }) {
            groups[idx] = group
        } else {
            groups.append(group)
        }
        return group
    }

    func delete(_ group: ChoreGroup) async throws {
        // Mirror Postgres' ON DELETE behavior: drop the group + membership,
        // and null out group_id on any past assignment Chores.
        groups.removeAll        { $0.id == group.id }
        groupMembers.removeAll  { $0.groupId == group.id }
        for i in chores.indices where chores[i].groupId == group.id {
            chores[i].groupId = nil
        }
    }

    func setMembers(_ members: [ChoreGroupMember], for groupId: UUID) async throws {
        groupMembers.removeAll { $0.groupId == groupId }
        groupMembers.append(contentsOf: members)
    }

    func resetBag(groupId: UUID) async throws {
        for i in groupMembers.indices where groupMembers[i].groupId == groupId {
            groupMembers[i].bagPicked = false
        }
    }

    func markPicked(groupId: UUID, userId: UUID) async throws {
        for i in groupMembers.indices
        where groupMembers[i].groupId == groupId && groupMembers[i].userId == userId {
            groupMembers[i].bagPicked = true
        }
    }
}
