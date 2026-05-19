# Roomiez

SwiftUI household management app: chores, grocery, notes, gamified house stats. Swift 6 · MVVM · Supabase (with in-memory seed-data fallback).

This file auto-loads in every Claude Code session in this folder. Read [Docs/handoff.md](Docs/handoff.md) for the full design journey + rejected directions.

---

## Architecture

```
View  →  ViewModel  →  AppState  →  Repository protocol
                                       │
                            ┌──────────┴──────────┐
                            ▼                     ▼
                  LocalSeedRepositories   SupabaseRepositories
```

- All Swift source: [`Sources/`](Sources/)
- Xcode project: [`Roomiez/Roomiez.xcodeproj`](Roomiez/Roomiez.xcodeproj) uses a `PBXFileSystemSynchronizedRootGroup` pointing at `../Sources/`.
- Bundle id: `cornerstoneorigin.Roomiez`
- Deployment target: iOS 17, Swift 6, strict concurrency complete, iOS-only
- Code signing disabled for simulator
- Repair project settings: `ruby scripts/configure_project.rb`

## Workflow — build + launch after every change

Run after ANY Swift / project / asset change:

```bash
scripts/run.sh
```

Picks an iPhone sim (prefers booted, else iPhone 17), builds via `xcodebuild` into `.build/derived`, terminates + reinstalls + relaunches. Grep `error:` / `BUILD SUCCEEDED` from output. Auto-launch is expected after every iteration.

If Xcode hangs or shows phantom file errors:

```bash
pkill -9 Xcode
rm -rf ~/Library/Developer/Xcode/DerivedData/Roomiez-* \
       Roomiez/Roomiez.xcodeproj/xcuserdata \
       Roomiez/Roomiez.xcodeproj/project.xcworkspace/xcuserdata \
       Roomiez/Roomiez.xcodeproj/project.xcworkspace/xcshareddata/swiftpm
```

---

## Pages

### Home tab — [`DashboardView`](Sources/Features/Dashboard/DashboardView.swift)

Section order:

1. **Greeting header** — "Your household" caption + house name. Right side: avatar stack + history button (`clock.arrow.circlepath`) + edit pencil button.
2. **Hero tile** — periwinkle linear-gradient fill over [`CozyHomeBackdrop`](Sources/Components/CozyHomeBackdrop.swift). Layout: tier-coloured `Lv N` pill (button → opens `HouseLevelsSheet`) + slim XP bar on the right top row, big bold `levelTitle` underneath, tier `blurb` below. A `HouseTierImage` (illustrated cartoon house, 110pt) sits as a watermark on the right, anchored below the XP bar so it doesn't overlap.
3. **Today** ([`todaySection`](Sources/Features/Dashboard/DashboardView.swift)) — `vm.todaysChoresForMe`: chores due today (or already overdue) assigned to the signed-in user. Each row is a flat-icon mini-card with title, due-date / "Late" pill, `+X XP`, and an outlined green check button. Tapping the check fires a per-row completing animation (dim + scale + checkmark overlay) then runs `vm.completeChore`. Empty state: "You're caught up — nothing due for you today."
4. **House pulse** — 3-tile highlights row (Top this week / Most consistent / Overdue) — each tile has flat-icon recipe, single-line title (`lineLimit(1) + minimumScaleFactor`), `maxHeight: .infinity` so heights stay equal. Below: untinted leaderboard `ListCard` + conditional Overdue `ListCard`.
5. **Roommates** — untinted `ListCard` with member rows.
6. **House rules** — untinted `ListCard` with numbered rule rows.
7. **Recent updates** — untinted `ListCard`. Rows use the **flat icon recipe** (38pt rounded square w/ `tint.opacity(0.12)` fill, tint glyph) instead of `IconBadge.solid`. Inline custom `activityRow(_:)` view in `DashboardView`, not `ListItemRow`.

