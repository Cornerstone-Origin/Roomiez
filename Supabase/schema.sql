-- Roomiez · Supabase schema
-- Run this in the Supabase SQL editor (or `supabase db push`) once.
-- All tables are scoped by household_id and protected by RLS.

create extension if not exists "uuid-ossp";

-- =========================================================================
-- Households
-- =========================================================================
create table if not exists households (
    id            uuid primary key default uuid_generate_v4(),
    name          text not null,
    emoji         text not null default '🏡',
    invite_code   text not null unique,
    house_xp      int  not null default 0,
    harmony       double precision not null default 0.5,
    weekly_streak int  not null default 0,
    member_ids    uuid[] not null default '{}',
    created_at    timestamptz not null default now()
);

-- =========================================================================
-- Users (linked 1:1 with auth.users via shared id)
-- =========================================================================
create table if not exists users (
    id            uuid primary key references auth.users(id) on delete cascade,
    display_name  text not null,
    avatar_emoji  text not null default '🐰',
    accent_hex    text not null default 'F4B6C2',
    household_id  uuid references households(id) on delete set null,
    personal_xp   int  not null default 0,
    weekly_streak int  not null default 0,
    joined_at     timestamptz not null default now()
);

-- =========================================================================
-- Chores
-- =========================================================================
create table if not exists chores (
    id           uuid primary key default uuid_generate_v4(),
    household_id uuid not null references households(id) on delete cascade,
    title        text not null,
    note         text,
    emoji        text not null default '🧺',
    status       text not null default 'todo',
    priority     text not null default 'normal',
    recurrence   text not null default 'once',
    assignee_id  uuid references users(id) on delete set null,
    xp_reward    int  not null default 10,
    due_date     timestamptz,
    completed_at timestamptz,
    streak       int  not null default 0,
    created_at   timestamptz not null default now()
);

create index if not exists chores_household_idx on chores (household_id);
create index if not exists chores_status_idx    on chores (household_id, status);

-- =========================================================================
-- Grocery items
-- =========================================================================
create table if not exists grocery_items (
    id           uuid primary key default uuid_generate_v4(),
    household_id uuid not null references households(id) on delete cascade,
    title        text not null,
    brand        text,
    quantity     text,
    category     text not null default 'other',
    is_checked   boolean not null default false,
    added_by_id  uuid references users(id) on delete set null,
    photo_url    text,
    added_at     timestamptz not null default now()
);

create index if not exists grocery_household_idx on grocery_items (household_id);

-- =========================================================================
-- Notes
-- =========================================================================
create table if not exists notes (
    id           uuid primary key default uuid_generate_v4(),
    household_id uuid not null references households(id) on delete cascade,
    title        text not null default '',
    body         text not null default '',
    color        text not null default 'pink',
    todos        jsonb not null default '[]',
    rotation     double precision not null default 0,
    order_index  int  not null default 0,
    author_id    uuid references users(id) on delete set null,
    pinned       boolean not null default false,
    created_at   timestamptz not null default now(),
    updated_at   timestamptz not null default now()
);

create index if not exists notes_household_idx on notes (household_id);

-- =========================================================================
-- Achievements (one row per household per unlocked achievement)
-- =========================================================================
create table if not exists achievements (
    id           uuid primary key default uuid_generate_v4(),
    household_id uuid not null references households(id) on delete cascade,
    key          text not null,
    title        text not null,
    blurb        text not null,
    emoji        text not null,
    tint_hex     text not null,
    threshold    int  not null default 0,
    unlocked_at  timestamptz,
    unique (household_id, key)
);

-- =========================================================================
-- Activity events (timeline)
-- =========================================================================
create table if not exists activity_events (
    id           uuid primary key default uuid_generate_v4(),
    household_id uuid not null references households(id) on delete cascade,
    actor_id     uuid references users(id) on delete set null,
    kind         text not null,
    subject      text not null,
    emoji        text not null,
    xp_delta     int  not null default 0,
    created_at   timestamptz not null default now()
);

create index if not exists activity_household_idx
    on activity_events (household_id, created_at desc);

-- =========================================================================
-- Helper RPC used by AppState.logEvent for atomic harmony bumps.
-- =========================================================================
create or replace function bump_household_harmony(
    household_id uuid,
    harmony double precision,
    house_xp_delta int
) returns void
language sql security definer as $$
    update households
       set harmony = bump_household_harmony.harmony,
           house_xp = house_xp + bump_household_harmony.house_xp_delta
     where id = bump_household_harmony.household_id;
$$;

-- =========================================================================
-- Realtime — make all relevant tables broadcast changes.
-- =========================================================================
alter publication supabase_realtime add table chores;
alter publication supabase_realtime add table grocery_items;
alter publication supabase_realtime add table notes;
alter publication supabase_realtime add table activity_events;
alter publication supabase_realtime add table achievements;
alter publication supabase_realtime add table households;

-- =========================================================================
-- Row Level Security — household-scoped access only.
-- =========================================================================
alter table households      enable row level security;
alter table users           enable row level security;
alter table chores          enable row level security;
alter table grocery_items   enable row level security;
alter table notes           enable row level security;
alter table achievements    enable row level security;
alter table activity_events enable row level security;

