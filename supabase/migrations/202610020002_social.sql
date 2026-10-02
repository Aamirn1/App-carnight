-- Apply after 202610020001_mobile_content.sql. No website tables are modified.
begin;
create table public.cn_blocks (
 blocker_id uuid not null references auth.users(id) on delete cascade,
 blocked_id uuid not null references auth.users(id) on delete cascade,
 blocked_label text not null default 'Car enthusiast' check(char_length(blocked_label) between 1 and 80),
 created_at timestamptz not null default now(),
 primary key(blocker_id,blocked_id), check(blocker_id <> blocked_id)
);
create index cn_blocks_reverse_idx on public.cn_blocks(blocked_id,blocker_id);
alter table public.cn_blocks enable row level security;
create policy cn_blocks_owner on public.cn_blocks for all to authenticated
 using(blocker_id=(select auth.uid())) with check(blocker_id=(select auth.uid()));

create function public.cn_can_interact(other_id uuid) returns boolean
 language sql stable security definer set search_path = '' as $$
 select not exists(select 1 from public.cn_blocks b where
 (b.blocker_id=auth.uid() and b.blocked_id=other_id) or
 (b.blocker_id=other_id and b.blocked_id=auth.uid()));
$$;
revoke all on function public.cn_can_interact(uuid) from public;
grant execute on function public.cn_can_interact(uuid) to anon,authenticated;

drop policy cn_profiles_read on public.cn_profiles;
create policy cn_profiles_read on public.cn_profiles for select to authenticated using(public.cn_can_interact(id));

create table public.cn_follows (
 follower_id uuid not null references auth.users(id) on delete cascade,
 followed_id uuid not null references auth.users(id) on delete cascade,
 created_at timestamptz not null default now(),
 primary key(follower_id,followed_id), check(follower_id <> followed_id)
);
create index cn_follows_reverse_idx on public.cn_follows(followed_id,follower_id);
alter table public.cn_follows enable row level security;
create policy cn_follows_read on public.cn_follows for select to authenticated
 using(follower_id=(select auth.uid()));
create policy cn_follows_insert on public.cn_follows for insert to authenticated
 with check(follower_id=(select auth.uid()) and public.cn_can_interact(followed_id));
create policy cn_follows_delete on public.cn_follows for delete to authenticated
 using(follower_id=(select auth.uid()));

create table public.cn_likes (
 user_id uuid not null references auth.users(id) on delete cascade,
 post_id uuid not null references public.cn_posts(id) on delete cascade,
 created_at timestamptz not null default now(), primary key(user_id,post_id)
);
create index cn_likes_post_idx on public.cn_likes(post_id);
create table public.cn_comments (
 id uuid primary key default gen_random_uuid(),
 user_id uuid not null references auth.users(id) on delete cascade,
 post_id uuid not null references public.cn_posts(id) on delete cascade,
 body text not null check(char_length(btrim(body)) between 1 and 500),
 created_at timestamptz not null default now()
);
create index cn_comments_page_idx on public.cn_comments(post_id,created_at,id);
alter table public.cn_likes enable row level security;
alter table public.cn_comments enable row level security;
create policy cn_likes_read on public.cn_likes for select to authenticated using
 (exists(select 1 from public.cn_posts p where p.id=post_id and p.status='published' and public.cn_can_interact(p.owner_id)));
create policy cn_likes_insert on public.cn_likes for insert to authenticated with check
 (user_id=(select auth.uid()) and exists(select 1 from public.cn_posts p where p.id=post_id and p.status='published' and public.cn_can_interact(p.owner_id)));
create policy cn_likes_delete on public.cn_likes for delete to authenticated using(user_id=(select auth.uid()));
create policy cn_comments_read on public.cn_comments for select to authenticated using
 (public.cn_can_interact(user_id) and exists(select 1 from public.cn_posts p where p.id=post_id and p.status='published' and public.cn_can_interact(p.owner_id)));
create policy cn_comments_insert on public.cn_comments for insert to authenticated with check
 (user_id=(select auth.uid()) and exists(select 1 from public.cn_posts p where p.id=post_id and p.status='published' and public.cn_can_interact(p.owner_id)));
