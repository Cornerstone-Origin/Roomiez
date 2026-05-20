import Foundation

/// Seed data used in SwiftUI previews and when running without Supabase.
/// All icons are SF Symbol names. Avatar fields hold 1–2 character monograms
/// (rendered by `AvatarView` as text inside a colored disc).
enum PreviewData {

    // MARK: - Users

    static let currentUser = RoomieUser(
        id: UUID(uuidString: "00000000-0000-0000-0000-000000000001")!,
        displayName: "Marina",
        avatarInitials: "MR",
        accentHex: "48CFAD",
        householdId: PreviewData.householdId,
        personalXP: 240,
        weeklyStreak: 6,
        joinedAt: Date(timeIntervalSinceNow: -60 * 60 * 24 * 90)
    )

    static let alex = RoomieUser(
        id: UUID(uuidString: "00000000-0000-0000-0000-000000000002")!,
        displayName: "Alex",
        avatarInitials: "AL",
        accentHex: "FC6E51",
        householdId: PreviewData.householdId,
        personalXP: 305,
        weeklyStreak: 4,
        joinedAt: Date(timeIntervalSinceNow: -60 * 60 * 24 * 120)
    )

    static let sam = RoomieUser(
        id: UUID(uuidString: "00000000-0000-0000-0000-000000000003")!,
        displayName: "Sam",
        avatarInitials: "SM",
        accentHex: "FFCE54",
        householdId: PreviewData.householdId,
        personalXP: 175,
        weeklyStreak: 3,
        joinedAt: Date(timeIntervalSinceNow: -60 * 60 * 24 * 60)
    )

    static let jules = RoomieUser(
        id: UUID(uuidString: "00000000-0000-0000-0000-000000000004")!,
        displayName: "Jules",
        avatarInitials: "JU",
        accentHex: "4FC1E9",
        householdId: PreviewData.householdId,
        personalXP: 410,
        weeklyStreak: 7,
        joinedAt: Date(timeIntervalSinceNow: -60 * 60 * 24 * 150)
    )

    static var users: [RoomieUser] { [currentUser, alex, sam, jules] }

    // MARK: - Household

    static let householdId = UUID(uuidString: "00000000-0000-0000-0000-0000000000AA")!

    static let household = Household(
        id: householdId,
        name: "The Sunny Loft",
        inviteCode: "SUNNY-7421",
        houseXP: 1280,
        harmony: 0.82,
        weeklyStreak: 5,
        memberIds: [currentUser.id, alex.id, sam.id, jules.id],
        rules: [
            "Quiet hours: 10pm – 8am.",
            "Wipe down counters after cooking.",
            "Trash + recycling go out Sunday night.",
            "Label your food in the fridge.",
            "Guests welcome — give a heads-up if overnight."
        ],
        createdAt: Date(timeIntervalSinceNow: -60 * 60 * 24 * 200)
    )

    // MARK: - Chores

