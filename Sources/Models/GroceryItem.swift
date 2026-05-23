import SwiftUI

enum GroceryCategory: String, Codable, CaseIterable, Identifiable, Sendable {
    case produce, dairy, frozen, pantry, snacks, cleaning, other

    var id: String { rawValue }
    var title: String {
        switch self {
        case .produce:  "Produce"
        case .dairy:    "Dairy"
        case .frozen:   "Frozen"
        case .pantry:   "Pantry"
        case .snacks:   "Snacks"
        case .cleaning: "Cleaning"
        case .other:    "Other"
        }
    }
    /// SF Symbol name.
    var icon: String {
        switch self {
        case .produce:  "leaf.fill"
        case .dairy:    "drop.fill"
        case .frozen:   "snowflake"
        case .pantry:   "shippingbox.fill"
        case .snacks:   "popcorn.fill"
        case .cleaning: "bubbles.and.sparkles.fill"
        case .other:    "cart.fill"
        }
    }
    var tint: Color {
        switch self {
        case .produce:  Theme.Palette.forest
        case .dairy:    Theme.Palette.slate
        case .frozen:   Color(hex: "8FB3C9")
        case .pantry:   Theme.Palette.ochre
        case .snacks:   Theme.Palette.brick
        case .cleaning: Theme.Palette.indigo
        case .other:    Theme.Palette.sand
        }
    }

    /// Quick-add suggestions per category — mirrors the chore-icon
    /// preset pattern so users can tap a chip instead of typing a
    /// title from scratch. Tweak this list to change the suggestions
    /// surfaced in the grocery smart-input bar.
    var presets: [String] {
        switch self {
        case .produce:
            return ["Bananas", "Apples", "Avocados", "Tomatoes",
                    "Spinach", "Onions", "Lettuce", "Garlic",
                    "Lemons", "Berries", "Carrots", "Bell peppers"]
        case .dairy:
            return ["Milk", "Eggs", "Butter", "Yogurt",
                    "Cheddar", "Cream cheese", "Oat milk",
                    "Heavy cream", "Sour cream", "Parmesan"]
        case .frozen:
            return ["Ice cream", "Frozen pizza", "Frozen veggies",
                    "Frozen berries", "Waffles", "Frozen dumplings",
                    "Ice cubes", "Veggie burgers"]
        case .pantry:
            return ["Rice", "Pasta", "Bread", "Cereal",
                    "Coffee", "Olive oil", "Sugar", "Flour",
                    "Peanut butter", "Black beans", "Pasta sauce",
                    "Tortillas", "Honey"]
        case .snacks:
            return ["Chips", "Crackers", "Popcorn", "Cookies",
                    "Granola bars", "Chocolate", "Mixed nuts",
                    "Pretzels", "Trail mix", "Dried fruit"]
        case .cleaning:
            return ["Paper towels", "Toilet paper", "Dish soap",
                    "Laundry detergent", "Sponges", "Trash bags",
                    "All-purpose cleaner", "Bleach", "Dryer sheets"]
        case .other:
            return ["Batteries", "Light bulbs", "Pet food",
                    "Toothpaste", "Shampoo", "Hand soap",
                    "Sunscreen", "Tissues"]
        }
    }
}

struct GroceryItem: Identifiable, Codable, Hashable, Sendable {
    let id: UUID
    var householdId: UUID
    var title: String                // "Oat milk"
    var brand: String?               // "Oatly"
    var quantity: String?            // "2", "1 dozen"
    var category: GroceryCategory
    var isChecked: Bool
    var addedById: UUID?
    var photoURL: URL?
    var addedAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case householdId = "household_id"
        case title, brand, quantity, category
        case isChecked   = "is_checked"
        case addedById   = "added_by_id"
        case photoURL    = "photo_url"
        case addedAt     = "added_at"
    }
}
