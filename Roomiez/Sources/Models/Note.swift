import SwiftUI

enum NoteColor: String, Codable, CaseIterable, Sendable {
    case coral, teal, amber, indigo, peach, sky

    /// Sticky notes use very-light tinted paper — readable on white,
    /// distinct from each other, never compete with the brand accents.
    var swiftUI: Color {
        switch self {
        case .coral:  return Color(hex: "FFE4D6")   // light coral paper
        case .teal:   return Color(hex: "D1FAE5")   // light mint paper
        case .amber:  return Color(hex: "FEF3C7")   // light yellow paper
        case .indigo: return Color(hex: "E0E7FF")   // light periwinkle paper
        case .peach:  return Color(hex: "FFEDD5")
        case .sky:    return Color(hex: "DBEAFE")
        }
    }
}

struct NoteTodo: Identifiable, Codable, Hashable, Sendable {
    let id: UUID
    var text: String
    var done: Bool
}

struct Note: Identifiable, Codable, Hashable, Sendable {
    let id: UUID
    var householdId: UUID
    var title: String
    var body: String
    var color: NoteColor
    var todos: [NoteTodo]
    var rotation: Double             // small random tilt — sticky-note feel
    var orderIndex: Int              // for drag-reorder
    var authorId: UUID?
    var pinned: Bool
    var createdAt: Date
    var updatedAt: Date

    var isTodoList: Bool { !todos.isEmpty }

    enum CodingKeys: String, CodingKey {
        case id
        case householdId = "household_id"
        case title, body, color, todos, rotation
        case orderIndex  = "order_index"
        case authorId    = "author_id"
        case pinned
        case createdAt   = "created_at"
        case updatedAt   = "updated_at"
    }
}
