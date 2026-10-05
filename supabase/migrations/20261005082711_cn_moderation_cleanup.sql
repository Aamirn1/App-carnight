begin;
-- Durable outbox: no FK, so account/post cascades cannot erase cleanup work.
create table public.cn_media_cleanup (
 id uuid primary key default gen_random_uuid(),
 storage_path text not null unique check(storage_path ~ '^[a-zA-Z0-9/_-]+[.](webp|jpg)$'),
 created_at timestamptz not null default now(),
 available_at timestamptz not null default now()+interval '20 minutes',
 attempts integer not null default 0,
 lease_token uuid,
 completed_at timestamptz
);
alter table public.cn_media_cleanup enable row level security;
revoke all on public.cn_media_cleanup from public,anon,authenticated;
grant all on public.cn_media_cleanup to service_role;
create index cn_media_cleanup_due on public.cn_media_cleanup(available_at) where completed_at is null;

alter table public.cn_photo_requests drop constraint cn_photo_requests_state_check;
alter table public.cn_photo_requests add constraint cn_photo_requests_state_check check(state in ('reserved','published','deleted'));
create function public.cn_queue_media_cleanup() returns trigger
language plpgsql security definer set search_path='' as $$
begin
 insert into public.cn_media_cleanup(storage_path) values(old.storage_path) on conflict(storage_path) do nothing;
 return old;
end $$;
create trigger cn_media_cleanup_on_delete before delete on public.cn_post_media for each row execute function public.cn_queue_media_cleanup();
create function public.cn_retire_photo() returns trigger
language plpgsql security definer set search_path='' as $$
begin
 update public.cn_photo_requests set state='deleted' where post_id=old.id;
 return old;
end $$;
create trigger cn_retire_deleted_post before delete on public.cn_posts for each row execute function public.cn_retire_photo();
create function public.cn_cleanup_deleted_reservation() returns trigger
language plpgsql security definer set search_path='' as $$
begin
 insert into public.cn_media_cleanup(storage_path) values(old.owner_id::text||'/'||old.request_id::text||'.jpg') on conflict(storage_path) do nothing;
 return old;
end $$;
create trigger cn_cleanup_reservation before delete on public.cn_photo_requests for each row execute function public.cn_cleanup_deleted_reservation();
revoke all on function public.cn_queue_media_cleanup(),public.cn_retire_photo(),public.cn_cleanup_deleted_reservation() from public,anon,authenticated;

create function public.cn_claim_media_cleanup()
returns table(id uuid,storage_path text,lease_token uuid)
language sql security definer set search_path='' as $$
 with due as (
 select q.id from public.cn_media_cleanup q where q.completed_at is null and q.available_at<=now() and q.attempts<20
 order by q.available_at limit 20 for update skip locked
 )
 update public.cn_media_cleanup q set attempts=q.attempts+1,available_at=now()+interval '15 minutes',lease_token=gen_random_uuid()
 from due where q.id=due.id returning q.id,q.storage_path,q.lease_token;
$$;
create function public.cn_finish_media_cleanup(job uuid,lease uuid,succeeded boolean) returns void
language sql security definer set search_path='' as $$
 update public.cn_media_cleanup set completed_at=case when succeeded then now() else null end,
 available_at=now()+interval '1 hour'
 where id=job and lease_token=lease and completed_at is null;
$$;
revoke all on function public.cn_claim_media_cleanup(),public.cn_finish_media_cleanup(uuid,uuid,boolean) from public,anon,authenticated;
grant execute on function public.cn_claim_media_cleanup(),public.cn_finish_media_cleanup(uuid,uuid,boolean) to service_role;

-- Moderators are assigned only by a trusted operator, never user metadata.
create table public.cn_moderators(user_id uuid primary key references auth.users(id) on delete cascade);
alter table public.cn_moderators enable row level security;
revoke all on public.cn_moderators from public,anon,authenticated;
grant select on public.cn_moderators to authenticated;
grant all on public.cn_moderators to service_role;
create policy cn_moderator_self on public.cn_moderators for select to authenticated using(user_id=(select auth.uid()));
alter table public.cn_reports add column target_post_id uuid,
 add column review_status text not null default 'open' check(review_status in ('open','dismissed','removed')),
 add column reviewed_at timestamptz;
