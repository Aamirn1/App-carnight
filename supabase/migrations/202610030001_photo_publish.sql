-- Apply after both 20261002 mobile/social migrations. No website objects changed.
begin;
create table public.cn_photo_requests (
  owner_id uuid not null references auth.users(id) on delete cascade,
  request_id uuid not null,
  post_id uuid not null default gen_random_uuid(),
  fingerprint text not null check(fingerprint ~ '^[a-f0-9]{64}$'),
  caption text not null check(char_length(btrim(caption)) between 1 and 500),
  state text not null default 'reserved' check(state in ('reserved','published')),
  created_at timestamptz not null default now(),
  primary key(owner_id,request_id), unique(post_id)
);
create index cn_photo_requests_owner_time on public.cn_photo_requests(owner_id,created_at);
alter table public.cn_photo_requests enable row level security;
revoke all on public.cn_photo_requests from anon,authenticated;
grant all on public.cn_photo_requests to service_role;

-- Reservations remain charged even if a request fails. Thus orphaned objects and
-- deleted posts cannot silently bypass the initial 100 MiB storage budget.
create function public.cn_reserve_photo(actor uuid, request uuid, digest text, body text)
returns jsonb language plpgsql security definer set search_path=public,pg_temp as $$
declare item public.cn_photo_requests; total bigint;
begin
  perform pg_advisory_xact_lock(hashtextextended('cn-photo-global-budget',0));
  select * into item from public.cn_photo_requests where owner_id=actor and request_id=request;
  if found then
    if item.fingerprint<>digest or item.caption<>btrim(body) then
      raise exception 'Request mismatch' using errcode='22023';
    end if;
    return jsonb_build_object('post_id',item.post_id,'state',item.state);
  end if;
  select count(*) into total from public.cn_photo_requests;
  if total >= 200 or
     (select count(*) from public.cn_photo_requests where owner_id=actor) >= 20 or
     (select count(*) from public.cn_photo_requests where owner_id=actor and created_at>now()-interval '24 hours') >= 5 then
    raise exception 'Photo quota reached' using errcode='P0001';
  end if;
  insert into public.cn_photo_requests(owner_id,request_id,fingerprint,caption)
    values(actor,request,digest,btrim(body)) returning * into item;
  return jsonb_build_object('post_id',item.post_id,'state',item.state);
end $$;

create function public.cn_finish_photo(actor uuid, request uuid, image_width integer, image_height integer, image_bytes integer)
returns uuid language plpgsql security definer set search_path=public,pg_temp as $$
declare item public.cn_photo_requests;
begin
  select * into item from public.cn_photo_requests where owner_id=actor and request_id=request for update;
  if not found then raise exception 'Reservation missing' using errcode='22023'; end if;
  if item.state='published' then return item.post_id; end if;
  -- cn_post_media constraints enforce output bounds; all statements roll back together.
  insert into public.cn_posts(id,owner_id,caption,status) values(item.post_id,actor,item.caption,'published');
  insert into public.cn_post_media(post_id,position,storage_path,width,height,bytes)
    values(item.post_id,0,actor::text||'/'||request::text||'.jpg',image_width,image_height,image_bytes);
  update public.cn_photo_requests set state='published' where owner_id=actor and request_id=request;
  return item.post_id;
end $$;
revoke all on function public.cn_reserve_photo(uuid,uuid,text,text),public.cn_finish_photo(uuid,uuid,integer,integer,integer) from public,anon,authenticated;
grant execute on function public.cn_reserve_photo(uuid,uuid,text,text),public.cn_finish_photo(uuid,uuid,integer,integer,integer) to service_role;

-- Bucket upload/update/delete is restricted to the trusted Edge Function.
-- Originals are never stored. Public URLs are for intentionally public photos.
insert into storage.buckets(id,name,public,file_size_limit,allowed_mime_types)
values('cn-media','cn-media',true,524288,array['image/jpeg'])
on conflict(id) do update set public=true,file_size_limit=524288,allowed_mime_types=array['image/jpeg'];
-- Restrictive policies also constrain pre-existing broad website storage policies.
create policy cn_media_no_client_insert on storage.objects as restrictive for insert to anon,authenticated with check(bucket_id<>'cn-media');
create policy cn_media_no_client_update on storage.objects as restrictive for update to anon,authenticated using(bucket_id<>'cn-media') with check(bucket_id<>'cn-media');
create policy cn_media_no_client_delete on storage.objects as restrictive for delete to anon,authenticated using(bucket_id<>'cn-media');
commit;