create policy cn_comments_delete on public.cn_comments for delete to authenticated using(user_id=(select auth.uid()));

-- Only the future trusted media validator may insert these approved paths.
create table public.cn_post_media (
 id uuid primary key default gen_random_uuid(),
 post_id uuid not null references public.cn_posts(id) on delete cascade,
 position smallint not null check(position between 0 and 3),
 storage_path text not null check(storage_path ~ '^[a-zA-Z0-9/_-]+\.(webp|jpg)$'),
 width integer not null check(width between 1 and 1600),
 height integer not null check(height between 1 and 1600),
 bytes integer not null check(bytes between 1 and 524288),
 unique(post_id,position)
);
alter table public.cn_post_media enable row level security;
create policy cn_media_read on public.cn_post_media for select to anon,authenticated using
 (exists(select 1 from public.cn_posts p where p.id=post_id and p.status='published' and public.cn_can_interact(p.owner_id)));

create table public.cn_conversations (
 id uuid primary key default gen_random_uuid(),
 requester_id uuid not null references auth.users(id) on delete cascade,
 recipient_id uuid not null references auth.users(id) on delete cascade,
 -- Immutable listing reference, validated by the request RPC; history survives deletion.
 listing_id uuid,
 status text not null default 'pending' check(status in ('pending','active','declined')),
 created_at timestamptz not null default now(), check(requester_id <> recipient_id)
);
create unique index cn_conversation_pair_idx on public.cn_conversations
 (least(requester_id,recipient_id),greatest(requester_id,recipient_id),coalesce(listing_id,'00000000-0000-0000-0000-000000000000'::uuid));
create index cn_conversation_recipient_idx on public.cn_conversations(recipient_id,created_at desc);
create index cn_conversation_requester_idx on public.cn_conversations(requester_id,created_at desc);
alter table public.cn_conversations enable row level security;
create policy cn_conversations_read on public.cn_conversations for select to authenticated using
 ((requester_id=(select auth.uid()) or recipient_id=(select auth.uid())) and
 public.cn_can_interact(case when requester_id=auth.uid() then recipient_id else requester_id end));

create table public.cn_messages (
 id uuid primary key default gen_random_uuid(),
 conversation_id uuid not null references public.cn_conversations(id) on delete cascade,
 sender_id uuid not null references auth.users(id) on delete cascade,
 body text not null check(char_length(btrim(body)) between 1 and 2000),
 client_id uuid not null,
 created_at timestamptz not null default now(), unique(sender_id,client_id)
);
create index cn_messages_page_idx on public.cn_messages(conversation_id,created_at desc,id desc);
create index cn_messages_rate_idx on public.cn_messages(sender_id,created_at desc);
alter table public.cn_messages enable row level security;
create policy cn_messages_read on public.cn_messages for select to authenticated using
 (exists(select 1 from public.cn_conversations c where c.id=conversation_id));
-- Inserts go through the rate-limited RPC, which checks status, blocks and identity.

create table public.cn_reports (
 id uuid primary key default gen_random_uuid(),
 reporter_id uuid not null references auth.users(id) on delete cascade,
 reported_user_id uuid not null references auth.users(id) on delete cascade,
 reason text not null check(char_length(btrim(reason)) between 1 and 500),
 created_at timestamptz not null default now()
);
alter table public.cn_reports enable row level security;
create policy cn_reports_own on public.cn_reports for select to authenticated using(reporter_id=(select auth.uid()));
create policy cn_reports_insert on public.cn_reports for insert to authenticated with check(reporter_id=(select auth.uid()));

-- No dynamic SQL, fixed search paths, caller checks, and explicit execution grants.
create function public.cn_request_conversation(target_id uuid, for_listing uuid default null)
 returns uuid language plpgsql security definer set search_path='' as $$
