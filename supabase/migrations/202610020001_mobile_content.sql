-- Independent mobile tables for a project shared with the website.
-- Does not modify website tables, auth settings, or auth triggers.
begin;

create table public.cn_profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  display_name text not null check (char_length(btrim(display_name)) between 1 and 80),
  created_at timestamptz not null default now()
);

create table public.cn_posts (
  id uuid primary key default gen_random_uuid(),
  owner_id uuid not null references auth.users(id) on delete cascade,
  caption text not null check (char_length(btrim(caption)) between 1 and 500),
  status text not null default 'draft' check (status in ('draft','published','archived')),
  created_at timestamptz not null default now()
);

create table public.cn_listings (
  id uuid primary key default gen_random_uuid(),
  owner_id uuid not null references auth.users(id) on delete cascade,
  kind text not null check (kind in ('sale','rental')),
  title text not null check (char_length(btrim(title)) between 1 and 80),
  city text not null check (char_length(btrim(city)) between 1 and 80),
  currency text not null check (currency ~ '^[A-Z]{3}$'),
  price_minor bigint not null check (price_minor > 0),
  status text not null default 'draft' check (status in ('draft','published','archived')),
  created_at timestamptz not null default now()
);

create table public.cn_saved_posts (
  user_id uuid not null references auth.users(id) on delete cascade,
  post_id uuid not null references public.cn_posts(id) on delete cascade,
  created_at timestamptz not null default now(),
  primary key (user_id, post_id)
);
create table public.cn_saved_listings (
  user_id uuid not null references auth.users(id) on delete cascade,
  listing_id uuid not null references public.cn_listings(id) on delete cascade,
  created_at timestamptz not null default now(),
  primary key (user_id, listing_id)
);

create index cn_posts_feed_idx on public.cn_posts(created_at desc, id desc) where status = 'published';
create index cn_posts_owner_idx on public.cn_posts(owner_id);
create index cn_listings_feed_idx on public.cn_listings(kind, created_at desc, id desc) where status = 'published';
create index cn_listings_owner_idx on public.cn_listings(owner_id);
create index cn_saved_posts_target_idx on public.cn_saved_posts(post_id);
create index cn_saved_listings_target_idx on public.cn_saved_listings(listing_id);

alter table public.cn_profiles enable row level security;
alter table public.cn_posts enable row level security;
alter table public.cn_listings enable row level security;
alter table public.cn_saved_posts enable row level security;
alter table public.cn_saved_listings enable row level security;

-- User identity is supplied by the verified auth service, never request JSON.
create policy cn_profiles_read on public.cn_profiles for select to authenticated using (true);
create policy cn_profiles_create on public.cn_profiles for insert to authenticated
  with check (id = (select auth.uid()));
create policy cn_profiles_update on public.cn_profiles for update to authenticated
  using (id = (select auth.uid())) with check (id = (select auth.uid()));

create policy cn_posts_read on public.cn_posts for select to anon, authenticated
  using (status = 'published' or owner_id = (select auth.uid()));
create policy cn_posts_create_draft on public.cn_posts for insert to authenticated
  with check (owner_id = (select auth.uid()) and status = 'draft');
create policy cn_posts_update_own on public.cn_posts for update to authenticated
  using (owner_id = (select auth.uid()))
  with check (owner_id = (select auth.uid()) and status in ('draft','archived'));
create policy cn_posts_delete_own on public.cn_posts for delete to authenticated
  using (owner_id = (select auth.uid()));

create policy cn_listings_read on public.cn_listings for select to anon, authenticated
  using (status = 'published' or owner_id = (select auth.uid()));
create policy cn_listings_create_draft on public.cn_listings for insert to authenticated
  with check (owner_id = (select auth.uid()) and status = 'draft');
create policy cn_listings_update_own on public.cn_listings for update to authenticated
  using (owner_id = (select auth.uid()))
  with check (owner_id = (select auth.uid()) and status in ('draft','archived'));
create policy cn_listings_delete_own on public.cn_listings for delete to authenticated
  using (owner_id = (select auth.uid()));

create policy cn_saved_posts_read on public.cn_saved_posts for select to authenticated
  using (user_id = (select auth.uid()));
create policy cn_saved_posts_create on public.cn_saved_posts for insert to authenticated
  with check (user_id = (select auth.uid()) and exists (
    select 1 from public.cn_posts where id = post_id and status = 'published'));
create policy cn_saved_posts_delete on public.cn_saved_posts for delete to authenticated
  using (user_id = (select auth.uid()));
create policy cn_saved_listings_read on public.cn_saved_listings for select to authenticated
  using (user_id = (select auth.uid()));
create policy cn_saved_listings_create on public.cn_saved_listings for insert to authenticated
  with check (user_id = (select auth.uid()) and exists (
    select 1 from public.cn_listings where id = listing_id and status = 'published'));
create policy cn_saved_listings_delete on public.cn_saved_listings for delete to authenticated
  using (user_id = (select auth.uid()));

revoke all on public.cn_profiles, public.cn_posts, public.cn_listings,
  public.cn_saved_posts, public.cn_saved_listings from anon, authenticated;
grant select on public.cn_posts, public.cn_listings to anon;
grant select, insert, update on public.cn_profiles to authenticated;
grant select, insert, update, delete on public.cn_posts, public.cn_listings to authenticated;
grant select, insert, delete on public.cn_saved_posts, public.cn_saved_listings to authenticated;
-- Never expose service_role credentials in Flutter. Publishing remains a
-- privileged server operation after image validation and moderation.
grant all on public.cn_profiles, public.cn_posts, public.cn_listings,
  public.cn_saved_posts, public.cn_saved_listings to service_role;
commit;
