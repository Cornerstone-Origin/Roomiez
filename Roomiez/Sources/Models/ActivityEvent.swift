import SwiftUI

enum ActivityKind: String, Codable, Sendable {
    case choreCompleted, choreAdded, choreAssigned
    case groceryAdded, groceryChecked
    case noteAdded
    case achievementUnlocked
    case levelUp, levelDown
    case streakSaved
    case overduePenalty, choreReverted
}

struct ActivityEvent: Identifiable, Codable, Hashable, Sendable {
    let id: UUID
    var householdId: UUID
    var actorId: UUID?
    var kind: ActivityKind
    var subject: String              // "Trash duty", "Oat milk", …
    /// SF Symbol name.
    var icon: String
    var xpDelta: Int
    var createdAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case householdId = "household_id"
        case actorId     = "actor_id"
        case kind, subject
        case icon        = "icon"
        case xpDelta     = "xp_delta"
        case createdAt   = "created_at"
    }
}
