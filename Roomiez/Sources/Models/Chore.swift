import SwiftUI

enum ChoreStatus: String, Codable, CaseIterable, Identifiable, Sendable {
    case todo, inProgress, done

    var id: String { rawValue }
    var title: String {
        switch self {
        case .todo:       "To Do"
        case .inProgress: "In Progress"
        case .done:       "Done"
        }
    }
    /// Short label used in tight UIs (e.g. the chore-board picker pills).
    var shortTitle: String {
        switch self {
        case .todo:       "To Do"
        case .inProgress: "IP"
        case .done:       "Done"
        }
    }
    /// SF Symbol name.
    var icon: String {
        switch self {
        case .todo:       "circle"
        case .inProgress: "circle.dotted"
        case .done:       "checkmark.circle.fill"
        }
    }
    var tint: Color {
        switch self {
        case .todo:       Theme.Palette.brick
        case .inProgress: Theme.Palette.ochre
        case .done:       Theme.Palette.forest
        }
    }
}

enum ChorePriority: String, Codable, CaseIterable, Identifiable, Sendable {
    case low, normal, high

    var id: String { rawValue }
    var label: String { rawValue.capitalized }
    var tint: Color {
        switch self {
        case .low:    Theme.Palette.forest
        case .normal: Theme.Palette.indigo
        case .high:   Theme.Palette.brick
        }
    }
}

/// How effortful a chore is. Drives the XP reward automatically so the
/// user doesn't have to dial in a number — picking the difficulty sets
/// the XP. See `xp` for the mapping.
enum ChoreDifficulty: String, Codable, CaseIterable, Identifiable, Sendable {
    case quick, normal, hefty, big

    var id: String { rawValue }
    var label: String {
        switch self {
        case .quick:  "Quick"
        case .normal: "Normal"
        case .hefty:  "Hefty"
        case .big:    "Big"
        }
    }
    var blurb: String {
        switch self {
        case .quick:  "A few minutes"
        case .normal: "Half an hour"
        case .hefty:  "About an hour"
        case .big:    "Multi-hour project"
        }
    }
    var icon: String {
        switch self {
        case .quick:  "bolt.fill"
        case .normal: "clock.fill"
        case .hefty:  "timer"
        case .big:    "hammer.fill"
        }
    }
    /// XP awarded when the chore is completed at this difficulty.
    var xp: Int {
        switch self {
        case .quick:  5
        case .normal: 10
        case .hefty:  20
        case .big:    35
        }
    }
    var tint: Color {
        switch self {
        case .quick:  Theme.Palette.mint
        case .normal: Theme.Palette.azure
        case .hefty:  Theme.Palette.marigold
        case .big:    Theme.Palette.rose
        }
    }
}

enum ChoreRecurrence: String, Codable, CaseIterable, Identifiable, Sendable {
    case once, daily, weekly, biweekly, monthly

    var id: String { rawValue }
    var label: String {
        switch self {
        case .once:     "One-time"
        case .daily:    "Daily"
        case .weekly:   "Weekly"
        case .biweekly: "Every 2 wks"
        case .monthly:  "Monthly"
        }
    }
}

struct Chore: Identifiable, Codable, Hashable, Sendable {
    let id: UUID
    var householdId: UUID
    var title: String
    var note: String?
    /// SF Symbol name — e.g. `"tshirt.fill"`, `"trash.fill"`.
    var icon: String
    var status: ChoreStatus
    var priority: ChorePriority
    var recurrence: ChoreRecurrence
    var assigneeId: UUID?
    /// Roommate IDs in the order this chore rotates through. Empty array
    /// means "use the household default member order".
    var rotationOrder: [UUID]
    var xpReward: Int                // default 10 — derived from `difficulty`
    /// How effortful the chore is. The `xpReward` is auto-computed from
    /// this in the create / edit sheet.
    var difficulty: ChoreDifficulty = .normal
    var dueDate: Date?
    var completedAt: Date?
    var streak: Int                  // per-chore streak ("trash day hero")
    var createdAt: Date
    /// Last day the overdue-penalty deduction was applied for this chore.
    /// `nil` means the chore has never been penalized.
    var lastPenaltyAt: Date?
    /// Originating rotation group, if this chore was materialized by the
    /// weekly auto-assignment scheduler. `nil` for one-off chores.
    var groupId: UUID? = nil
    /// Anchor date of the cycle this assignment serves (start of the week
    /// for weekly groups, etc.). Pairs with `groupId` for the unique
    /// `(group_id, cycle_anchor)` constraint that keeps the scheduler
    /// idempotent.
    var cycleAnchor: Date? = nil
    /// True when the scheduler — not a roommate — created this chore.
    var autoAssigned: Bool = false

    var isOverdue: Bool {
        guard status != .done, let due = dueDate else { return false }
        return due < .now.startOfDay
    }

