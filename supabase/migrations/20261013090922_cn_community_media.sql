begin;
alter table public.cn_profiles add column bio text not null default '' check(char_length(bio)<=500),
 add column city text not null default '' check(char_length(city)<=80),
 add column dream_car text not null default '' check(char_length(dream_car)<=80);
-- Profile opt-in is a publicity preference, never an authorization claim.
-- Updating Auth metadata and the mobile public profile now commits atomically.
create function public.cn_sync_public_profile() returns trigger
language plpgsql security definer set search_path='' as $$
begin
 if new.raw_user_meta_data->>'cn_public_profile'='true' then
  insert into public.cn_profiles(id,display_name,bio,city,dream_car)
  values(new.id,coalesce(nullif(left(btrim(new.raw_user_meta_data->>'display_name'),80),''),'Car enthusiast'),
  left(coalesce(new.raw_user_meta_data->>'cn_bio',''),500),left(coalesce(new.raw_user_meta_data->>'cn_profile_city',''),80),left(coalesce(new.raw_user_meta_data->>'cn_dream_car',''),80))
  on conflict(id) do update set display_name=excluded.display_name,bio=excluded.bio,city=excluded.city,dream_car=excluded.dream_car;
 end if;
 return new;
end $$;
revoke all on function public.cn_sync_public_profile() from public,anon,authenticated;
create trigger cn_public_profile_metadata after update of raw_user_meta_data on auth.users
for each row when(old.raw_user_meta_data is distinct from new.raw_user_meta_data) execute function public.cn_sync_public_profile();
-- These optional fields become public to other signed-in members only when saved.
grant update(bio,city,dream_car) on public.cn_profiles to authenticated;
create table public.cn_post_thumbnails (
 post_id uuid not null references public.cn_posts(id) on delete cascade,
 position smallint not null check(position between 0 and 3),
 storage_path text not null check(storage_path ~ '^[a-zA-Z0-9/_-]+_thumb[.]jpg$'),
 width integer not null check(width between 1 and 480), height integer not null check(height between 1 and 480),
 bytes integer not null check(bytes between 1 and 65536), primary key(post_id,position)
);
alter table public.cn_post_thumbnails enable row level security;
create policy cn_thumb_read on public.cn_post_thumbnails for select to anon,authenticated using(exists(select 1 from public.cn_posts p where p.id=post_id and p.status='published' and public.cn_can_interact(p.owner_id)));
revoke all on public.cn_post_thumbnails from public,anon,authenticated;
grant select on public.cn_post_thumbnails to anon,authenticated;
grant all on public.cn_post_thumbnails to service_role;
create trigger cn_thumb_cleanup before delete on public.cn_post_thumbnails for each row execute function public.cn_queue_media_cleanup();
create or replace function public.cn_cleanup_deleted_reservation() returns trigger
language plpgsql security definer set search_path='' as $$
begin
 insert into public.cn_media_cleanup(storage_path) values(old.owner_id::text||'/'||old.request_id::text||'.jpg'),(old.owner_id::text||'/'||old.request_id::text||'_thumb.jpg') on conflict(storage_path) do nothing;
 return old;
end $$;
-- During an Auth cascade the owner row is already gone. Avoid updating the
-- soon-to-be-cascaded reservation and rechecking its now-missing FK parent.
create or replace function public.cn_retire_photo() returns trigger
language plpgsql security definer set search_path='' as $$
begin
 update public.cn_photo_requests set state='deleted' where post_id=old.id
 and exists(select 1 from auth.users where id=old.owner_id);
 return old;
end $$;
create function public.cn_finish_photo_v2(actor uuid, request uuid, image_width integer,image_height integer,image_bytes integer,thumb_width integer,thumb_height integer,thumb_bytes integer)
returns uuid language plpgsql security definer set search_path='' as $$
declare result uuid; begin
 if image_bytes>458752 or image_bytes+thumb_bytes>524288 then raise exception 'Media budget exceeded' using errcode='22023'; end if;
 result:=public.cn_finish_photo(actor,request,image_width,image_height,image_bytes);
 insert into public.cn_post_thumbnails(post_id,position,storage_path,width,height,bytes) values(result,0,actor::text||'/'||request::text||'_thumb.jpg',thumb_width,thumb_height,thumb_bytes) on conflict(post_id,position) do nothing;
 return result;
end $$;
revoke all on function public.cn_finish_photo_v2(uuid,uuid,integer,integer,integer,integer,integer,integer) from public,anon,authenticated;
grant execute on function public.cn_finish_photo_v2(uuid,uuid,integer,integer,integer,integer,integer,integer) to service_role;

