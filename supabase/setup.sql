-- rota-x database schema (already applied to the live project; kept here for reference and new environments)

create table if not exists public.venues (
  id uuid primary key default gen_random_uuid(),
  owner_id uuid not null default auth.uid() references auth.users(id) on delete cascade,
  name text not null, head_doorman text not null default '', area_manager text not null default '',
  created_at timestamptz not null default now(), updated_at timestamptz not null default now()
);
create unique index if not exists venues_one_per_owner on public.venues(owner_id);

create table if not exists public.staff (
  venue_id uuid not null references public.venues(id) on delete cascade, id text not null,
  name text not null, phone text not null default '', sia_number text not null default '', sia_expiry date,
  archived boolean not null default false, updated_at timestamptz not null default now(),
  primary key (venue_id, id)
);
create index if not exists staff_by_venue on public.staff(venue_id);

create table if not exists public.shifts (
  venue_id uuid not null references public.venues(id) on delete cascade, id text not null,
  shift_date date not null, staff_id text not null, start_time time not null, end_time time not null,
  deleted boolean not null default false, updated_at timestamptz not null default now(),
  primary key (venue_id, id)
);
create index if not exists shifts_by_venue_date on public.shifts(venue_id, shift_date);

-- Admins: can read every venue (read-only). Add one with:
--   insert into public.admins(user_id) select id from auth.users where email = 'person@example.com';
create table if not exists public.admins (
  user_id uuid primary key references auth.users(id) on delete cascade,
  note text not null default '', created_at timestamptz not null default now()
);

create schema if not exists private;
revoke all on schema private from public, anon;
grant usage on schema private to authenticated;
create or replace function private.is_admin() returns boolean language sql stable security definer set search_path = '' as $$
  select exists (select 1 from public.admins where user_id = (select auth.uid()));
$$;
revoke execute on function private.is_admin() from public, anon;
grant execute on function private.is_admin() to authenticated;

alter table public.venues enable row level security;
alter table public.staff  enable row level security;
alter table public.shifts enable row level security;
alter table public.admins enable row level security;

grant select, insert, update, delete on public.venues, public.staff, public.shifts to authenticated;
grant select on public.admins to authenticated;
revoke all on public.venues, public.staff, public.shifts, public.admins from anon;

create policy "read own admin row" on public.admins for select to authenticated using (user_id = (select auth.uid()));

create policy "venues read"   on public.venues for select to authenticated using (owner_id = (select auth.uid()) or (select private.is_admin()));
create policy "venues insert" on public.venues for insert to authenticated with check (owner_id = (select auth.uid()));
create policy "venues update" on public.venues for update to authenticated using (owner_id = (select auth.uid())) with check (owner_id = (select auth.uid()));
create policy "venues delete" on public.venues for delete to authenticated using (owner_id = (select auth.uid()));

create policy "staff read"   on public.staff for select to authenticated using ((select private.is_admin()) or exists (select 1 from public.venues v where v.id = staff.venue_id and v.owner_id = (select auth.uid())));
create policy "staff insert" on public.staff for insert to authenticated with check (exists (select 1 from public.venues v where v.id = staff.venue_id and v.owner_id = (select auth.uid())));
create policy "staff update" on public.staff for update to authenticated using (exists (select 1 from public.venues v where v.id = staff.venue_id and v.owner_id = (select auth.uid()))) with check (exists (select 1 from public.venues v where v.id = staff.venue_id and v.owner_id = (select auth.uid())));
create policy "staff delete" on public.staff for delete to authenticated using (exists (select 1 from public.venues v where v.id = staff.venue_id and v.owner_id = (select auth.uid())));

create policy "shifts read"   on public.shifts for select to authenticated using ((select private.is_admin()) or exists (select 1 from public.venues v where v.id = shifts.venue_id and v.owner_id = (select auth.uid())));
create policy "shifts insert" on public.shifts for insert to authenticated with check (exists (select 1 from public.venues v where v.id = shifts.venue_id and v.owner_id = (select auth.uid())));
create policy "shifts update" on public.shifts for update to authenticated using (exists (select 1 from public.venues v where v.id = shifts.venue_id and v.owner_id = (select auth.uid()))) with check (exists (select 1 from public.venues v where v.id = shifts.venue_id and v.owner_id = (select auth.uid())));
create policy "shifts delete" on public.shifts for delete to authenticated using (exists (select 1 from public.venues v where v.id = shifts.venue_id and v.owner_id = (select auth.uid())));
