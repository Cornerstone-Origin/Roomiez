# Roomiez — Design Journey & Current State

A self-contained brief for a Claude session picking up where the last one left off. Read [CLAUDE.md](../CLAUDE.md) first for architecture + conventions; this doc focuses on **what was tried, what was kept, and why**.

## Where things stand right now

- **Home page** is the household profile (hero + roommates + house rules + recent updates).
- **Bottom nav** is a glass pill with 4 plain SF Symbol side tabs (Chores / Grocery / Notes / You) + an **elevated central house hub** (offset `-14pt`, glassy tinted circle).
- **All pages** use [`PearlBackground`](../Sources/Components/PearlBackground.swift): diagonal pearl gradient + 3 blurred coral / periwinkle / marigold orbs.
- **All cards** follow the grocery-page recipe: outer tinted container (fill `0.18`, stroke `0.35`, no shadow) + inner white "mini-card" rows ([`ListItemRow`](../Sources/Components/ListItemRow.swift)).
- **Icons** are SF Symbols with `.symbolRenderingMode(.multicolor)` on the `IconBadge.solid` style — gives the "painted emoji" look without using emoji characters.
- **Palette** is Flat UI Colors (Bittersweet, Mint, Sunflower, Aqua, Blue Jeans, Grapefruit, Grass).
- **Workflow**: every code change is followed by `scripts/run.sh` which builds and relaunches the app on the iPhone 17 simulator.

## How the design landed there — the iteration timeline

### Phase 1 — Original cozy/fridge-magnet aesthetic
First build shipped with pastel pinks + lavender, heavy emoji usage, sticky-note cards.

**User feedback**: "way too girly" → first colour pass.

### Phase 2 — Colour iterations
Tried, in order: warm-modern jewel tones (too dull) → vibrant pastels (too girly) → modern brand saturated (still too pastel) → Park palette bold Tailwind 500s ("dull, want neon") → Tailwind 400 neon-bright cyan-led palette ("looks like a game") → **Flat UI Colors** (kept).

**Lesson**: the user dislikes pastel pinks/lavenders ("girly") and overly bright neon ("kid-like"). Flat UI hits the playful-but-grown-up balance they wanted.

### Phase 3 — Tile shape iterations
Tried, in order: white interior + colored border + colored drop shadow → Duolingo-chunky-button (solid colored top + darker bottom strip) ("too gamey") → flat with strong bevel borders ("shadows everywhere") → solid color fill with 3D top-bright/bottom-dark border gradient → **liquid glass** ([`.glassEffect`](../Sources/Core/Extensions/View+Extensions.swift)) → reverted to grocery's flat tinted container + white inner rows (kept).

**Lesson**: don't over-engineer the card surface. The grocery section's tinted container + white rows is the canonical pattern.

### Phase 4 — Icon iterations
Started with emoji characters everywhere (🏡 🥬 🧺 etc) → user wanted them removed ("way too many emojis") → swapped to outlined / filled SF Symbols → user asked for "colorful emoji-style drawings" → enabled `.symbolRenderingMode(.multicolor)` on `IconBadge.solid` so SF Symbols render in their native multi-tone palettes (leaf → green, drop → blue, flame → orange/yellow, etc.) (kept).

**Lesson**: SF Symbol `.multicolor` is the "emoji with colour" sweet spot for this user. Don't propose actual emoji characters.

### Phase 5 — Avatar iterations
Started with emoji avatars (🐰 🌿 ☕️). Rebuilt to **initials in coloured circles** ([`AvatarView`](../Sources/Components/AvatarView.swift)) — kept.

### Phase 6 — Bottom nav iterations
Originally a 5-tab equal-row pill. Restructured to **centre-hub layout**: 4 plain side tabs + elevated house hub. Then briefly experimented with glass-cushion icon tiles ([`CushionTile.swift`](../Sources/Components/CushionTile.swift), still in the repo) — user reverted to the simple icon-only tabs. The hub itself was originally a solid gradient circle ("doesn't blend with the glass nav bar") → now a translucent material with subtle colour bleed (kept).

### Phase 7 — Home page restructure
The original "dashboard" had previews of chores / grocery / notes / activity. Restructured so the home tab is the **household profile**: house hero + roommates + house rules + recent updates. Quick actions removed (the centre house hub covers that need; side tabs cover the rest).

Added `Household.rules: [String]` for the rules section, seeded with 5 starter rules in [`PreviewData`](../Sources/Resources/PreviewData.swift).

### Phase 8 — Background + section unification
Pearl background ([`PearlBackground`](../Sources/Components/PearlBackground.swift)) extracted as a reusable component and applied across every page. Each list card got a tinted gradient stroke matching its section's brand color (mint for chores, marigold for grocery, coral for notes/rules, azure for activity, periwinkle for roommates). Scroll-triggered fade/scale animations were tried (`scrollLift`, `stretchyTop`) and then **explicitly removed** per user request — they preferred static cards.

## Components — what's where and why