Sheets owned by Dashboard:
- [`HouseLevelsSheet`](Sources/Features/Dashboard/HouseLevelsSheet.swift) — 10-tier ladder with `HouseTierImage` per row. Current level highlighted with "You're here" pill; higher levels dimmed with lock glyph.
- [`HouseHistorySheet`](Sources/Features/Dashboard/HouseHistorySheet.swift) — XP gains/losses + level-up/down events, bucketed Today / Yesterday / Earlier this week / Older. Each row: tier-tinted icon, who-did-what headline, relative time, coloured `+X XP` / `-X XP` pill (forest / rose) or up/down arrow for level changes.
- [`EditHouseholdSheet`](Sources/Features/Dashboard/EditHouseholdSheet.swift) — name field, rules editor (add/edit/reorder/delete), members list w/ remove-with-confirmation, invite code with copy button.
- `InviteRoomieSheet` (defined in [`ProfileView.swift`](Sources/Features/Profile/ProfileView.swift)) — opened from the Roommates section header's "Invite" trailing button.

### Chores tab — [`ChoreBoardView`](Sources/Features/Chores/ChoreBoardView.swift)

1. **Header** — title + `StreakChip` (outlined-only, ink stroke matching tile borders).
2. [`ChoreCalendarStrip`](Sources/Features/Chores/ChoreCalendarStrip.swift) — 7 past + 90 future days, free horizontal scroll. Header: calendar icon circle (ink stroke, no fill) + month label + outlined "Today" jump button. Day pills: selected day fills with [`Theme.Gradients.accent`](Sources/Theme/Theme.swift) (pastel coral→azure peach→sky). Today's outline + count dots use the same gradient via `accentGradient` computed prop. Count badge `>=2`: gradient text + soft-gradient capsule. Counts only include literal due-date matches (no projection).
3. **Status segmented control** + **filter button** in one HStack. Status is a single capsule with three segments and a `matchedGeometryEffect` sliding pill indicator tinted with the active status's colour (brick/ochre/forest). Horizontal swipe gesture cycles statuses. Filter button (circular `line.3.horizontal.decrease` icon) sits on the left of the control, fills azure when any filter is active.
4. **Chore list** — `ChoreCard`s for the selected date only (no projection). On Today, also includes past-due unfinished chores so they surface. `LazyVStack(spacing: 10)`.

Filter sheet — [`ChoreFilterSheet`](Sources/Features/Chores/ChoreFilterSheet.swift)
- **Assigned to** — Everyone / You / each roommate.
- **Priority** — All / Low / Normal / High chips.
- **Rate** — Any / Once / Daily / Weekly / Biweekly / Monthly chips in a wrapping `FlowLayout`.
- **Sort by** — Due date / Priority / XP / Title A-Z.
- **Reset all filters** button at the bottom when any filter is set.
- `ChoreSortOrder` enum lives in this file.

`FloatingAddButton` on Chores / Grocery / Notes: 60×60 circle with `.ultraThinMaterial` base + `coral.opacity(0.62)→azure.opacity(0.62)` linear gradient overlay + white border + white plus icon (mirrors the home hub).

### Grocery tab — [`GroceryListView`](Sources/Features/Grocery/GroceryListView.swift)

1. **Compact header** — "Grocery" title + history button (`clock.arrow.circlepath`) + hide-checked toggle (`eye.fill` / `eye.slash.fill`). Stats line + coral→marigold progress capsule showing completion fraction.
2. **Smart input bar** — single text field that filters as you type. When non-empty: clear ✕ + coloured "Add" chip (tinted with the currently selected quick-add category). Tapping the chip or pressing Return adds the typed text as a new `GroceryItem`. Menu on the chip lets you change the category for the next add.
3. **Category filter chips** — horizontal scroll with "All" + one chip per non-empty category, each showing the remaining count.
4. **Category sections** — each tinted `0.12` fill + `0.30` stroke (slightly lighter than the canonical recipe), with the flat-icon recipe for the category header instead of `IconBadge.solid`. Inner rows: white `GroceryItemRow`s.
5. **Clear checked items** button at the bottom when there are completed items.

Sheets:
- [`AddGrocerySheet`](Sources/Features/Grocery/AddGrocerySheet.swift) — full-form add (brand, quantity, photo URL, etc.).
- [`GroceryHistorySheet`](Sources/Features/Grocery/GroceryHistorySheet.swift) — bucketed list of `.groceryChecked` events showing who bought what + when.

### Profile tab — [`ProfileView`](Sources/Features/Profile/ProfileView.swift)

White-surface + hairline-divider tiles (chore-card recipe everywhere — no tinted `CozyCard`s):