    /// Brand colour derived from the chore's icon — delegates to the
    /// single source of truth in `ChoreIcon.tint(for:)`.
    var iconTint: Color { ChoreIcon.tint(for: icon) }

    enum CodingKeys: String, CodingKey {
        case id
        case householdId   = "household_id"
        case title, note
        case icon          = "icon"
        case status, priority, recurrence
        case assigneeId    = "assignee_id"
        case rotationOrder = "rotation_order"
        case xpReward      = "xp_reward"
        case difficulty
        case dueDate       = "due_date"
        case completedAt   = "completed_at"
        case streak
        case createdAt     = "created_at"
        case lastPenaltyAt = "last_penalty_at"
        case groupId       = "group_id"
        case cycleAnchor   = "cycle_anchor"
        case autoAssigned  = "auto_assigned"
    }
}

/// Picker options shown in the new-chore sheet. Friendly label + SF Symbol.
enum ChoreIcon {
    static let options: [(label: String, symbol: String)] = [
        ("Laundry",  "tshirt.fill"),
        ("Trash",    "trash.fill"),
        ("Dishes",   "fork.knife"),
        ("Cooking",  "flame.fill"),
        ("Plants",   "leaf.fill"),
        ("Cleaning", "sparkles"),
        ("Bathroom", "shower.fill"),
        ("Sweep",    "wind"),
        ("Pet",      "pawprint.fill"),
        ("Mail",     "envelope.fill"),
        ("Bills",    "creditcard.fill"),
        ("Repair",   "wrench.adjustable.fill"),
    ]

    /// Single source of truth for the icon→colour mapping. `Chore.iconTint`
    /// delegates here too.
    static func tint(for symbol: String) -> Color {
        switch symbol {
        case "tshirt.fill":            return Theme.Palette.azure        // Laundry
        case "trash.fill":             return Theme.Palette.grass        // Trash
        case "fork.knife":             return Theme.Palette.marigold     // Dishes
        case "flame.fill":             return Theme.Palette.coral        // Cooking
        case "leaf.fill":              return Theme.Palette.grass        // Plants
        case "sparkles":               return Theme.Palette.periwinkle   // Cleaning
        case "shower.fill":            return Theme.Palette.periwinkle   // Bathroom
        case "wind":                   return Theme.Palette.mint         // Sweep
        case "pawprint.fill":          return Theme.Palette.marigold     // Pet
        case "envelope.fill":          return Theme.Palette.rose         // Mail
        case "creditcard.fill":        return Theme.Palette.azure        // Bills
        case "wrench.adjustable.fill": return Theme.Palette.azure        // Repair
        case "shippingbox.fill":       return Theme.Palette.marigold     // Restock
        default:                       return Theme.Palette.mint
        }
    }

    /// Recommended effort level for a generic chore of this category.
    /// Used as a baseline when the user picks an icon — the difficulty
    /// picker auto-snaps to this so the XP reflects the kind of work.
    static func defaultDifficulty(for symbol: String) -> ChoreDifficulty {
        switch symbol {
        case "tshirt.fill":            return .hefty   // Laundry
        case "trash.fill":             return .quick   // Trash
        case "fork.knife":             return .normal  // Dishes
        case "flame.fill":             return .hefty   // Cooking
        case "leaf.fill":              return .quick   // Plants
        case "sparkles":               return .hefty   // Cleaning (general)
        case "shower.fill":            return .hefty   // Bathroom
        case "wind":                   return .normal  // Sweep
        case "pawprint.fill":          return .normal  // Pet care
        case "envelope.fill":          return .quick   // Mail
        case "creditcard.fill":        return .normal  // Bills
        case "wrench.adjustable.fill": return .normal  // Repair
        default:                       return .normal
        }
    }

