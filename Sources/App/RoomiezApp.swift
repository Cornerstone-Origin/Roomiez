import SwiftUI

@main
struct RoomiezApp: App {
    @StateObject private var auth      = AuthService()
    @StateObject private var appState  = AppState()
    @StateObject private var router    = TabRouter()

    init() {
        // Make any system list / scroll background match our warm cream.
        let cream = UIColor(Theme.Palette.background)
        UITableView.appearance().backgroundColor = cream
        UICollectionView.appearance().backgroundColor = cream
        UIScrollView.appearance().backgroundColor = cream
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(auth)
                .environmentObject(appState)
                .environmentObject(router)
                .tint(Theme.Palette.text)
                .preferredColorScheme(.light)
        }
    }
}
