import SwiftUI

struct RootView: View {
    @EnvironmentObject private var auth: AuthService
    @EnvironmentObject private var appState: AppState
    @EnvironmentObject private var router: TabRouter

    var body: some View {
        ZStack {
            switch auth.state {
            case .loading:
                LoadingScreen()
                    .transition(.opacity)
            case .signedOut:
                AuthView()
                    .transition(.opacity)
            case .signedIn:
                MainTabScaffold()
                    .transition(.opacity)
            }

            if let celebration = appState.celebration {
                CelebrationOverlay(
                    title: celebration.title,
                    message: celebration.message,
                    systemName: celebration.systemImage,
                    tint: celebration.tint
                )
                .zIndex(99)
            }
        }
        .animation(Theme.Motion.gentle, value: auth.state)
        .animation(Theme.Motion.spring, value: appState.celebration)
    }
}

struct LoadingScreen: View {
    var body: some View {
        ZStack {
            Theme.Gradients.warmSky.ignoresSafeArea()
            VStack(spacing: 14) {
                Text("🏡").font(.system(size: 60))
                ProgressView()
                    .tint(Theme.Palette.text)
                Text("Tidying things up…")
                    .font(.cozyCaption)
                    .foregroundStyle(Theme.Palette.textSoft)
            }
        }
    }
}

struct MainTabScaffold: View {
    @EnvironmentObject private var appState: AppState
    @EnvironmentObject private var router: TabRouter

    var body: some View {
        ZStack(alignment: .bottom) {
            Group {
                switch router.selected {
                case .dashboard: DashboardView(appState: appState)
                case .chores:    ChoreBoardView(appState: appState)
                case .grocery:   GroceryListView(appState: appState)
                case .notes:     NotesHubView(appState: appState)
                case .profile:   ProfileView()
                }
            }
            .transition(.identity)
            .animation(nil, value: router.selected)

            CozyTabBar(selected: $router.selected)
                .padding(.horizontal, Theme.Spacing.md)
                .padding(.bottom, 8)
        }
        .ignoresSafeArea(.keyboard, edges: .bottom)
    }
}