declare me uuid:=auth.uid(); result uuid; begin
 if me is null or me=target_id or not public.cn_can_interact(target_id) then raise exception 'Request not allowed' using errcode='42501'; end if;
 if for_listing is null then
  if not exists(select 1 from public.cn_follows where follower_id=me and followed_id=target_id) then raise exception 'Follow this person before requesting a conversation' using errcode='42501'; end if;
 elsif not exists(select 1 from public.cn_listings where id=for_listing and owner_id=target_id and status='published') then
  raise exception 'Listing unavailable' using errcode='42501';
 end if;
 perform pg_advisory_xact_lock(hashtextextended(me::text,1));
 perform pg_advisory_xact_lock(hashtextextended(least(me,target_id)::text || greatest(me,target_id)::text || coalesce(for_listing::text,''),3));
 select id into result from public.cn_conversations where ((requester_id=me and recipient_id=target_id) or (requester_id=target_id and recipient_id=me)) and listing_id is not distinct from for_listing;
 if result is not null then return result; end if;
 if (select count(*) from public.cn_conversations where requester_id=me and created_at>now()-interval '1 hour')>=10 then raise exception 'Request limit reached'; end if;
 insert into public.cn_conversations(requester_id,recipient_id,listing_id) values(me,target_id,for_listing) returning id into result;
 return result;
end $$;
create function public.cn_respond_conversation(conversation uuid, accept_request boolean)
 returns void language plpgsql security definer set search_path='' as $$
begin
 update public.cn_conversations set status=case when accept_request then 'active' else 'declined' end
 where id=conversation and recipient_id=auth.uid() and status='pending' and public.cn_can_interact(requester_id);
 if not found then raise exception 'Request unavailable' using errcode='42501'; end if;
end $$;
create function public.cn_send_message(conversation uuid, message_body text, request_id uuid)
 returns uuid language plpgsql security definer set search_path='' as $$
declare me uuid:=auth.uid(); result uuid; begin
 if me is null then raise exception 'Sign in required' using errcode='42501'; end if;
 perform pg_advisory_xact_lock(hashtextextended(me::text,2));
 if not exists(select 1 from public.cn_conversations where id=conversation and status='active'
 and me in (requester_id,recipient_id) and public.cn_can_interact(case when requester_id=me then recipient_id else requester_id end)) then
 raise exception 'Conversation unavailable' using errcode='42501'; end if;
 select id into result from public.cn_messages where sender_id=me and client_id=request_id;
 if result is not null then
  if not exists(select 1 from public.cn_messages where id=result and conversation_id=conversation and body=btrim(message_body)) then raise exception 'Request ID already used for another message' using errcode='22023'; end if;
  return result;
 end if;
 if (select count(*) from public.cn_messages where sender_id=me and created_at>now()-interval '1 minute')>=30 then raise exception 'Message limit reached'; end if;
 insert into public.cn_messages(conversation_id,sender_id,body,client_id) values(conversation,me,btrim(message_body),request_id) returning id into result;
 return result;
end $$;

create function public.cn_feed(following_only boolean default false, before_time timestamptz default null, before_id uuid default null)
 returns table(id uuid,owner_id uuid,caption text,created_at timestamptz,display_name text,like_count bigint,comment_count bigint,liked boolean,following boolean,images jsonb)
 language sql stable security definer set search_path='' as $$
 select p.id,p.owner_id,p.caption,p.created_at,coalesce(pr.display_name,'Car enthusiast'),
 (select count(*) from public.cn_likes l where l.post_id=p.id),
 (select count(*) from public.cn_comments c where c.post_id=p.id and public.cn_can_interact(c.user_id)),
 exists(select 1 from public.cn_likes l where l.post_id=p.id and l.user_id=auth.uid()),
 exists(select 1 from public.cn_follows f where f.follower_id=auth.uid() and f.followed_id=p.owner_id),
 coalesce((select jsonb_agg(m.storage_path order by m.position) from public.cn_post_media m where m.post_id=p.id),'[]'::jsonb)
 from public.cn_posts p left join public.cn_profiles pr on pr.id=p.owner_id
 where p.status='published' and public.cn_can_interact(p.owner_id)
 and (not following_only or exists(select 1 from public.cn_follows f where f.follower_id=auth.uid() and f.followed_id=p.owner_id))
 and (before_time is null or (p.created_at,p.id)<(before_time,before_id))
 order by p.created_at desc,p.id desc limit 20;