1. **Profile card** — `AvatarView` (96pt) with a small pencil button in the top-right opening [`EditProfileSheet`](Sources/Features/Profile/EditProfileSheet.swift). Below: display name, `displayTitle` chip (outlined), optional bio, `XPBar`.
2. **Stats card** — three side-by-side `statTile`s using flat-icon recipe: weekly streak / house harmony / trophies count. `maxHeight: .infinity` for equal heights.
3. **Household card** — house name + member list with level chip per row. (The "Invite a roomie" button moved to the Home page.)
4. **Actions card** — Trophy room + Sign out via `PrimaryButton`.

`EditProfileSheet` lets the user change display name, bio, accent colour (7-swatch grid), and the **displayed title** — the picker is restricted to **unlocked trophy titles** ("Default" falls back to the level-derived title). No free-text title input. Pronouns and avatar-monogram editing were intentionally removed.

### Notes / Trophies

Notes uses a 2-column sticky-note grid. Trophies (Achievements) still uses the original list-card pattern.

---

## Models

All in [`Sources/Models/`](Sources/Models/). Icon fields hold SF Symbol names (never emoji).

### [`Chore`](Sources/Models/Chore.swift)

- `rotationOrder: [UUID]` — explicit rotation sequence (empty = household default).
- `iconTint: Color` → `ChoreIcon.tint(for:)` (single source of truth).
- `xpReward: Int` — stored, but auto-derived from `difficulty` in `AddChoreSheet`.
- `difficulty: ChoreDifficulty = .normal` — drives the XP picker. See below.
- `lastPenaltyAt: Date?` — date the overdue-penalty deduction was last applied. Cleared on completion.
- `isOverdue: Bool` — `status != .done && dueDate < startOfDay`.
- **No recurrence projection on the model anymore.** The chore list shows only literal due-date matches; recurring chores respawn on completion (handled in `ChoreBoardViewModel`).

`ChoreDifficulty` (Quick / Normal / Hefty / Big) drives XP automatically:
| Difficulty | Blurb | XP | Tint |
|---|---|---|---|
| Quick | A few minutes | 5 | mint |
| Normal | Half an hour | 10 | azure |
| Hefty | About an hour | 20 | marigold |
| Big | Multi-hour project | 35 | rose |

Each tier has `icon` (bolt/clock/timer/hammer), `xp`, `tint`, and a `blurb`.

`ChoreIcon` exports:
- `tint(for: symbol)` — icon → brand colour mapping.
- `presets(for: symbol)` — long preset chip lists per icon (9 cleaning options, 8 cooking, 9 repair, etc.).
- `defaultDifficulty(for: symbol)` — baseline difficulty per icon (laundry → hefty, trash → quick, dishes → normal, etc.).
- `presetDifficulty(for: title)` — specific preset titles override the icon default (e.g. "Replace bulb" → quick even on the Repair icon).

`AddChoreSheet` wires `.onChange(of: icon)` and `.onChange(of: title)` to call `applyDifficulty(_:)`, which animates both the difficulty selection and the XP slider to the new value. The slider remains visible (5–50, step 1) so users can fine-tune; manual adjustments hold until the next icon/preset change.

### [`Household`](Sources/Models/Household.swift)

- `level: Int = max(1, houseXP / 250 + 1)`.
- `levelTitle` → `tier.title`.
- `tier: LevelService.HouseTier` (computed from level).
- `levelProgress: Double` for the hero XP bar.
- `rules: [String]`.

### [`RoomieUser`](Sources/Models/User.swift)

- `avatarInitials: String` — falls back to derived initials if empty.
- `customTitle: String?` — chosen from unlocked trophies; `displayTitle` returns this or `levelTitle`.
- `bio: String?` — short blurb shown on the profile card.

### [`ActivityKind`](Sources/Models/ActivityEvent.swift)

Existing: `choreCompleted, choreAdded, choreAssigned, groceryAdded, groceryChecked, noteAdded, achievementUnlocked, streakSaved, levelUp`.

**New** bookkeeping kinds: `levelDown`, `overduePenalty`, `choreReverted`.

`LevelService.harmonyDelta(for:)` returns 0 for the new kinds — the calling site updates harmony separately.

---

## Gamification / XP economy

`LevelService.HouseTier` — **10 tiers, one per level** (was 6 / one per 2 levels):

