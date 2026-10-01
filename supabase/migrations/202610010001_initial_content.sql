begin;

create table public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  display_name text not null check (char_length(btrim(display_name)) between 1 and 80),
  created_at timestamptz not null default now()
);

create table public.posts (
  id uuid primary key default gen_random_uuid(),
  owner_id uuid not null references auth.users(id) on delete cascade,
  caption text not null check (char_length(btrim(caption)) between 1 and 500),
  status text not null default 'draft' check (status in ('draft','published','archived')),
  created_at timestamptz not null default now()
);

create table public.listings (
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

create table public.saved_posts (
  user_id uuid not null references auth.users(id) on delete cascade,
  post_id uuid not null references public.posts(id) on delete cascade,
  created_at timestamptz not null default now(),
  primary key (user_id, post_id)
);
create table public.saved_listings (
  user_id uuid not null references auth.users(id) on delete cascade,
  listing_id uuid not null references public.listings(id) on delete cascade,
  created_at timestamptz not null default now(),
  primary key (user_id, listing_id)
);

create index posts_feed_idx on public.posts(created_at desc, id desc) where status = 'published';
create index posts_owner_idx on public.posts(owner_id);
create index listings_feed_idx on public.listings(kind, created_at desc, id desc) where status = 'published';
create index listings_owner_idx on public.listings(owner_id);
create index saved_posts_target_idx on public.saved_posts(post_id);
create index saved_listings_target_idx on public.saved_listings(listing_id);

alter table public.profiles enable row level security;
alter table public.posts enable row level security;
alter table public.listings enable row level security;
alter table public.saved_posts enable row level security;
alter table public.saved_listings enable row level security;

-- User identity is supplied by the verified auth service, never request JSON.
create policy profiles_read on public.profiles for select to authenticated using (true);
create policy profiles_create on public.profiles for insert to authenticated
  with check (id = (select auth.uid()));
create policy profiles_update on public.profiles for update to authenticated
  using (id = (select auth.uid())) with check (id = (select auth.uid()));

create policy posts_read on public.posts for select to anon, authenticated
  using (status = 'published' or owner_id = (select auth.uid()));
create policy posts_create_draft on public.posts for insert to authenticated
  with check (owner_id = (select auth.uid()) and status = 'draft');
create policy posts_update_own on public.posts for update to authenticated
  using (owner_id = (select auth.uid()))
  with check (owner_id = (select auth.uid()) and status in ('draft','archived'));
create policy posts_delete_own on public.posts for delete to authenticated
  using (owner_id = (select auth.uid()));

create policy listings_read on public.listings for select to anon, authenticated
  using (status = 'published' or owner_id = (select auth.uid()));
create policy listings_create_draft on public.listings for insert to authenticated
  with check (owner_id = (select auth.uid()) and status = 'draft');
create policy listings_update_own on public.listings for update to authenticated
  using (owner_id = (select auth.uid()))
  with check (owner_id = (select auth.uid()) and status in ('draft','archived'));
create policy listings_delete_own on public.listings for delete to authenticated
  using (owner_id = (select auth.uid()));

create policy saved_posts_read on public.saved_posts for select to authenticated
  using (user_id = (select auth.uid()));
create policy saved_posts_create on public.saved_posts for insert to authenticated
  with check (user_id = (select auth.uid()) and exists (
    select 1 from public.posts where id = post_id and status = 'published'));
create policy saved_posts_delete on public.saved_posts for delete to authenticated
  using (user_id = (select auth.uid()));
create policy saved_listings_read on public.saved_listings for select to authenticated
  using (user_id = (select auth.uid()));
create policy saved_listings_create on public.saved_listings for insert to authenticated
  with check (user_id = (select auth.uid()) and exists (
    select 1 from public.listings where id = listing_id and status = 'published'));
create policy saved_listings_delete on public.saved_listings for delete to authenticated
  using (user_id = (select auth.uid()));

revoke all on public.profiles, public.posts, public.listings,
  public.saved_posts, public.saved_listings from anon, authenticated;
grant select on public.posts, public.listings to anon;
grant select, insert, update on public.profiles to authenticated;
grant select, insert, update, delete on public.posts, public.listings to authenticated;
grant select, insert, delete on public.saved_posts, public.saved_listings to authenticated;
-- Never expose service_role credentials in Flutter. Publishing remains a
-- privileged server operation after image validation and moderation.
grant all on public.profiles, public.posts, public.listings,
  public.saved_posts, public.saved_listings to service_role;
commit;
