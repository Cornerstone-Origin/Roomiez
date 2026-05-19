import Foundation

/// A household is the shared "home" container — its own XP, harmony,
/// streak and member roster.
struct Household: Identifiable, Codable, Hashable, Sendable {
    let id: UUID
    var name: String                // "The Sunny Loft", "Maple St."
    var inviteCode: String
    var houseXP: Int
    var harmony: Double             // 0...1
    var weeklyStreak: Int
    var memberIds: [UUID]
    var rules: [String]
    var createdAt: Date

    /// House level — slower curve than personal (250 XP / level).
    var level: Int { max(1, houseXP / 250 + 1) }
    var levelTitle: String { tier.title }
    /// Tier metadata derived from `level` — drives icon, tint, blurb.
    var tier: LevelService.HouseTier { LevelService.HouseTier.tier(for: level) }
    var levelProgress: Double {
        let into = houseXP % 250
        return Double(into) / 250.0
    }

    enum CodingKeys: String, CodingKey {
        case id, name, rules
        case inviteCode    = "invite_code"
        case houseXP       = "house_xp"
        case harmony
        case weeklyStreak  = "weekly_streak"
        case memberIds     = "member_ids"
        case createdAt     = "created_at"
    }
}
