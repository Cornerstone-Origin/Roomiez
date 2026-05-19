-- Optional seed data — drop into the SQL editor *after* the schema runs
-- and *after* you've created at least one auth user.
-- Replace the user IDs below with real ones from `auth.users`.

insert into households (id, name, emoji, invite_code, house_xp, harmony, weekly_streak)
values
  ('00000000-0000-0000-0000-0000000000aa',
   'The Sunny Loft', '🏡', 'SUNNY-7421', 1280, 0.82, 5)
on conflict (id) do nothing;

-- Add a few sample chores
insert into chores (household_id, title, emoji, status, priority, recurrence, xp_reward, streak)
values
  ('00000000-0000-0000-0000-0000000000aa', 'Take out trash', '🗑️',
   'todo', 'high', 'weekly', 15, 6),
  ('00000000-0000-0000-0000-0000000000aa', 'Water plants', '🌱',
   'todo', 'normal', 'daily', 10, 12),
  ('00000000-0000-0000-0000-0000000000aa', 'Laundry', '🧺',
   'inProgress', 'normal', 'weekly', 12, 3),
  ('00000000-0000-0000-0000-0000000000aa', 'Clean kitchen', '🍳',
   'inProgress', 'high', 'weekly', 18, 4)
on conflict do nothing;

-- A few grocery items
insert into grocery_items (household_id, title, category, brand, quantity, is_checked)
values
  ('00000000-0000-0000-0000-0000000000aa', 'Strawberries', 'produce', null, '1 box', false),
  ('00000000-0000-0000-0000-0000000000aa', 'Oat milk',     'dairy',   'Oatly', '2',   false),
  ('00000000-0000-0000-0000-0000000000aa', 'Pasta',        'pantry',  'Barilla', '2 boxes', false)
on conflict do nothing;

-- A starter sticky note
insert into notes (household_id, title, body, color, rotation, pinned)
values
  ('00000000-0000-0000-0000-0000000000aa',
   'Wifi password', 'sunny-loft-2026 🌞', 'yellow', 1.6, true)
on conflict do nothing;
