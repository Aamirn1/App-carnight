-- Hosted only. Existing Vault credential and worker remain unchanged.
begin;
select cron.schedule('cn-media-cleanup','*/5 * * * *',$job$
 select public.cn_expire_photo_requests();
 select net.http_post(
  url:='https://romhqgmsoabzowwvuvvp.supabase.co/functions/v1/cn-cleanup-media',
  headers:=jsonb_build_object('Content-Type','application/json','x-cn-worker-key',(select decrypted_secret from vault.decrypted_secrets where name='cn_cleanup_worker_key')),
  body:='{}'::jsonb,timeout_milliseconds:=10000
 ) where exists(select 1 from public.cn_media_cleanup where completed_at is null and available_at<=now() and attempts<20);
$job$);
commit;
