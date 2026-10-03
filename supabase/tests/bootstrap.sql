-- Disposable CI database only. NEVER run this bootstrap on Supabase.
create role anon nologin;
create role authenticated nologin;
create role service_role nologin bypassrls;
create schema auth;
create table auth.users(id uuid primary key);
create function auth.uid() returns uuid language sql stable as $$
 select nullif(current_setting('request.jwt.claim.sub', true), '')::uuid;
$$;
grant usage on schema auth, public to anon, authenticated, service_role;
grant execute on function auth.uid() to anon, authenticated, service_role;

-- Existing website tables intentionally occupy generic names.
create table public.profiles (website_marker text);
create table public.posts (website_marker text);
create table public.listings (website_marker text);
insert into public.posts values ('website-unchanged');

-- Disposable storage API schema fixture; production Supabase already owns these.
create schema storage;
create table storage.buckets(id text primary key,name text,public boolean,file_size_limit bigint,allowed_mime_types text[]);
create table storage.objects(id uuid primary key default gen_random_uuid(),bucket_id text,name text);
alter table storage.objects enable row level security;
grant usage on schema storage to anon,authenticated,service_role;
grant all on storage.objects to anon,authenticated,service_role;
create policy fixture_website_storage on storage.objects for all to authenticated using(true) with check(true);