$$;

revoke all on public.cn_blocks,public.cn_follows,public.cn_likes,public.cn_comments,public.cn_post_media,public.cn_conversations,public.cn_messages,public.cn_reports from anon,authenticated;
grant select,delete on public.cn_blocks,public.cn_follows,public.cn_likes,public.cn_comments to authenticated;
grant insert(blocker_id,blocked_id,blocked_label) on public.cn_blocks to authenticated;
grant insert(follower_id,followed_id) on public.cn_follows to authenticated;
grant insert(user_id,post_id) on public.cn_likes to authenticated;
grant insert(user_id,post_id,body) on public.cn_comments to authenticated;
grant select on public.cn_reports to authenticated;
grant insert(reporter_id,reported_user_id,reason) on public.cn_reports to authenticated;
grant select on public.cn_conversations,public.cn_messages to authenticated;
grant select on public.cn_post_media to anon,authenticated;
grant all on public.cn_blocks,public.cn_follows,public.cn_likes,public.cn_comments,public.cn_post_media,public.cn_conversations,public.cn_messages,public.cn_reports to service_role;
revoke all on function public.cn_request_conversation(uuid,uuid),public.cn_respond_conversation(uuid,boolean),public.cn_send_message(uuid,text,uuid),public.cn_feed(boolean,timestamptz,uuid) from public;
grant execute on function public.cn_request_conversation(uuid,uuid),public.cn_respond_conversation(uuid,boolean),public.cn_send_message(uuid,text,uuid) to authenticated;
grant execute on function public.cn_feed(boolean,timestamptz,uuid) to anon,authenticated;
-- Bounded per-user counters prevent rapid writes from exhausting the small budget.
create table public.cn_rate_counters (
 actor uuid not null references auth.users(id) on delete cascade,
 action text not null, started_at timestamptz not null, hits integer not null,
 primary key(actor,action)
);
alter table public.cn_rate_counters enable row level security;
revoke all on public.cn_rate_counters from public,anon,authenticated;
grant all on public.cn_rate_counters to service_role;
create function public.cn_limit_social_write() returns trigger
 language plpgsql security definer set search_path='' as $$
declare me uuid:=auth.uid(); max_hits integer; seconds integer; current_hits integer; begin
 if me is null then return new; end if;
 case TG_TABLE_NAME
  when 'cn_comments' then max_hits:=10; seconds:=60;
  when 'cn_likes' then max_hits:=30; seconds:=60;
  when 'cn_follows' then max_hits:=60; seconds:=3600;
  when 'cn_reports' then max_hits:=5; seconds:=3600;
  when 'cn_blocks' then max_hits:=30; seconds:=3600;
  else raise exception 'Unsupported social action';
 end case;
 insert into public.cn_rate_counters as counter(actor,action,started_at,hits)
 values(me,TG_TABLE_NAME,now(),1)
 on conflict(actor,action) do update set
 hits=case when counter.started_at <= now()-make_interval(secs=>seconds) then 1 else counter.hits+1 end,
 started_at=case when counter.started_at <= now()-make_interval(secs=>seconds) then now() else counter.started_at end
 returning hits into current_hits;
 if current_hits>max_hits then raise exception 'Too many requests. Try later.' using errcode='P0001'; end if;
 return new;
end $$;
revoke all on function public.cn_limit_social_write() from public,anon,authenticated;
create trigger cn_comment_limit before insert on public.cn_comments for each row execute function public.cn_limit_social_write();
create trigger cn_like_limit before insert on public.cn_likes for each row execute function public.cn_limit_social_write();
create trigger cn_follow_limit before insert on public.cn_follows for each row execute function public.cn_limit_social_write();
create trigger cn_report_limit before insert on public.cn_reports for each row execute function public.cn_limit_social_write();
create trigger cn_block_limit before insert on public.cn_blocks for each row execute function public.cn_limit_social_write();
commit;
