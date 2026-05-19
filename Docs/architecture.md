# Architecture notes

## Layers

```
View  →  ViewModel  →  AppState  →  Repository protocol
                                       │
                            ┌──────────┴──────────┐
                            ▼                     ▼
                  LocalSeedRepositories   SupabaseRepositories
```

Every screen has a `*ViewModel` (`@MainActor`, `ObservableObject`) that owns
its own state and calls into one or more repositories through `AppState`.
ViewModels never touch Supabase directly — that's `Services/` territory.

## Why two repo implementations?

The brief asked for a polished feel "out of the box," but Supabase requires
network credentials. The compromise: a single set of `*Repository` protocols
plus two implementations.

* **LocalSeedRepositories** — actor-backed in-memory store, pre-loaded from
  `PreviewData`. Used in SwiftUI previews and any time `SupabaseConfig.plist`
  is missing. Means the app is *fully interactive* from a clean clone.
* **SupabaseRepositories** — real `client.from(...)` calls. Selected
  automatically when `SupabaseConfig.plist` has valid values.

Both conform to the same protocol set, so `AppState` picks one at init time
and the rest of the app is none the wiser.

## XP & Harmony pipeline

Every meaningful user action funnels through one call:

```swift
await appState.logEvent(kind: .choreCompleted,
                        subject: chore.title,
                        emoji: chore.emoji,
                        xp: chore.xpReward)
```

Inside `AppState.logEvent`:
1. Inserts an `ActivityEvent` (timeline shows up everywhere immediately).
2. Bumps the current user's `personalXP`.
3. Calls `LevelService.harmonyDelta(for:)` to compute the house-wide nudge.
4. Calls `householdRepo.updateHarmony(...)`. With Supabase this runs an
   atomic `bump_household_harmony` RPC; locally it just mutates the actor.

This means XP/harmony rules live in **one** file (`LevelService`) — tune
the economy without grepping the codebase.

## Realtime

`RealtimeService.start(for:)` subscribes to six household-scoped tables. The
callback re-fetches `AppState.recentActivity` + the household record, so the
dashboard always reflects what roommates are doing right now.

Individual feature `*ViewModel.load()` methods are also called from view
`.task` modifiers — that re-pulls full lists when a screen appears.

## Custom tab bar

Default `TabView` couldn't match the cozy aesthetic (no rounded pastel pill
indicator, no springy `matchedGeometryEffect`). `CozyTabBar` + a switch in
`MainTabScaffold` get us the look the brief asked for without much code.

## Celebrations

`AppState.celebration` is a small struct that, when non-nil, causes
`RootView` to overlay `CelebrationOverlay` (gold star + confetti) on top of
whatever's underneath. Auto-dismisses after 2.4s. Used for chore completion,
streak bonuses, and achievement unlocks.

## What's intentionally out of scope (for now)

* **Payments** — explicitly punted per spec.
* **Push notifications** — easy to add later via Supabase Functions + APNs.
* **Photo upload to Supabase Storage** — model field exists (`photoURL`),
  UI hook isn't wired so we don't ship dead UI.
* **Native widgets / live activities** — solid follow-up given the
  fridge-magnet aesthetic, but out of v1.
