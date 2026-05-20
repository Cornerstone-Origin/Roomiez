import SwiftUI

/// Pure functions for level math + cute titles.
enum LevelService {

    static let personalTitles: [String] = [
        "Tiny Helper", "Cozy Companion", "House Hero",
        "Chore Champion", "Harmony Master", "Legendary Roomie"
    ]

    static func title(for level: Int) -> String {
        let idx = min(max(level - 1, 0) / 2, personalTitles.count - 1)
        return personalTitles[idx]
    }

    static func houseTitle(for level: Int) -> String {
        HouseTier.tier(for: level).title
    }

    /// XP awards per action — single source of truth.
    enum Reward {
        static let choreComplete       = 10
        static let prioritisedChore    = 15
        static let groceryItemAdded    = 1
        static let groceryItemChecked  = 2
        static let noteCreated         = 2
        static let streakBonus         = 25
    }

    /// Distinct progression tier for the household. Drives the title,
    /// the icon on the hero card, the accent colour, and the flavour
    /// blurb. One tier per level, capped at level 10 (legendary).
    enum HouseTier: Int, CaseIterable, Sendable {
        case nest, den, cottage, lodge, loft,
             townhouse, neighborhood, manor, mystic, legendary

        var title: String {
            switch self {
            case .nest:         "Fresh Nest"
            case .den:          "Cozy Den"
            case .cottage:      "Warm Cottage"
            case .lodge:        "Garden Lodge"
            case .loft:         "Sunny Loft"
            case .townhouse:    "Family Townhouse"
            case .neighborhood: "Storybook Block"
            case .manor:        "Grand Manor"
            case .mystic:       "Mythic Estate"
            case .legendary:    "Legendary Household"
            }
        }

        /// SF Symbol that grows in elaborateness with each tier.
        var icon: String {
            switch self {
            case .nest:         "tent.fill"
            case .den:          "tent.2.fill"
            case .cottage:      "house.fill"
            case .lodge:        "house.lodge.fill"
            case .loft:         "house.and.flag.fill"
            case .townhouse:    "building.fill"
            case .neighborhood: "building.2.fill"
            case .manor:        "building.columns.fill"
            case .mystic:       "sparkles"
            case .legendary:    "crown.fill"
            }
        }

        /// Tint paired with each tier — cycles through the brand palette.
        var tint: Color {
            switch self {
            case .nest:         Theme.Palette.azure
            case .den:          Theme.Palette.coral
            case .cottage:      Theme.Palette.marigold
            case .lodge:        Theme.Palette.grass
            case .loft:         Theme.Palette.mint
            case .townhouse:    Theme.Palette.periwinkle
            case .neighborhood: Theme.Palette.azure
            case .manor:        Theme.Palette.rose
            case .mystic:       Theme.Palette.coral
            case .legendary:    Theme.Palette.marigold
            }
        }

        var blurb: String {
            switch self {
            case .nest:         "Just getting cozy."
            case .den:          "Two roomies, one rhythm."
            case .cottage:      "Building warmth."
            case .lodge:        "Plants on every shelf."
            case .loft:         "Sunlight and good habits."
            case .townhouse:    "Quiet routines and rituals."
            case .neighborhood: "Pages of memory."
            case .manor:        "Walls full of warmth."
            case .mystic:       "A small, kind kingdom."
            case .legendary:    "Roomie hall of fame."
            }
        }

        /// House level at which this tier unlocks (1…10).
        var unlocksAtLevel: Int { rawValue + 1 }

        static func tier(for level: Int) -> HouseTier {
            let idx = min(max(level - 1, 0), HouseTier.allCases.count - 1)
            return HouseTier(rawValue: idx) ?? .nest
        }
    }

    // MARK: - Overdue penalty

    /// XP lost on the *single* day `dayOverdue` for a chore worth
    /// `xpReward`. Penalty escalates linearly: day 1 costs 10% of XP,
    /// day 2 costs 20%, etc., capped at the chore's own XP value.
    /// Always at least 1 XP so micro-chores still bite.
    static func dailyOverduePenalty(xpReward: Int, dayOverdue: Int) -> Int {
        let raw = Double(xpReward) * Double(dayOverdue) * 0.10
        let rounded = Int(raw.rounded())
        return max(1, min(xpReward, rounded))
    }

    /// Total XP penalty owed for a chore that has been overdue
    /// `totalDaysOverdue` days, given the last day already accounted
    /// for is `lastPenalizedDay` (0 if never penalized). Sums each
    /// missed day's individual penalty.
    static func accumulatedOverduePenalty(xpReward: Int,
                                          totalDaysOverdue: Int,
                                          lastPenalizedDay: Int) -> Int {
        guard totalDaysOverdue > lastPenalizedDay else { return 0 }
        var total = 0
        for day in (lastPenalizedDay + 1)...totalDaysOverdue {
            total += dailyOverduePenalty(xpReward: xpReward, dayOverdue: day)
        }
        return total
    }

    /// House harmony bumps in/out of 0…1 based on collaborative activity.
    static func harmonyDelta(for kind: ActivityKind) -> Double {
        switch kind {
        case .choreCompleted:     0.04
        case .choreAssigned:      0.01
        case .groceryChecked:     0.02
        case .noteAdded:          0.01
        case .achievementUnlocked:0.06
        case .levelUp:            0.05
        case .streakSaved:        0.03
        case .choreAdded, .groceryAdded: 0.005
        // Bookkeeping kinds — house-XP changes are tracked elsewhere;
        // the harmony delta is folded in by the calling site.
        case .levelDown, .overduePenalty, .choreReverted: 0
        }
    }
}
