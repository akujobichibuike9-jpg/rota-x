-- rota-x database setup
-- Paste this whole file into Supabase → SQL Editor → New query, then press Run. Run it once.

-- 1. Venues: one per head doorman account
create table if not exists public.venues (
  id            uuid primary key default gen_random_uuid(),
  owner_id      uuid not null default auth.uid() references auth.users(id) on delete cascade,
  name          text not null,
  head_doorman  text not null default '',
  area_manager  text not null default '',
  created_at    timestamptz not null default now(),
  updated_at    timestamptz not null default now()
);
create unique index if not exists venues_one_per_owner on public.venues(owner_id);

-- 2. Door supervisors at each venue
create table if not exists public.staff (
  venue_id    uuid not null references public.venues(id) on delete cascade,
  id          text not null,
  name        text not null,
  phone       text not null default '',
  sia_number  text not null default '',
  sia_expiry  date,
  archived    boolean not null default false,
  updated_at  timestamptz not null default now(),
  primary key (venue_id, id)
);

-- 3. Shifts: one row per door supervisor per night
create table if not exists public.shifts (
  venue_id    uuid not null references public.venues(id) on delete cascade,
  id          text not null,
  shift_date  date not null,
  staff_id    text not null,
  start_time  time not null,
  end_time    time not null,
  deleted     boolean not null default false,
  updated_at  timestamptz not null default now(),
  primary key (venue_id, id)
);
create index if not exists shifts_by_venue_date on public.shifts(venue_id, shift_date);

-- 4. Security: each head doorman can only see and change their own venue
alter table public.venues enable row level security;
alter table public.staff  enable row level security;
alter table public.shifts enable row level security;

drop policy if exists "own venue" on public.venues;
create policy "own venue" on public.venues
  for all to authenticated
  using (owner_id = (select auth.uid()))
  with check (owner_id = (select auth.uid()));

drop policy if exists "own venue staff" on public.staff;
create policy "own venue staff" on public.staff
  for all to authenticated
  using (exists (select 1 from public.venues v where v.id = staff.venue_id and v.owner_id = (select auth.uid())))
  with check (exists (select 1 from public.venues v where v.id = staff.venue_id and v.owner_id = (select auth.uid())));

drop policy if exists "own venue shifts" on public.shifts;
create policy "own venue shifts" on public.shifts
  for all to authenticated
  using (exists (select 1 from public.venues v where v.id = shifts.venue_id and v.owner_id = (select auth.uid())))
  with check (exists (select 1 from public.venues v where v.id = shifts.venue_id and v.owner_id = (select auth.uid())));