| Lv | Tier | Tint |
|---|---|---|
| 1 | Fresh Nest | azure |
| 2 | Cozy Den | coral |
| 3 | Warm Cottage | marigold |
| 4 | Garden Lodge | grass |
| 5 | Sunny Loft | mint |
| 6 | Family Townhouse | periwinkle |
| 7 | Storybook Block | azure |
| 8 | Grand Manor | rose |
| 9 | Mythic Estate | coral |
| 10 | Legendary Household | marigold |

Each tier has `title`, `blurb`, `tint`, `unlocksAtLevel`. The legacy `icon: String` SF-Symbol property still exists but the home page + level sheet use `HouseTierImage` instead.

### Overdue XP penalty

`LevelService.dailyOverduePenalty(xpReward:dayOverdue:)` — `xpReward * dayOverdue * 0.10`, capped at the chore's XP and floored at 1. So a 10 XP chore loses 1 / 2 / 3 / … / 10 XP on days 1 / 2 / 3 / … / 10 overdue.

`LevelService.accumulatedOverduePenalty(...)` sums missed days (between `lastPenalizedDay + 1` and `totalDaysOverdue`).

`AppState.processOverduePenalties()` walks all chores, deducts the accumulated penalty, persists `lastPenaltyAt = today` on each affected chore, logs one `.overduePenalty` event per chore (attributed to the assignee), and calls `recordLevelChange` once at the end. Triggered from:
- `AppState.initialLoad()` (cold start)
- `DashboardViewModel.load()` and `ChoreBoardViewModel.load()` (returning to a tab / pull-to-refresh)
- `ChoreBoardViewModel.add(_:)` and `update(_:)` (newly-created overdue chores)

### Revert refund

`ChoreBoardViewModel.advance(_:to:)` detects **Done → not-Done** transitions: clears `completedAt`, decrements `streak`, then calls `AppState.refundChoreXP(chore)` which subtracts `xpReward` from house XP, rolls harmony back by `harmonyDelta(.choreCompleted)`, logs a `.choreReverted` event, and runs `recordLevelChange`.

### Level change detection

`AppState.recordLevelChange(from oldLevel:actorId:)` compares `oldLevel` against `household.level` after any XP mutation; if it crossed a 250-XP boundary it logs a `.levelUp` or `.levelDown` event. Called from `logEvent`, `refundChoreXP`, and `processOverduePenalties`.

`AppState.persistActivity(...)` — utility for one-off bookkeeping events that should appear in `recentActivity` without touching XP.

---

## Service layer

[`AppState`](Sources/App/AppState.swift) holds the dependency container.

Notable methods (besides initialLoad / logEvent / celebrate):
- `updateProfile(_:)` — persists a `RoomieUser` edit and refreshes `currentUser` + `members`.
- `updateHousehold(_:)` — persists household name / rules / member roster and prunes the local `members` array for anyone removed.
- `refundChoreXP(_:)` — see above.
- `processOverduePenalties()` — see above.
- `recordLevelChange(from:actorId:)` + `persistActivity(...)` — bookkeeping helpers.

[`HouseholdRepository`](Sources/Services/Repositories.swift) gained `updateUser(_:)` and `updateHousehold(_:)`. Both implementations updated.

`SupabaseManager` auto-detects `Sources/Resources/SupabaseConfig.plist`; without it falls back to `LocalSeedRepositories` seeded from [`PreviewData`](Sources/Resources/PreviewData.swift). All repositories are `@MainActor`. Views never reach `Supabase` directly.

---

## Bottom nav — [`CozyTabBar`](Sources/Components/CozyTabBar.swift)

Glass `.ultraThinMaterial` pill with **4 plain side tabs** (Chores / Grocery / Notes / You) and an **elevated centre house hub** — `.ultraThinMaterial` over a `coral.opacity(0.62)→azure.opacity(0.62)` tinted gradient, 54pt diameter, offset `-14pt`. Tapping the hub selects `.dashboard`.

`FloatingButtonClearance.bottom = 90pt` (was 140) — the floating Add button on Chores / Grocery / Notes sits just above the hub.

**Tab switch animation**: `.transition(.identity)` + `.animation(nil, value: router.selected)` — tabs swap instantly with no cross-fade or slide (cross-fades felt laggy on complex pages; slides felt overdone).