-- Budget charges survive account deletion, including delayed physical cleanup.
create table public.cn_photo_charges (
 owner_id uuid not null, request_id uuid not null, created_at timestamptz not null,
 primary key(owner_id,request_id)
);
insert into public.cn_photo_charges select owner_id,request_id,created_at from public.cn_photo_requests;
alter table public.cn_photo_charges enable row level security;
revoke all on public.cn_photo_charges from public,anon,authenticated;
grant all on public.cn_photo_charges to service_role;
create index cn_photo_charges_time on public.cn_photo_charges(owner_id,created_at);
create function public.cn_record_photo_charge() returns trigger language plpgsql security definer set search_path='' as $$
begin insert into public.cn_photo_charges values(new.owner_id,new.request_id,new.created_at) on conflict do nothing; return new; end $$;
revoke all on function public.cn_record_photo_charge() from public,anon,authenticated;
create trigger cn_charge_photo after insert on public.cn_photo_requests for each row execute function public.cn_record_photo_charge();

create function public.cn_profile(target uuid) returns jsonb language plpgsql stable security definer set search_path='' as $$
declare result jsonb; begin
 if auth.uid() is null or not exists(select 1 from auth.users where id=auth.uid()) or not public.cn_can_interact(target) then raise exception 'Profile unavailable' using errcode='42501'; end if;
 select jsonb_build_object('id',p.id,'display_name',p.display_name,'bio',p.bio,'city',p.city,'dream_car',p.dream_car,
 'followers',(select count(*) from public.cn_follows f where f.followed_id=p.id and public.cn_can_interact(f.follower_id)),
 'following',(select count(*) from public.cn_follows f where f.follower_id=p.id and public.cn_can_interact(f.followed_id)),
 'posts',(select count(*) from public.cn_posts q where q.owner_id=p.id and q.status='published'),
 'is_following',exists(select 1 from public.cn_follows f where f.follower_id=auth.uid() and f.followed_id=p.id)) into result from public.cn_profiles p where p.id=target;
 if result is null then raise exception 'Profile unavailable' using errcode='42501'; end if;
 return result;
end $$;
revoke all on function public.cn_profile(uuid) from public,anon,authenticated;
grant execute on function public.cn_profile(uuid) to authenticated;

-- Internal page selector. External RPCs restrict which collections can be read.
create function public.cn_post_page(following_only boolean,author uuid,saved_only boolean,before_time timestamptz,before_id uuid)
returns table(id uuid,owner_id uuid,caption text,created_at timestamptz,display_name text,like_count bigint,comment_count bigint,liked boolean,following boolean,images jsonb,thumbnails jsonb,saved boolean)
language sql stable security definer set search_path='' as $$
 select p.id,p.owner_id,p.caption,p.created_at,coalesce(pr.display_name,'Car enthusiast'),
 (select count(*) from public.cn_likes l where l.post_id=p.id),
 (select count(*) from public.cn_comments c where c.post_id=p.id and public.cn_can_interact(c.user_id)),
 exists(select 1 from public.cn_likes l where l.post_id=p.id and l.user_id=auth.uid()),
 exists(select 1 from public.cn_follows f where f.follower_id=auth.uid() and f.followed_id=p.owner_id),
 coalesce((select jsonb_agg(m.storage_path order by m.position) from public.cn_post_media m where m.post_id=p.id),'[]'::jsonb),
 coalesce((select jsonb_agg(coalesce(t.storage_path,m.storage_path) order by m.position) from public.cn_post_media m left join public.cn_post_thumbnails t on t.post_id=m.post_id and t.position=m.position where m.post_id=p.id),'[]'::jsonb),
 exists(select 1 from public.cn_saved_posts s where s.user_id=auth.uid() and s.post_id=p.id)
 from public.cn_posts p left join public.cn_profiles pr on pr.id=p.owner_id
 where p.status='published' and public.cn_can_interact(p.owner_id) and (author is null or p.owner_id=author)
 and (not following_only or exists(select 1 from public.cn_follows f where f.follower_id=auth.uid() and f.followed_id=p.owner_id))
 and (not saved_only or exists(select 1 from public.cn_saved_posts s where s.user_id=auth.uid() and s.post_id=p.id))
 and (before_time is null or (p.created_at,p.id)<(before_time,before_id)) order by p.created_at desc,p.id desc limit 20;