    static let chores: [Chore] = [
        Chore(id: UUID(), householdId: householdId,
              title: "Take out trash", note: "Recycling day too.",
              icon: "trash.fill", status: .todo, priority: .high,
              recurrence: .weekly, assigneeId: alex.id,
              rotationOrder: [alex.id, sam.id, currentUser.id, jules.id],
              xpReward: 15, dueDate: .now.addingTimeInterval(60*60*8),
              completedAt: nil, streak: 6,
              createdAt: .now.addingTimeInterval(-60*60*24)),

        Chore(id: UUID(), householdId: householdId,
              title: "Water plants", note: nil,
              icon: "leaf.fill", status: .todo, priority: .normal,
              recurrence: .daily, assigneeId: currentUser.id, rotationOrder: [],
              xpReward: 10, dueDate: .now,
              completedAt: nil, streak: 12,
              createdAt: .now.addingTimeInterval(-60*60*2)),

        Chore(id: UUID(), householdId: householdId,
              title: "Laundry", note: "Whites and towels",
              icon: "tshirt.fill", status: .inProgress, priority: .normal,
              recurrence: .weekly, assigneeId: sam.id, rotationOrder: [],
              xpReward: 12, dueDate: .now.addingTimeInterval(60*60*24),
              completedAt: nil, streak: 3,
              createdAt: .now.addingTimeInterval(-60*60*6)),

        Chore(id: UUID(), householdId: householdId,
              title: "Clean kitchen", note: "Counters and sink",
              icon: "fork.knife", status: .inProgress, priority: .high,
              recurrence: .weekly, assigneeId: jules.id, rotationOrder: [],
              xpReward: 18, dueDate: .now,
              completedAt: nil, streak: 4,
              createdAt: .now.addingTimeInterval(-60*60*3)),

        Chore(id: UUID(), householdId: householdId,
              title: "Vacuum living room", note: nil,
              icon: "wind", status: .done, priority: .low,
              recurrence: .weekly, assigneeId: currentUser.id, rotationOrder: [],
              xpReward: 10, dueDate: .now.addingTimeInterval(-60*60*24),
              completedAt: .now.addingTimeInterval(-60*60*22),
              streak: 9,
              createdAt: .now.addingTimeInterval(-60*60*48)),

        Chore(id: UUID(), householdId: householdId,
              title: "Restock paper goods", note: nil,
              icon: "shippingbox.fill", status: .done, priority: .low,
              recurrence: .biweekly, assigneeId: alex.id, rotationOrder: [],
              xpReward: 8, dueDate: .now.addingTimeInterval(-60*60*60),
              completedAt: .now.addingTimeInterval(-60*60*50),
              streak: 2,
              createdAt: .now.addingTimeInterval(-60*60*72)),

        Chore(id: UUID(), householdId: householdId,
              title: "Mop bathroom", note: "After laundry",
              icon: "shower.fill", status: .todo, priority: .low,
              recurrence: .biweekly, assigneeId: nil, rotationOrder: [],
              xpReward: 12, dueDate: .now.addingTimeInterval(60*60*48),
              completedAt: nil, streak: 0,
              createdAt: .now.addingTimeInterval(-60*60*1)),

        // Extra "done this week" history so the leaderboard has data.
        Chore(id: UUID(), householdId: householdId,
              title: "Empty dishwasher", note: nil,
              icon: "fork.knife", status: .done, priority: .normal,
              recurrence: .daily, assigneeId: jules.id, rotationOrder: [],
              xpReward: 8, dueDate: .now.addingTimeInterval(-60*60*36),
              completedAt: .now.addingTimeInterval(-60*60*30),
              streak: 5,
              createdAt: .now.addingTimeInterval(-60*60*72)),

        Chore(id: UUID(), householdId: householdId,
              title: "Walk pet", note: nil,
              icon: "pawprint.fill", status: .done, priority: .normal,
              recurrence: .daily, assigneeId: sam.id, rotationOrder: [],
              xpReward: 6, dueDate: .now.addingTimeInterval(-60*60*48),
              completedAt: .now.addingTimeInterval(-60*60*46),
              streak: 4,
              createdAt: .now.addingTimeInterval(-60*60*72)),

        Chore(id: UUID(), householdId: householdId,
              title: "Sort mail", note: nil,
              icon: "envelope.fill", status: .done, priority: .low,
              recurrence: .weekly, assigneeId: jules.id, rotationOrder: [],
              xpReward: 5, dueDate: .now.addingTimeInterval(-60*60*60),
              completedAt: .now.addingTimeInterval(-60*60*55),
              streak: 1,
              createdAt: .now.addingTimeInterval(-60*60*96)),

        // An overdue chore so the "Needs attention" card has data.
        Chore(id: UUID(), householdId: householdId,
              title: "Wipe counters", note: nil,
              icon: "sparkles", status: .todo, priority: .normal,
              recurrence: .daily, assigneeId: alex.id, rotationOrder: [],
              xpReward: 8, dueDate: .now.addingTimeInterval(-60*60*36),
              completedAt: nil, streak: 0,
              createdAt: .now.addingTimeInterval(-60*60*48)),
    ]

    // MARK: - Grocery

    static let grocery: [GroceryItem] = [
        .init(id: UUID(), householdId: householdId, title: "Strawberries",
              brand: nil, quantity: "1 box",
              category: .produce, isChecked: false,
              addedById: currentUser.id, photoURL: nil,
              addedAt: .now.addingTimeInterval(-60*60*3)),

        .init(id: UUID(), householdId: householdId, title: "Spinach",
              brand: "Earthbound", quantity: nil,
              category: .produce, isChecked: false,
              addedById: alex.id, photoURL: nil,
              addedAt: .now.addingTimeInterval(-60*60*2)),

        .init(id: UUID(), householdId: householdId, title: "Oat milk",
              brand: "Oatly", quantity: "2",
              category: .dairy, isChecked: false,
              addedById: sam.id, photoURL: nil,
              addedAt: .now.addingTimeInterval(-60*60*5)),

        .init(id: UUID(), householdId: householdId, title: "Butter",
              brand: "Kerrygold", quantity: nil,
              category: .dairy, isChecked: true,
              addedById: jules.id, photoURL: nil,
              addedAt: .now.addingTimeInterval(-60*60*9)),

        .init(id: UUID(), householdId: householdId, title: "Frozen dumplings",
              brand: "Trader Joe's", quantity: "2 bags",
              category: .frozen, isChecked: false,
              addedById: currentUser.id, photoURL: nil,
              addedAt: .now.addingTimeInterval(-60*60*1)),

        .init(id: UUID(), householdId: householdId, title: "Olive oil",
              brand: nil, quantity: nil,
              category: .pantry, isChecked: false,
              addedById: alex.id, photoURL: nil,
              addedAt: .now.addingTimeInterval(-60*60*4)),

        .init(id: UUID(), householdId: householdId, title: "Pasta",
              brand: "Barilla", quantity: "2 boxes",
              category: .pantry, isChecked: false,
              addedById: currentUser.id, photoURL: nil,
              addedAt: .now.addingTimeInterval(-60*60*6)),

        .init(id: UUID(), householdId: householdId, title: "Dark chocolate",
              brand: nil, quantity: nil,
              category: .snacks, isChecked: false,
              addedById: jules.id, photoURL: nil,
              addedAt: .now.addingTimeInterval(-60*60*8)),

        .init(id: UUID(), householdId: householdId, title: "Dish soap",
              brand: "Mrs. Meyer's", quantity: nil,
              category: .cleaning, isChecked: false,
              addedById: sam.id, photoURL: nil,
              addedAt: .now.addingTimeInterval(-60*60*7)),
    ]

