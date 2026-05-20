import SwiftUI

/// How often a chore group re-assigns. The group owns recurrence —
/// individual `Chore` assignments materialized from it have `.once`.
enum GroupFrequency: String, Codable, CaseIterable, Identifiable, Sendable {
    case weekly, biweekly, monthly

    var id: String { rawValue }
    var label: String {
        switch self {
        case .weekly:   "Weekly"
        case .biweekly: "Every 2 wks"
        case .monthly:  "Monthly"
        }
    }
    /// Days between assignments. The rotation scheduler advances
    /// `next_due_at` by this many days each cycle.
    var cycleDays: Int {
        switch self {
        case .weekly:   7
        case .biweekly: 14
        case .monthly:  30
        }
    }
}

/// How the scheduler picks the next assignee each cycle.
enum RotationStyle: String, Codable, CaseIterable, Identifiable, Sendable {
    /// Round-robin through household member order.
    case classic
    /// Random, but everyone goes once before anyone repeats ("bag" shuffle).
    case shuffle
    /// Round-robin through a user-defined order.
    case custom

    var id: String { rawValue }
    var label: String {
        switch self {
        case .classic: "Classic"
        case .shuffle: "Shuffle"
        case .custom:  "Custom"
        }
    }
    var blurb: String {
        switch self {
        case .classic: "Round-robin in roommate order"
        case .shuffle: "Random, but everyone goes once before anyone repeats"
        case .custom:  "Drag to set the order yourself"
        }
    }
}

/// Rotating chore "template". Each cycle the scheduler materializes a
/// concrete `Chore` row tagged with `groupId` + `cycleAnchor`; that
/// Chore feeds the existing chore board, XP economy, overdue penalties,
/// streaks, and activity feed unchanged.
struct ChoreGroup: Identifiable, Codable, Hashable, Sendable {
    let id: UUID
    var householdId: UUID
    var title: String
    var note: String?
    /// SF Symbol name — same vocabulary as `Chore.icon`.
    var icon: String
    var frequency: GroupFrequency
    var rotationStyle: RotationStyle
    var xpReward: Int
    var difficulty: ChoreDifficulty
    var priority: ChorePriority
    /// Round-robin pointer for `.classic` and `.custom`. Ignored by
    /// `.shuffle`, which uses per-member `bagPicked` flags instead.
    var rotationIndex: Int
    /// Last cycle anchor the scheduler generated an assignment for. `nil`
    /// means the group has never assigned yet (newly created).
    var lastAssignedAt: Date?
    /// Anchor (start) of the next cycle the scheduler should serve.
    var nextDueAt: Date
    var isPaused: Bool
    /// When set, the scheduler skips the group until this date passes.
    /// Distinct from `isPaused` so the UI can show "Paused until Sun".
    var pausedUntil: Date?
    var createdById: UUID?
    var createdAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case householdId     = "household_id"
        case title, note, icon, frequency
        case rotationStyle   = "rotation_style"
        case xpReward        = "xp_reward"
        case difficulty, priority
        case rotationIndex   = "rotation_index"
        case lastAssignedAt  = "last_assigned_at"
        case nextDueAt       = "next_due_at"
        case isPaused        = "is_paused"
        case pausedUntil     = "paused_until"
        case createdById     = "created_by_id"
        case createdAt       = "created_at"
    }
}

/// Membership row — one per (group, user). `orderIndex` defines the
/// sequence for `.classic` and `.custom` styles. `bagPicked` is the
/// shuffle-bag flag; reset to false for every member when the bag empties.
struct ChoreGroupMember: Codable, Hashable, Sendable {
    var groupId: UUID
    var userId: UUID
    var orderIndex: Int
    var bagPicked: Bool

    enum CodingKeys: String, CodingKey {
        case groupId    = "group_id"
        case userId     = "user_id"
        case orderIndex = "order_index"
        case bagPicked  = "bag_picked"
    }
}
