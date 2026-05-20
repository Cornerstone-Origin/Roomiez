import SwiftUI

struct Achievement: Identifiable, Codable, Hashable, Sendable {
    let id: UUID
    var key: String                  // "laundry_legend"
    var title: String                // "Laundry Legend"
    var blurb: String
    /// SF Symbol name.
    var icon: String
    var tintHex: String
    var threshold: Int               // e.g. 10 laundry completions
    var unlockedAt: Date?

    var tint: Color { Color(hex: tintHex) }
    var isUnlocked: Bool { unlockedAt != nil }

    enum CodingKeys: String, CodingKey {
        case id, key, title, blurb
        case icon        = "icon"
        case tintHex     = "tint_hex"
        case threshold
        case unlockedAt  = "unlocked_at"
    }
}

/// The static catalog of achievements the app ships with.
/// (User progress is tracked separately per household.)
enum AchievementCatalog {

    static let all: [Achievement] = [
        .init(id: UUID(), key: "laundry_legend",
              title: "Laundry Legend",
              blurb: "10 loads of laundry completed.",
              icon: "tshirt.fill",
              tintHex: "ED5565", threshold: 10, unlockedAt: nil),

        .init(id: UUID(), key: "trash_day_hero",
              title: "Trash Day Hero",
              blurb: "5 trash days in a row.",
              icon: "trash.fill",
              tintHex: "48CFAD", threshold: 5, unlockedAt: nil),

        .init(id: UUID(), key: "kitchen_guardian",
              title: "Kitchen Guardian",
              blurb: "20 kitchen chores complete.",
              icon: "fork.knife",
              tintHex: "FFCE54", threshold: 20, unlockedAt: nil),

        .init(id: UUID(), key: "harmony_keeper",
              title: "Harmony Keeper",
              blurb: "A full week of 90%+ harmony.",
              icon: "heart.fill",
              tintHex: "4FC1E9", threshold: 7, unlockedAt: nil),

        .init(id: UUID(), key: "early_bird",
              title: "Early Bird",
              blurb: "Complete 5 chores before noon.",
              icon: "sunrise.fill",
              tintHex: "ED5565", threshold: 5, unlockedAt: nil),

        .init(id: UUID(), key: "grocery_guru",
              title: "Grocery Guru",
              blurb: "Add 50 items to the list.",
              icon: "basket.fill",
              tintHex: "A0D468", threshold: 50, unlockedAt: nil),
    ]
}