create index cn_reports_open on public.cn_reports(created_at) where review_status='open';
create table public.cn_moderation_actions (
 id uuid primary key default gen_random_uuid(), report_id uuid not null,
 moderator_id uuid not null, action text not null, note text not null,
 created_at timestamptz not null default now()
);
alter table public.cn_moderation_actions enable row level security;
revoke all on public.cn_moderation_actions from public,anon,authenticated;
grant all on public.cn_moderation_actions to service_role;
create function public.cn_report_post(target uuid,reason_text text) returns void
language plpgsql security definer set search_path='' as $$
declare owner uuid; begin
 if auth.uid() is null then raise exception 'Sign in required' using errcode='42501'; end if;
 select owner_id into owner from public.cn_posts where id=target and status='published' and public.cn_can_interact(owner_id);
 if owner is null or owner=auth.uid() then raise exception 'Post unavailable' using errcode='42501'; end if;
 insert into public.cn_reports(reporter_id,reported_user_id,reason,target_post_id) values(auth.uid(),owner,btrim(reason_text),target);
end $$;
create function public.cn_moderation_queue() returns table(id uuid,reason text,target_post_id uuid,created_at timestamptz,caption text,images jsonb)
language plpgsql security definer set search_path='' as $$
begin
 if not exists(select 1 from public.cn_moderators where user_id=auth.uid()) then raise exception 'Moderator required' using errcode='42501'; end if;
 return query select r.id,r.reason,r.target_post_id,r.created_at,p.caption,coalesce((select jsonb_agg(m.storage_path order by m.position) from public.cn_post_media m where m.post_id=r.target_post_id),'[]'::jsonb) from public.cn_reports r
 left join public.cn_posts p on p.id=r.target_post_id where r.review_status='open' order by r.created_at,r.id limit 50;
end $$;
create function public.cn_review_report(report uuid,decision text,review_note text) returns void
language plpgsql security definer set search_path='' as $$
declare item public.cn_reports; begin
 if not exists(select 1 from public.cn_moderators where user_id=auth.uid()) then raise exception 'Moderator required' using errcode='42501'; end if;
 if decision not in ('dismissed','removed') or decision is null or review_note is null or char_length(btrim(review_note)) not between 1 and 500 then raise exception 'Invalid review' using errcode='22023'; end if;
 select * into item from public.cn_reports where id=report for update;
 if not found or item.review_status<>'open' then raise exception 'Report already reviewed or missing' using errcode='22023'; end if;
 if decision='removed' then
  if item.target_post_id is null then raise exception 'This report has no post' using errcode='22023'; end if;
  delete from public.cn_posts where id=item.target_post_id;
 end if;
 update public.cn_reports set review_status=decision,reviewed_at=now() where id=report;
 insert into public.cn_moderation_actions(report_id,moderator_id,action,note) values(report,auth.uid(),decision,btrim(review_note));
end $$;
revoke all on function public.cn_report_post(uuid,text),public.cn_moderation_queue(),public.cn_review_report(uuid,text,text) from public,anon,authenticated;
grant execute on function public.cn_report_post(uuid,text),public.cn_moderation_queue(),public.cn_review_report(uuid,text,text) to authenticated;
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

create or replace function public.cn_finish_photo(actor uuid, request uuid, image_width integer, image_height integer, image_bytes integer)
returns uuid language plpgsql security definer set search_path=public,pg_temp as $$
declare item public.cn_photo_requests;
begin
  select * into item from public.cn_photo_requests where owner_id=actor and request_id=request for update;
  if not found then raise exception 'Reservation missing' using errcode='22023'; end if;
  if item.state='deleted' then raise exception 'Post deleted' using errcode='22023'; end if;
  if item.state='published' then return item.post_id; end if;
  -- cn_post_media constraints enforce output bounds; all statements roll back together.
  insert into public.cn_posts(id,owner_id,caption,status) values(item.post_id,actor,item.caption,'published');
  insert into public.cn_post_media(post_id,position,storage_path,width,height,bytes)
    values(item.post_id,0,actor::text||'/'||request::text||'.jpg',image_width,image_height,image_bytes);
  update public.cn_photo_requests set state='published' where owner_id=actor and request_id=request;
  return item.post_id;
end $$;
commit;