---

## Design language

**Palette** ([Theme.swift](Sources/Theme/Theme.swift)) — Flat UI Colors:

| Token | Hex | Flat UI name |
|------|-----|------|
| `coral` | `#FC6E51` | Bittersweet |
| `mint` | `#48CFAD` | Mint |
| `marigold` | `#FFCE54` | Sunflower |
| `periwinkle` | `#4FC1E9` | Aqua |
| `azure` | `#5D9CEC` | Blue Jeans |
| `rose` | `#ED5565` | Grapefruit |
| `grass` | `#A0D468` | Grass |

`divider` = ink @ `0.14`, `hairline` = ink @ `0.18` (bumped from 0.07 / 0.10 so every tile has a defined edge).

**Gradients**:
- `Theme.Gradients.harmony` — warm sunrise sweep `rose → coral → marigold` (no blue stops anymore).
- `Theme.Gradients.accent` — pastel **peach → sky** (`#FFC8B0 → #C4DAF2`), hand-picked light hues. Used by the chore-calendar selected day fill, today outline, and dots. Sits comfortably on the pearl background instead of looking dark-mode-bright.
- `Theme.Gradients.xpBar` — existing tri-stop coral → marigold → mint.
- `Theme.Gradients.pearl` — the background gradient.

**Background**: [`PearlBackground`](Sources/Components/PearlBackground.swift) is now just the diagonal pearl gradient — the three coral/periwinkle/marigold blurred orbs were removed for a quieter surface.

**Canonical card recipe** (grocery `categorySection` is still the reference):

| Layer | Treatment |
|------|-----------|
| Outer tinted container — [`CozyCard`](Sources/Components/CozyCard.swift) / [`ListCard`](Sources/Components/ListItemRow.swift) (when a `tint` is passed) | Tint fill `0.18`, 1pt tint stroke `0.35`. Flat. |
| Outer untinted container — `ListCard` with nil tint | White surface fill `0.6`, hairline stroke (used on the Home page). |
| Inner rows — `ListItemRow` | White mini-card with `divider` stroke. Leading `IconBadge(.solid)`. |
| Spacing between rows | `VStack(spacing: 10)` inside `ListCard`. |

**Flat icon recipe** (chore card, today section, recent updates, grocery category header, profile stat tile): 38pt rounded square, `tint.opacity(0.12)` fill, 16pt semibold SF Symbol in tint colour. **Replaces** `IconBadge(.solid)` on the chore-board / home / profile pages but those pages still get the `.solid` glass treatment where it's used.

**Icons**: SF Symbols only. No emoji.

**Avatars**: monogram initials in colored circles via [`AvatarView`](Sources/Components/AvatarView.swift) (the avatar-pack image picker was added then removed).

---

## Components

| Component | Notes |
|---|---|
| [`HouseTierImage`](Sources/Components/HouseTierImage.swift) | Procedural cartoon house, level 1–10. Soft cream walls on stone foundations, shingled roof in tier accent, glowing yellow windows, smoke puffs, garden ground. Tiers progress: tiny cabin → small house → cottage → garden lodge → tall cottage w/ attic dormer → two-story → balcony → three-story manor → triple-peak estate → castle w/ spires + flags + sparkles. ~400 lines of inline SwiftUI primitives. |
| [`ChoreCard`](Sources/Components/ChoreCard.swift) | White surface, divider stroke, flat icon recipe (no `IconBadge`). No checkmark complete button anymore — status dropdown is the only status-change UI. Tapping the status pill opens a custom popover (white surface, themed rows) instead of the system `Menu`. `Move to Done` triggers a per-card completing animation (dim + scale + green→marigold checkmark overlay) before firing `onMove(.done)`. Uses `ChoreCardPressStyle: ButtonStyle` for the 0.98 press scale (replaced `.pressable` which broke ScrollView scrolling). `LatePill` shown when `chore.isOverdue`. `XPBadge` is now a **white capsule with a marigold outline + dark text** (no sparkle icon). |
| [`HarmonyMeter`](Sources/Components/HarmonyMeter.swift) | Circular ring. **No longer used on the home page** but kept for future reuse. |
| [`CozyHomeBackdrop`](Sources/Components/CozyHomeBackdrop.swift) | Hills + stars + sparkles + warm corner glow. Still decorates the hero. |
| [`PearlBackground`](Sources/Components/PearlBackground.swift) | Now just the pearl gradient. `FloatingButtonClearance.bottom = 90`. |
| [`ModernInputField`](Sources/Components/ModernInputField.swift) | Used in `AddChoreSheet` / `AddGrocerySheet` / `EditProfileSheet` / `EditHouseholdSheet`. |
| [`StreakChip`](Sources/Components/QuickActionTile.swift) | Outlined-only (no fill); ink stroke matching tile borders. |
| `XPBadge` | In `ChoreCard.swift`. White fill, marigold outline, dark text. |
| `LatePill` | In `ChoreCard.swift`. Rose pill with warning-triangle icon. |

