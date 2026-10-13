-- Hosted Supabase only: requires Vault, pg_cron and pg_net.
-- The credential is generated inside Postgres and never returned to the client.
begin;
create extension if not exists pg_cron with schema pg_catalog;
create extension if not exists pg_net with schema extensions;
do $$ begin
 if not exists(select 1 from vault.secrets where name='cn_cleanup_worker_key') then
  perform vault.create_secret(replace(gen_random_uuid()::text||gen_random_uuid()::text,'-',''),'cn_cleanup_worker_key','Cars Night scheduled media cleanup');
 end if;
end $$;
create function public.cn_cleanup_authorized(candidate text) returns boolean
language sql stable security definer set search_path='' as $$
 select candidate is not null and exists(select 1 from vault.decrypted_secrets where name='cn_cleanup_worker_key' and decrypted_secret=candidate);
$$;
revoke all on function public.cn_cleanup_authorized(text) from public,anon,authenticated;
grant execute on function public.cn_cleanup_authorized(text) to service_role;
select cron.schedule('cn-media-cleanup','*/5 * * * *',$job$
 select net.http_post(
  url:='https://romhqgmsoabzowwvuvvp.supabase.co/functions/v1/cn-cleanup-media',
  headers:=jsonb_build_object('Content-Type','application/json','x-cn-worker-key',(select decrypted_secret from vault.decrypted_secrets where name='cn_cleanup_worker_key')),
  body:='{}'::jsonb,timeout_milliseconds:=10000
 ) where exists(select 1 from public.cn_media_cleanup where completed_at is null and available_at<=now() and attempts<20);
$job$);
commit;
