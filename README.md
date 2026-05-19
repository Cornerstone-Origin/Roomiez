# Roomiez 🏡

A cozy, gamified household management app for roommates, couples, and families.
Built with **SwiftUI · Swift 6 · MVVM · Supabase**.

* Soft pastel design system, rounded cards, sticky notes, layered shadows
* Shared dashboard with house XP, harmony meter, weekly streak, recent activity
* Kanban-style chore board with auto-rotation, recurrence and XP rewards
* Collaborative grocery list grouped by category
* Sticky-note hub with mini todos
* Gamification system: levels, achievements, leaderboard, cosmetic unlocks
* Realtime sync via Supabase (with a seed-data fallback so the app runs
  offline / before credentials are wired up)

---

## 1 · Create the Xcode project

The repo intentionally ships source files only — the Xcode project file is
machine-specific. All the Swift source lives under `Sources/` so Xcode is
free to create its own `Roomiez/` wrapper folder without colliding.

Final layout after setup:

```
Desktop/Roomiez/
├── Roomiez/                  ← created by Xcode (project + target sources)
│   ├── Roomiez.xcodeproj
│   └── Roomiez/              ← Xcode's stub target folder (you'll empty it)
├── Sources/                  ← all the Swift files in this repo
├── Supabase/
└── Docs/
```

1. Open **Xcode → File → New → Project**.
2. Choose **iOS → App**.
3. Settings:
   * **Product Name:** `Roomiez`
   * **Team:** *your team*
   * **Organization Identifier:** `com.yourname`
   * **Interface:** SwiftUI
   * **Language:** Swift
   * **Storage:** None
4. Save the project **inside this folder** (`/Desktop/Roomiez/`). Xcode will
   create `/Desktop/Roomiez/Roomiez/Roomiez.xcodeproj`.
5. In the new project, **delete** Xcode's stub `ContentView.swift` and the
   auto-generated `RoomiezApp.swift` (they conflict with the ones in
   `Sources/App/`). Move them to Trash when prompted.
6. In Finder, drag the `Sources/` folder onto the Xcode project navigator.
   In the import dialog:
   * **Action:** "Create groups" *(not folder references)*
   * **Add to targets:** ✓ Roomiez
   All the `App`, `Core`, `Theme`, `Components`, `Features`, `Models`,
   `Services`, `Utilities`, `Resources` subdirectories will appear in the
   navigator.
7. In **Project ▸ Target ▸ Build Settings** set:
   * **iOS Deployment Target:** 17.0
   * **Swift Language Version:** Swift 6
   * **Strict Concurrency Checking:** Complete
8. In **Project ▸ Target ▸ Info** replace the default `Info.plist` with the
   one in `Sources/Resources/Info.plist` (or merge the keys you care about —
   the `UILaunchScreen → UIColorName: LaunchBackground` and camera/photo
   usage strings are the important ones).
9. Confirm `Sources/Resources/Assets.xcassets` is in the project navigator
   and has target membership on **Roomiez**.

## 2 · Add the Supabase Swift SDK

In Xcode:

1. **File → Add Package Dependencies…**
2. URL: `https://github.com/supabase/supabase-swift`
3. Version: **Up to Next Major** from `2.0.0`
4. Add **Supabase** product to the **Roomiez** app target.

## 3 · Configure Supabase credentials

The app runs **without** credentials — it just uses in-memory seed data so you
can preview the design immediately. To use a real backend:

1. Create a project at <https://supabase.com>.
2. In **SQL Editor**, paste and run `Supabase/schema.sql`.
   (Optional: paste `Supabase/seed.sql` for sample rows.)
3. Copy your project URL and `anon` key from **Project Settings → API**.
4. In `Sources/Resources/` copy `SupabaseConfig.example.plist` to
   `SupabaseConfig.plist` and paste your URL/key in.
5. Add `SupabaseConfig.plist` to the target (drag into Xcode, ensure
   *Target Membership* is checked). Keep it out of git.

`SupabaseManager.swift` will pick those up automatically. If it can't find
them, the app silently falls back to `LocalSeedRepositories` and runs offline.

## 4 · Run

`⌘R` from Xcode — iPhone 15 simulator or any iOS 17+ device.

The first launch lands directly on the dashboard (the local seed user is
auto-signed-in). With Supabase credentials, the auth screen appears first.

---

## Architecture

```
Sources/
├── App/                 RoomiezApp · AppState · RootView
├── Core/
│   ├── Extensions/      Color(hex:), Date helpers, View modifiers
│   └── Navigation/      TabRouter + AppTab enum
├── Theme/               Theme, Typography, Shadows
├── Components/          CozyCard, XPBar, HarmonyMeter, ChoreCard,
│                        StickyNoteCard, GroceryItemRow, ConfettiView,
│                        AchievementBadge, CozyTabBar, …
├── Features/
│   ├── Dashboard/       DashboardView + ViewModel
│   ├── Chores/          ChoreBoardView, AddChoreSheet + ViewModel
│   ├── Grocery/         GroceryListView, AddGrocerySheet + ViewModel
│   ├── Notes/           NotesHubView, NoteEditorSheet + ViewModel
│   ├── Gamification/    AchievementsView + ViewModel · LevelService
│   ├── Auth/            AuthView
│   └── Profile/         ProfileView · InviteRoomieSheet
├── Models/              User, Household, Chore, GroceryItem, Note,
│                        Achievement, ActivityEvent (Codable, snake_case keys)
├── Services/
│   ├── SupabaseManager      Single client, reads SupabaseConfig.plist
│   ├── Repositories         Protocols all views depend on
│   ├── LocalSeedRepositories In-memory, used for previews / no-creds
│   ├── SupabaseRepositories Real Postgres + Realtime implementation
│   ├── AuthService          Email/password + auto profile bootstrap
│   ├── RealtimeService      Subscribes to all household-scoped tables
│   └── LevelService         XP rewards, harmony deltas, level titles
├── Utilities/           Haptics · Log (OSLog wrappers)
└── Resources/           PreviewData · Info.plist · SupabaseConfig.example
                         Assets.xcassets (AppIcon, AccentColor, Launch)
```

The pattern: views read from `@EnvironmentObject` (`AppState`, `AuthService`,
`TabRouter`) and call ViewModels that talk to the repository protocols.
Supabase is **never** referenced from views.

---

## What's where

* **House XP / Harmony / Streaks** — `LevelService` + `AppState.logEvent`
  (every action funnels through here and bumps both personal XP and the
  shared house meters).
* **Auto-rotation of recurring chores** — `ChoreBoardViewModel.complete`
  spawns the next instance with `rotatedAssignee(…)`.
* **Celebrations / confetti** — `AppState.celebrate(…)` raises a banner
  that `RootView` renders on top of any screen.
* **Realtime** — `RealtimeService.start` subscribes to all six household
  tables; the callback refreshes `AppState`.
* **Design tokens** — change once in `Theme/Theme.swift` and the whole app
  reskins.

---

## License

MIT — make your home cozy.
