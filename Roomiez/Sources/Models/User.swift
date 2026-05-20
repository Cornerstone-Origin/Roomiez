import SwiftUI

/// A roommate / family member inside a household.
struct RoomieUser: Identifiable, Codable, Hashable, Sendable {
    let id: UUID
    var displayName: String
    /// 1–2 letter monogram shown in the avatar circle. Auto-derived
    /// from `displayName` when blank.
    var avatarInitials: String
    var accentHex: String            // jewel tint for avatar ring / cards
    /// Title chosen from unlocked trophies. Nil → show the level title.
    var customTitle: String?
    /// Short personal blurb shown on the profile card.
    var bio: String?
    var householdId: UUID?
    var personalXP: Int
    var weeklyStreak: Int
    var joinedAt: Date

    var accent: Color { Color(hex: accentHex) }

    /// Title shown on the profile card. Falls back to the level-derived
    /// title when the user hasn't set a custom one.
    var displayTitle: String {
        if let t = customTitle, !t.trimmingCharacters(in: .whitespaces).isEmpty {
            return t
        }
        return levelTitle
    }

    /// Auto-computed fallback if `avatarInitials` is empty.
    var initials: String {
        if !avatarInitials.isEmpty { return avatarInitials.uppercased() }
        let parts = displayName.split(separator: " ").prefix(2)
        return parts.compactMap { $0.first.map(String.init) }
                    .joined()
                    .uppercased()
    }

    /// Level computed from XP. Each level is roughly 100 XP.
    var level: Int { max(1, personalXP / 100 + 1) }
    var levelTitle: String { LevelService.title(for: level) }

    /// Progress (0…1) toward the next level.
    var levelProgress: Double {
        let into = personalXP % 100
        return Double(into) / 100.0
    }

    enum CodingKeys: String, CodingKey {
        case id
        case displayName    = "display_name"
        case avatarInitials = "avatar_initials"
        case accentHex      = "accent_hex"
        case customTitle    = "custom_title"
        case bio
        case householdId    = "household_id"
        case personalXP     = "personal_xp"
        case weeklyStreak   = "weekly_streak"
        case joinedAt       = "joined_at"
    }
}