-- A user is a member of a household iff their household_id matches.
create policy "members read household" on households
    for select using (
        id = (select household_id from users where users.id = auth.uid())
    );

create policy "members update household" on households
    for update using (
        id = (select household_id from users where users.id = auth.uid())
    );

create policy "anyone reads users in same household" on users
    for select using (
        household_id = (select household_id from users me where me.id = auth.uid())
        or id = auth.uid()
    );

create policy "users self-write" on users
    for all using (id = auth.uid()) with check (id = auth.uid());

-- Generic "your household only" policy for the rest.
create policy "household_rw chores" on chores
    for all using (
        household_id = (select household_id from users where users.id = auth.uid())
    ) with check (
        household_id = (select household_id from users where users.id = auth.uid())
    );

create policy "household_rw grocery" on grocery_items
    for all using (
        household_id = (select household_id from users where users.id = auth.uid())
    ) with check (
        household_id = (select household_id from users where users.id = auth.uid())
    );

create policy "household_rw notes" on notes
    for all using (
        household_id = (select household_id from users where users.id = auth.uid())
    ) with check (
        household_id = (select household_id from users where users.id = auth.uid())
    );

create policy "household_rw activity" on activity_events
    for all using (
        household_id = (select household_id from users where users.id = auth.uid())
    ) with check (
        household_id = (select household_id from users where users.id = auth.uid())
    );

create policy "household_rw achievements" on achievements
    for all using (
        household_id = (select household_id from users where users.id = auth.uid())
    ) with check (
        household_id = (select household_id from users where users.id = auth.uid())
    );

-- =========================================================================
-- Chore groups — rotating "template" that auto-assigns a Chore each cycle.
-- The group owns recurrence + rotation; each cycle materializes a row in
-- the `chores` table tagged with `group_id` so the existing chore board,
-- XP economy, overdue penalties, streaks, and activity feed all just work.
-- =========================================================================
create table if not exists chore_groups (
    id               uuid primary key default uuid_generate_v4(),
    household_id     uuid not null references households(id) on delete cascade,
    title            text not null,
    note             text,
    icon             text not null default 'sparkles',
    -- weekly | biweekly | monthly
    frequency        text not null default 'weekly',
    -- classic | shuffle | custom
    rotation_style   text not null default 'classic',
    xp_reward        int  not null default 10,
    difficulty       text not null default 'normal',
    priority         text not null default 'normal',
    -- Round-robin pointer for classic/custom. Ignored by shuffle.
    rotation_index   int  not null default 0,
    -- Last cycle anchor we generated an assignment for. NULL = never.
    last_assigned_at timestamptz,
    -- Anchor (start) of the next cycle the scheduler should serve.
    next_due_at      timestamptz not null,
    is_paused        boolean not null default false,
    paused_until     timestamptz,
    created_by_id    uuid references users(id) on delete set null,
    created_at       timestamptz not null default now()
);

create index if not exists chore_groups_household_idx on chore_groups (household_id);
create index if not exists chore_groups_due_idx       on chore_groups (next_due_at)
    where is_paused = false;

-- =========================================================================
-- Group membership — who rotates, and (for `custom`) in what order.
-- `bag_picked` is the "shuffle bag" flag: everyone goes once before anyone
-- repeats. Reset to false for all members when the bag empties.
-- =========================================================================
create table if not exists chore_group_members (
    group_id    uuid not null references chore_groups(id) on delete cascade,
    user_id     uuid not null references users(id) on delete cascade,
    order_index int  not null default 0,
    bag_picked  boolean not null default false,
    added_at    timestamptz not null default now(),
    primary key (group_id, user_id)
);

create index if not exists group_members_group_idx
    on chore_group_members (group_id, order_index);

-- =========================================================================
-- Chores — back-pointer to the originating group + cycle bookkeeping.
-- Additive only; existing single chores leave these NULL.
-- =========================================================================
alter table chores
    add column if not exists group_id      uuid references chore_groups(id) on delete set null,
    add column if not exists cycle_anchor  timestamptz,
    add column if not exists auto_assigned boolean not null default false;

create index if not exists chores_group_idx on chores (group_id, cycle_anchor);

-- Idempotency guard for the rotation scheduler: prevents the app-launch
-- sweep and any backstop (pg_cron, Edge Function) from double-inserting an
-- assignment for the same group/cycle.
create unique index if not exists chores_group_cycle_uq
    on chores (group_id, cycle_anchor)
    where group_id is not null;

-- =========================================================================
-- Realtime
-- =========================================================================
alter publication supabase_realtime add table chore_groups;
alter publication supabase_realtime add table chore_group_members;

-- =========================================================================
-- RLS — same household-scoped pattern as the existing tables.
-- =========================================================================
alter table chore_groups        enable row level security;
alter table chore_group_members enable row level security;

create policy "household_rw chore_groups" on chore_groups
    for all using (
        household_id = (select household_id from users where users.id = auth.uid())
    ) with check (
        household_id = (select household_id from users where users.id = auth.uid())
    );

create policy "household_rw chore_group_members" on chore_group_members
    for all using (
        group_id in (
            select id from chore_groups
            where household_id = (select household_id from users where users.id = auth.uid())
        )
    ) with check (
        group_id in (
            select id from chore_groups
            where household_id = (select household_id from users where users.id = auth.uid())
        )
    );