$$;
revoke all on function public.cn_post_page(boolean,uuid,boolean,timestamptz,uuid) from public,anon,authenticated;
drop function public.cn_feed(boolean,timestamptz,uuid);
create function public.cn_feed(following_only boolean default false,before_time timestamptz default null,before_id uuid default null)
returns table(id uuid,owner_id uuid,caption text,created_at timestamptz,display_name text,like_count bigint,comment_count bigint,liked boolean,following boolean,images jsonb,thumbnails jsonb,saved boolean)
language sql stable security definer set search_path='' as $$select * from public.cn_post_page(following_only,null,false,before_time,before_id)$$;
create function public.cn_saved_feed(before_time timestamptz default null,before_id uuid default null)
returns table(id uuid,owner_id uuid,caption text,created_at timestamptz,display_name text,like_count bigint,comment_count bigint,liked boolean,following boolean,images jsonb,thumbnails jsonb,saved boolean)
language sql stable security definer set search_path='' as $$select * from public.cn_post_page(false,null,true,before_time,before_id)$$;
create function public.cn_author_feed(target uuid,before_time timestamptz default null,before_id uuid default null)
returns table(id uuid,owner_id uuid,caption text,created_at timestamptz,display_name text,like_count bigint,comment_count bigint,liked boolean,following boolean,images jsonb,thumbnails jsonb,saved boolean)
language sql stable security definer set search_path='' as $$select * from public.cn_post_page(false,target,false,before_time,before_id)$$;
revoke all on function public.cn_feed(boolean,timestamptz,uuid),public.cn_saved_feed(timestamptz,uuid),public.cn_author_feed(uuid,timestamptz,uuid) from public,anon,authenticated;
grant execute on function public.cn_feed(boolean,timestamptz,uuid) to anon,authenticated;
grant execute on function public.cn_saved_feed(timestamptz,uuid),public.cn_author_feed(uuid,timestamptz,uuid) to authenticated;
create function public.cn_account_delete_attempt(actor uuid) returns void language plpgsql security definer set search_path='' as $$
declare hits integer; begin
 insert into public.cn_rate_counters as c(actor,action,started_at,hits) values(actor,'account-delete',now(),1)
 on conflict on constraint cn_rate_counters_pkey do update set hits=case when c.started_at<now()-interval '1 hour' then 1 else c.hits+1 end,
 started_at=case when c.started_at<now()-interval '1 hour' then now() else c.started_at end returning c.hits into hits;
 if hits>5 then raise exception 'Try later' using errcode='P0001'; end if;
end $$;
revoke all on function public.cn_account_delete_attempt(uuid) from public,anon,authenticated;
grant execute on function public.cn_account_delete_attempt(uuid) to service_role;
create or replace function public.cn_reserve_photo(actor uuid, request uuid, digest text, body text)
returns jsonb language plpgsql security definer set search_path=public,pg_temp as $$
declare item public.cn_photo_requests; total bigint;
begin
  perform pg_advisory_xact_lock(hashtextextended('cn-photo-global-budget',0));
  select * into item from public.cn_photo_requests where owner_id=actor and request_id=request;
  if found then
    if item.state='deleted' then raise exception 'Post deleted' using errcode='22023'; end if;
    if item.fingerprint<>digest or item.caption<>btrim(body) then
      raise exception 'Request mismatch' using errcode='22023';
    end if;
    return jsonb_build_object('post_id',item.post_id,'state',item.state);
  end if;
  select count(*) into total from public.cn_photo_charges;
  if total >= 200 or
     (select count(*) from public.cn_photo_charges where owner_id=actor) >= 20 or
     (select count(*) from public.cn_photo_charges where owner_id=actor and created_at>now()-interval '24 hours') >= 5 then
    raise exception 'Photo quota reached' using errcode='P0001';
  end if;
  insert into public.cn_photo_requests(owner_id,request_id,fingerprint,caption)
    values(actor,request,digest,btrim(body)) returning * into item;
  return jsonb_build_object('post_id',item.post_id,'state',item.state);
end $$;

create function public.cn_account_session_valid(actor uuid,session uuid) returns boolean
language sql stable security definer set search_path='' as $$select exists(select 1 from auth.sessions where id=session and user_id=actor)$$;
revoke all on function public.cn_account_session_valid(uuid,uuid) from public,anon,authenticated;
grant execute on function public.cn_account_session_valid(uuid,uuid) to service_role;
create function public.cn_photo_process_attempt(actor uuid) returns void language plpgsql security definer set search_path='' as $$
declare hits integer; begin
 insert into public.cn_rate_counters as c(actor,action,started_at,hits) values(actor,'photo-process',now(),1)
 on conflict on constraint cn_rate_counters_pkey do update set hits=case when c.started_at<now()-interval '1 minute' then 1 else c.hits+1 end,
 started_at=case when c.started_at<now()-interval '1 minute' then now() else c.started_at end returning c.hits into hits;
 if hits>10 then raise exception 'Try later' using errcode='P0001'; end if;
end $$;
revoke all on function public.cn_photo_process_attempt(uuid) from public,anon,authenticated;
grant execute on function public.cn_photo_process_attempt(uuid) to service_role;
create function public.cn_expire_photo_requests() returns void language plpgsql security definer set search_path='' as $$
declare item public.cn_photo_requests; begin
 for item in select * from public.cn_photo_requests where state='reserved' and created_at<now()-interval '7 days' for update skip locked loop
  update public.cn_photo_requests set state='deleted' where owner_id=item.owner_id and request_id=item.request_id;
  insert into public.cn_media_cleanup(storage_path) values(item.owner_id::text||'/'||item.request_id::text||'.jpg'),(item.owner_id::text||'/'||item.request_id::text||'_thumb.jpg') on conflict do nothing;
 end loop;
end $$;
revoke all on function public.cn_expire_photo_requests() from public,anon,authenticated;
grant execute on function public.cn_expire_photo_requests() to service_role;
commit;
