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