---

## Recent feature additions

In addition to the original chore/rotation/preset features:

1. **Procedural illustrated `HouseTierImage`** — 10 cartoon house designs, one per level. Used in the home hero watermark and the `HouseLevelsSheet`.
2. **House levels sheet** (`HouseLevelsSheet`) — tap the `Lv N` pill on the hero to see the full ladder.
3. **House history sheet** (`HouseHistorySheet`) — tap the clock icon in the greeting header. Shows every XP gain/loss and level change.
4. **Grocery history sheet** (`GroceryHistorySheet`) — tap the clock icon in the grocery header. Shows who bought what + when, sourced from `.groceryChecked` events.
5. **Edit household sheet** — tap the pencil in the greeting header. Edit name, rules (add/edit/reorder/delete), members (remove with confirmation), shows invite code.
6. **Edit profile sheet** — pencil button on the profile card. Name + bio + accent colour. Title picker restricted to unlocked trophies.
7. **Chore difficulty system** — `ChoreDifficulty` enum drives XP automatically. `ChoreIcon.defaultDifficulty(for:)` and `ChoreIcon.presetDifficulty(for:)` make picking an icon or preset chip snap the difficulty + XP slider.
8. **Overdue XP penalty system** — daily escalating loss, capped at chore XP, `lastPenaltyAt` tracking, runs on every load + chore add/update.
9. **Revert refund** — Done → not-Done deducts the XP and harmony that completion awarded.
10. **Level-up / Level-down events** auto-logged on every XP mutation.
11. **Sleek segmented status control** on the chore board (matched-geometry sliding indicator + swipe to cycle).
12. **`ChoreFilterSheet`** — replaces the old `AssigneeFilterRow`. Filter button left of the status control.
13. **No recurrence projection** — chore list shows only literal due-date matches. Past-due unfinished chores surface on Today with a "Late" pill.
14. **Today section on home page** — `vm.todaysChoresForMe`, inline complete with animation.
15. **Grocery smart input** — combined search + quick-add. Category filter chips. Hide-checked toggle. Coral→marigold progress capsule.
16. **Tab switch animation disabled** — `.transition(.identity)` + `.animation(nil, value:)` because cross-fades felt laggy.
17. **Chore-card scrolling fix** — replaced `.pressable` with `ChoreCardPressStyle: ButtonStyle` which doesn't install a competing drag gesture.
18. **Long preset chip lists per icon** — 6–10 preset titles per category, each mapped to a specific difficulty.

---

## Things explicitly rejected — don't propose these

- Pastel pinks / lavenders ("girly")
- Pure-rainbow vibrant pastels ("still girly")
- Duolingo-style chunky 3D buttons with a darker bottom strip ("looks too much like a game")
- Heavy 3D bevel borders + colored halos ("shadow everywhere")
- Pure Liquid Glass tinted cards (user preferred flat grocery style)
- Pure-flat with no depth at all ("too basic")
- Scroll-triggered fade/scale animations on cards
- Cross-fade or slide tab-switch animations ("too laggy", "too aggressive")
- Emoji characters in the UI (use multicolor SF Symbols)
- The cushion-tile icon row in the bottom nav
- Pronouns / monogram-text-edit / avatar-pack picker on the profile (user removed all three after trying them)
- Vines / ivy on the procedural houses (added then removed)
- Forest / Ghibli green replacement for mint (user reverted to original `#48CFAD` teal)
- Coloured orbs in `PearlBackground` (removed for a quieter surface)
- Per-section tinted `ListCard`s on the home page (reverted to untinted)