    // MARK: - Notes

    static let notes: [Note] = [
        .init(id: UUID(), householdId: householdId,
              title: "Sunday plan",
              body: "Brunch at 11, then farmer's market.",
              color: .coral, todos: [],
              rotation: -2.4, orderIndex: 0,
              authorId: currentUser.id, pinned: true,
              createdAt: .now.addingTimeInterval(-60*60*16),
              updatedAt: .now.addingTimeInterval(-60*60*1)),

        .init(id: UUID(), householdId: householdId,
              title: "Wifi password",
              body: "sunny-loft-2026",
              color: .amber, todos: [],
              rotation: 1.6, orderIndex: 1,
              authorId: alex.id, pinned: true,
              createdAt: .now.addingTimeInterval(-60*60*48),
              updatedAt: .now.addingTimeInterval(-60*60*30)),

        .init(id: UUID(), householdId: householdId,
              title: "Trip packing",
              body: "",
              color: .indigo,
              todos: [
                .init(id: UUID(), text: "Sunscreen", done: true),
                .init(id: UUID(), text: "Beach towels", done: false),
                .init(id: UUID(), text: "Speaker", done: false),
                .init(id: UUID(), text: "Snacks", done: true),
              ],
              rotation: -1.2, orderIndex: 2,
              authorId: jules.id, pinned: false,
              createdAt: .now.addingTimeInterval(-60*60*24),
              updatedAt: .now.addingTimeInterval(-60*60*2)),

        .init(id: UUID(), householdId: householdId,
              title: "Movie night picks",
              body: "Sam votes Studio Ghibli\nAlex says Drive\nJules abstains",
              color: .teal, todos: [],
              rotation: 2.0, orderIndex: 3,
              authorId: sam.id, pinned: false,
              createdAt: .now.addingTimeInterval(-60*60*20),
              updatedAt: .now.addingTimeInterval(-60*60*10)),

        .init(id: UUID(), householdId: householdId,
              title: "Plant care",
              body: "Monstera every 5 days. Pothos when the soil is dry.",
              color: .peach, todos: [],
              rotation: -0.8, orderIndex: 4,
              authorId: currentUser.id, pinned: false,
              createdAt: .now.addingTimeInterval(-60*60*72),
              updatedAt: .now.addingTimeInterval(-60*60*70)),
    ]

    // MARK: - Activity

    static let activity: [ActivityEvent] = [
        .init(id: UUID(), householdId: householdId, actorId: alex.id,
              kind: .choreCompleted, subject: "Take out trash",
              icon: "trash.fill", xpDelta: 15,
              createdAt: .now.addingTimeInterval(-60*5)),

        .init(id: UUID(), householdId: householdId, actorId: sam.id,
              kind: .groceryAdded, subject: "Oat milk",
              icon: "drop.fill", xpDelta: 1,
              createdAt: .now.addingTimeInterval(-60*40)),

        .init(id: UUID(), householdId: householdId, actorId: jules.id,
              kind: .achievementUnlocked, subject: "Laundry Legend",
              icon: "trophy.fill", xpDelta: 25,
              createdAt: .now.addingTimeInterval(-60*60*2)),

        .init(id: UUID(), householdId: householdId, actorId: currentUser.id,
              kind: .noteAdded, subject: "Sunday plan",
              icon: "note.text", xpDelta: 2,
              createdAt: .now.addingTimeInterval(-60*60*5)),

        .init(id: UUID(), householdId: householdId, actorId: alex.id,
              kind: .streakSaved, subject: "Trash duty",
              icon: "flame.fill", xpDelta: 25,
              createdAt: .now.addingTimeInterval(-60*60*22)),
    ]

    // MARK: - Achievements

    static var unlockedAchievements: [Achievement] {
        var laundry = AchievementCatalog.all[0]
        laundry.unlockedAt = .now.addingTimeInterval(-60*60*24*2)
        var trash = AchievementCatalog.all[1]
        trash.unlockedAt = .now.addingTimeInterval(-60*60*24*7)
        return [laundry, trash]
    }
}
