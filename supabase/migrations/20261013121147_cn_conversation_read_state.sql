begin;
create table public.cn_message_reads (
 user_id uuid not null references auth.users(id) on delete cascade,
 message_id uuid not null references public.cn_messages(id) on delete cascade,
 primary key(user_id,message_id)
);
create index cn_message_reads_message_idx on public.cn_message_reads(message_id);
alter table public.cn_message_reads enable row level security;
revoke all on public.cn_message_reads from public,anon,authenticated;
grant select on public.cn_message_reads to authenticated;
grant all on public.cn_message_reads to service_role;
create policy cn_message_reads_owner on public.cn_message_reads for select to authenticated using(user_id=(select auth.uid()));
-- Mark exactly the fetched messages: a concurrently arriving message stays unread.
create function public.cn_mark_messages_read(message_ids uuid[]) returns void
language plpgsql security definer set search_path='' as $$
begin
 if auth.uid() is null or coalesce(cardinality(message_ids),0)>100 then raise exception 'Invalid read request' using errcode='42501'; end if;
 insert into public.cn_message_reads(user_id,message_id)
 select auth.uid(),m.id from public.cn_messages m join public.cn_conversations c on c.id=m.conversation_id
 where m.id=any(message_ids) and m.sender_id<>auth.uid() and auth.uid() in(c.requester_id,c.recipient_id)
 and public.cn_can_interact(case when c.requester_id=auth.uid() then c.recipient_id else c.requester_id end)
 on conflict do nothing;
end $$;
create function public.cn_inbox(page_offset integer default 0) returns table(
 id uuid,requester_id uuid,recipient_id uuid,listing_id uuid,status text,created_at timestamptz,unread_count bigint)
language sql stable security definer set search_path='' as $$
 select c.id,c.requester_id,c.recipient_id,c.listing_id,c.status,c.created_at,
 (select count(*) from public.cn_messages m where m.conversation_id=c.id and m.sender_id<>auth.uid()
 and not exists(select 1 from public.cn_message_reads r where r.user_id=auth.uid() and r.message_id=m.id))
 from public.cn_conversations c
 where auth.uid() in(c.requester_id,c.recipient_id) and public.cn_can_interact(case when c.requester_id=auth.uid() then c.recipient_id else c.requester_id end)
 order by coalesce((select max(m.created_at) from public.cn_messages m where m.conversation_id=c.id),c.created_at) desc,c.id desc
 limit 20 offset greatest(0,least(page_offset,10000));
$$;
revoke all on function public.cn_mark_messages_read(uuid[]),public.cn_inbox(integer) from public,anon,authenticated;
grant execute on function public.cn_mark_messages_read(uuid[]),public.cn_inbox(integer) to authenticated;
-- Publish only INSERT/UPDATE subscriptions in the client; never stream deletes.
-- CI has no Realtime publication. Hosted projects do.
do $$ declare t text; begin
 if exists(select 1 from pg_publication where pubname='supabase_realtime') then
  foreach t in array array['cn_messages','cn_conversations'] loop
   if not exists(select 1 from pg_publication_tables where pubname='supabase_realtime' and schemaname='public' and tablename=t) then
    execute format('alter publication supabase_realtime add table public.%I',t);
   end if;
  end loop;
 end if;
end $$;
commit;