### Tiles & layout primitives
- [`CozyCard`](../Sources/Components/CozyCard.swift) — tinted container. Flat, no shadow. Used for one-off panels.
- [`ListCard`](../Sources/Components/ListItemRow.swift) — tinted container with `VStack(spacing: 10)` inside. Used to group multiple rows.
- [`ListItemRow`](../Sources/Components/ListItemRow.swift) — self-contained white mini-card row. Same recipe `GroceryItemRow` uses.
- [`HeroCard`](../Sources/Components/HeroCard.swift) — big gradient hero with decorative white blobs + white-stroke gradient border. Currently only used on the home page.
- [`IconBadge`](../Sources/Components/IconBadge.swift) — three styles: `.soft` (low-opacity tint + stroke), `.solid` (white→tint cushion + multicolor SF Symbol), `.outline`. Use `.solid` for category headers and chore icons.
- [`AvatarView`](../Sources/Components/AvatarView.swift) — initials in colored circle.
- [`PearlBackground`](../Sources/Components/PearlBackground.swift) — the diagonal pearl gradient + 3 blurred orbs. `.allowsHitTesting(false)`.
- [`CozyTabBar`](../Sources/Components/CozyTabBar.swift) — glass pill + elevated house hub.
- [`RoomiezMark`](../Sources/Components/RoomiezMark.swift) — custom brand mark (geometric "R") used on the auth screen.

### Feature views
- [`DashboardView`](../Sources/Features/Dashboard/DashboardView.swift) — household profile (home tab)
- [`ChoreBoardView`](../Sources/Features/Chores/ChoreBoardView.swift) + [`AddChoreSheet`](../Sources/Features/Chores/AddChoreSheet.swift)
- [`GroceryListView`](../Sources/Features/Grocery/GroceryListView.swift) + [`AddGrocerySheet`](../Sources/Features/Grocery/AddGrocerySheet.swift) — **the canonical visual reference** for cards
- [`NotesHubView`](../Sources/Features/Notes/NotesHubView.swift) + [`NoteEditorSheet`](../Sources/Features/Notes/NoteEditorSheet.swift)
- [`ProfileView`](../Sources/Features/Profile/ProfileView.swift)
- [`AchievementsView`](../Sources/Features/Gamification/AchievementsView.swift)
- [`AuthView`](../Sources/Features/Auth/AuthView.swift)

### Services + models
- [`AppState`](../Sources/App/AppState.swift) — dependency container, holds repos + currentUser + household.
- [`SupabaseManager`](../Sources/Services/SupabaseManager.swift) — auto-detects `Sources/Resources/SupabaseConfig.plist`; without it, the app uses [`LocalSeedRepositories`](../Sources/Services/LocalSeedRepositories.swift) seeded from [`PreviewData`](../Sources/Resources/PreviewData.swift).
- Models: [`Chore`](../Sources/Models/Chore.swift), [`GroceryItem`](../Sources/Models/GroceryItem.swift), [`Note`](../Sources/Models/Note.swift), [`Household`](../Sources/Models/Household.swift) (has `rules: [String]`), [`RoomieUser`](../Sources/Models/User.swift) (has `avatarInitials`), [`Achievement`](../Sources/Models/Achievement.swift), [`ActivityEvent`](../Sources/Models/ActivityEvent.swift). All icon fields are SF Symbol names (never emoji).

## Build + launch workflow

Always after a code change:

```bash
scripts/run.sh
```

The script handles everything — picking a simulator, building, terminating any running instance, reinstalling, relaunching. Output worth grepping: `error:` and `BUILD SUCCEEDED` / `BUILD FAILED`.

If Xcode itself acts up (hung on launch, "ContentView.swift not found", etc.), the fix has always been:

```bash
pkill -9 Xcode
rm -rf ~/Library/Developer/Xcode/DerivedData/Roomiez-* \
       Roomiez/Roomiez.xcodeproj/xcuserdata \
       Roomiez/Roomiez.xcodeproj/project.xcworkspace/xcuserdata \
       Roomiez/Roomiez.xcodeproj/project.xcworkspace/xcshareddata/swiftpm
```

If project settings drift, [`scripts/configure_project.rb`](../scripts/configure_project.rb) re-applies the right Swift 6 / iOS-only / Supabase package config in one shot.

## Open / potential next steps

- Apply the grocery-style tinted container + white-row pattern more deeply to the **Chores** and **Notes** pages (currently they use their own card layouts — `ChoreCard` is its own tinted tile; `StickyNoteCard` is a grid tile).
- Wire up real Supabase: drop credentials into `Sources/Resources/SupabaseConfig.plist` (template at [`Sources/Resources/SupabaseConfig.example.plist`](../Sources/Resources/SupabaseConfig.example.plist)); schema is at [`Supabase/schema.sql`](../Supabase/schema.sql).
- House rules editing UI (currently read-only, no add/edit flow).
- Push notifications (deferred).
- Photo upload to Supabase Storage for grocery items (model field exists, no UI yet).