    /// Effort level for a *specific* preset title — overrides the
    /// icon's default. "Replace bulb" is quick, "Cook dinner" is hefty,
    /// etc. Returns nil for free-text titles the system doesn't know.
    static func presetDifficulty(for title: String) -> ChoreDifficulty? {
        let normalized = title
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()
        switch normalized {
        // Laundry
        case "whites", "darks", "towels", "bedding",
             "delicates", "workout gear":                       return .hefty
        case "fold laundry", "iron clothes":                    return .normal
        case "hang dry":                                        return .quick
        // Trash
        case "take out trash", "recycling", "compost",
             "empty bins", "sort recyclables":                  return .quick
        case "bag yard waste":                                  return .normal
        // Dishes
        case "wash dishes", "hand-wash pots":                   return .normal
        case "load dishwasher", "empty dishwasher",
             "clear table", "wipe stove", "soak pans":          return .quick
        // Cooking
        case "cook dinner", "cook lunch",
             "meal prep", "bake bread":                         return .hefty
        case "cook breakfast":                                  return .normal
        case "make snacks", "marinate":                         return .quick
        case "slow cook":                                       return .big
        // Plants
        case "water plants", "mist plants", "fertilize",
             "rotate plants", "harvest herbs":                  return .quick
        case "repot", "trim leaves":                            return .normal
        case "weed garden":                                     return .hefty
        // Cleaning
        case "vacuum", "mop floors", "clean windows",
             "wipe baseboards":                                 return .hefty
        case "wipe counters", "dust",
             "sanitize handles":                                return .quick
        case "wipe appliances", "polish furniture":             return .normal
        case "deep clean kitchen":                              return .big
        // Bathroom
        case "clean toilet", "clean sink", "wash bath mats":    return .normal
        case "scrub shower", "mop bathroom":                    return .hefty
        case "wipe mirror", "refill soap",
             "empty bin", "restock tp":                         return .quick
        // Sweep
        case "sweep floors", "sweep porch",
             "sweep stairs", "sweep deck",
             "beat rugs", "clean entryway":                     return .normal
        case "sweep garage":                                    return .hefty
        // Pet
        case "walk pet", "trim nails", "play time":             return .normal
        case "feed pet", "refill water",
             "clean litter", "brush pet":                       return .quick
        case "pet bath", "clean cage", "vet appointment":       return .hefty
        // Mail
        case "check mail", "sort mail",
             "cancel junk mail":                                return .quick
        case "send package", "drop off return",
             "reply to letters":                                return .normal
        // Bills
        case "pay rent", "pay utilities", "pay internet",
             "pay subscriptions", "pay credit card",
             "pay insurance", "split bills":                    return .normal
        case "review budget":                                   return .hefty
        // Repair
        case "replace bulb", "tighten loose",
             "oil hinges", "replace filter":                    return .quick
        case "unclog drain":                                    return .normal
        case "fix faucet", "fix leak",
             "patch wall", "touch-up paint":                    return .hefty
        // Restock
        case "restock paper goods", "restock pantry",
             "restock cleaning supplies":                       return .normal
        default:                                                return nil
        }
    }

    /// Quick-fill suggestions for the chore title when a given icon is
    /// selected. Empty for unknown icons; the create sheet always shows a
    /// trailing "Custom" chip so the user can type freely.
    static func presets(for symbol: String) -> [String] {
        switch symbol {
        case "tshirt.fill":
            return ["Whites", "Darks", "Towels", "Bedding",
                    "Delicates", "Workout gear",
                    "Fold laundry", "Iron clothes", "Hang dry"]
        case "trash.fill":
            return ["Take out trash", "Recycling", "Compost",
                    "Empty bins", "Sort recyclables", "Bag yard waste"]
        case "fork.knife":
            return ["Wash dishes", "Hand-wash pots",
                    "Load dishwasher", "Empty dishwasher",
                    "Clear table", "Wipe stove", "Soak pans"]
        case "flame.fill":
            return ["Cook breakfast", "Cook lunch", "Cook dinner",
                    "Meal prep", "Bake bread", "Make snacks",
                    "Marinate", "Slow cook"]
        case "leaf.fill":
            return ["Water plants", "Mist plants", "Fertilize",
                    "Repot", "Trim leaves", "Rotate plants",
                    "Harvest herbs", "Weed garden"]
        case "sparkles":
            return ["Vacuum", "Mop floors", "Wipe counters",
                    "Dust", "Clean windows", "Wipe baseboards",
                    "Sanitize handles", "Wipe appliances",
                    "Polish furniture", "Deep clean kitchen"]
        case "shower.fill":
            return ["Clean toilet", "Scrub shower", "Mop bathroom",
                    "Wipe mirror", "Clean sink", "Refill soap",
                    "Wash bath mats", "Empty bin", "Restock TP"]
        case "wind":
            return ["Sweep floors", "Sweep porch", "Sweep stairs",
                    "Sweep garage", "Sweep deck",
                    "Beat rugs", "Clean entryway"]
        case "pawprint.fill":
            return ["Walk pet", "Feed pet", "Refill water",
                    "Clean litter", "Brush pet", "Trim nails",
                    "Pet bath", "Play time", "Clean cage",
                    "Vet appointment"]
        case "envelope.fill":
            return ["Check mail", "Sort mail", "Send package",
                    "Drop off return", "Reply to letters",
                    "Cancel junk mail"]
        case "creditcard.fill":
            return ["Pay rent", "Pay utilities", "Pay internet",
                    "Pay subscriptions", "Pay credit card",
                    "Pay insurance", "Split bills", "Review budget"]
        case "wrench.adjustable.fill":
            return ["Replace bulb", "Tighten loose", "Oil hinges",
                    "Replace filter", "Fix faucet", "Fix leak",
                    "Unclog drain", "Patch wall", "Touch-up paint"]
        case "shippingbox.fill":
            return ["Restock paper goods", "Restock pantry",
                    "Restock cleaning supplies"]
        default:                       return []
        }
    }
}
