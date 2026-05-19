import SwiftUI
import Combine

enum AppTab: Hashable, CaseIterable {
    case dashboard, chores, grocery, notes, profile

    var title: String {
        switch self {
        case .dashboard: "Home"
        case .chores:    "Chores"
        case .grocery:   "Grocery"
        case .notes:     "Notes"
        case .profile:   "You"
        }
    }
    var icon: String {
        switch self {
        case .dashboard: "house.fill"
        case .chores:    "checkmark.seal.fill"
        case .grocery:   "cart.fill"
        case .notes:     "note.text"
        case .profile:   "person.crop.circle.fill"
        }
    }
    var tint: Color {
        switch self {
        case .dashboard: Theme.Palette.coral
        case .chores:    Theme.Palette.teal
        case .grocery:   Theme.Palette.amber
        case .notes:     Theme.Palette.indigo
        case .profile:   Color(hex: "FFD8B5")
        }
    }
}

@MainActor
final class TabRouter: ObservableObject {
    @Published var selected: AppTab = .dashboard

    func go(_ tab: AppTab) {
        withAnimation(Theme.Motion.spring) { selected = tab }
        Haptics.selection()
    }
}
