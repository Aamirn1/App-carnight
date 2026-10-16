begin;
create table public.cn_activity_reads (
 user_id uuid not null references auth.users(id) on delete cascade,
 event_key text not null check(char_length(event_key) between 1 and 140),
 created_at timestamptz not null default now(), primary key(user_id,event_key)
);
alter table public.cn_activity_reads enable row level security;
revoke all on public.cn_activity_reads from public,anon,authenticated;
grant select on public.cn_activity_reads to authenticated;
grant all on public.cn_activity_reads to service_role;
create policy cn_activity_reads_owner on public.cn_activity_reads for select to authenticated using(user_id=(select auth.uid()));
create function public.cn_activity(before_time timestamptz default null,before_key text default null)
returns table(event_key text,kind text,actor_id uuid,display_name text,post_id uuid,conversation_id uuid,created_at timestamptz,is_read boolean)
language sql stable security definer set search_path='' as $$
 with events as (
 select 'like:'||l.user_id::text||':'||l.post_id::text||':'||extract(epoch from l.created_at)::text as key,'like'::text as kind,l.user_id as actor,p.id as post,null::uuid as chat,l.created_at as at
 from public.cn_likes l join public.cn_posts p on p.id=l.post_id where p.owner_id=auth.uid() and p.status='published'
 union all
 select 'comment:'||c.id::text,'comment',c.user_id,p.id,null::uuid,c.created_at from public.cn_comments c join public.cn_posts p on p.id=c.post_id where p.owner_id=auth.uid() and p.status='published'
 union all
 select 'follow:'||f.follower_id::text||':'||extract(epoch from f.created_at)::text,'follow',f.follower_id,null::uuid,null::uuid,f.created_at from public.cn_follows f where f.followed_id=auth.uid()
 union all
 select 'request:'||c.id::text,'request',c.requester_id,null::uuid,c.id,c.created_at from public.cn_conversations c where c.recipient_id=auth.uid() and c.status='pending'
 union all
 select 'message:'||m.id::text,'message',m.sender_id,null::uuid,c.id,m.created_at from public.cn_messages m join public.cn_conversations c on c.id=m.conversation_id where auth.uid() in(c.requester_id,c.recipient_id) and c.status='active'
 )
 select e.key,e.kind,e.actor,coalesce(p.display_name,'Car enthusiast'),e.post,e.chat,e.at,
 exists(select 1 from public.cn_activity_reads r where r.user_id=auth.uid() and r.event_key=e.key)
 from events e left join public.cn_profiles p on p.id=e.actor
 where auth.uid() is not null and exists(select 1 from auth.users u where u.id=auth.uid()) and e.actor<>auth.uid() and public.cn_can_interact(e.actor)
 and e.at>now()-interval '30 days' and (before_time is null or (e.at,e.key)<(before_time,before_key))
 order by e.at desc,e.key desc limit 30;
$$;
create function public.cn_read_activity(keys text[]) returns void language plpgsql security definer set search_path='' as $$
begin
 if auth.uid() is null or cardinality(keys)>30 then raise exception 'Invalid read request' using errcode='42501'; end if;
 -- Validating through the same bounded reader prevents fabricated cross-account keys.
 insert into public.cn_activity_reads(user_id,event_key)
 select auth.uid(),a.event_key from public.cn_activity() a where a.event_key=any(keys) on conflict do nothing;
 delete from public.cn_activity_reads where user_id=auth.uid() and created_at<now()-interval '30 days';
end $$;
revoke all on function public.cn_activity(timestamptz,text),public.cn_read_activity(text[]) from public,anon,authenticated;
grant execute on function public.cn_activity(timestamptz,text),public.cn_read_activity(text[]) to authenticated;
create function public.cn_activity_post(target uuid)
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
 where p.status='published' and public.cn_can_interact(p.owner_id) and p.id=target
 and true
 and true
 and true order by p.created_at desc,p.id desc limit 20;
$$;
revoke all on function public.cn_activity_post(uuid) from public,anon,authenticated;
grant execute on function public.cn_activity_post(uuid) to authenticated;
commit;
