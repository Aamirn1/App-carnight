begin;
create index cn_comments_user_idx on public.cn_comments(user_id);
create index cn_reports_reporter_idx on public.cn_reports(reporter_id);
create index cn_reports_reported_idx on public.cn_reports(reported_user_id);
alter table public.cn_listings add column revision integer not null default 1;
-- Clients cannot bypass revision checks by writing revision directly.
revoke update on public.cn_listings from authenticated;
grant update(title,city,currency,price_minor,status,kind,country_code,category,description) on public.cn_listings to authenticated;
create function public.cn_edit_listing(target uuid,expected_revision integer,new_title text,new_description text,new_city text,new_price bigint)
returns void language plpgsql security definer set search_path='' as $$
begin
 if new_price not between 1 and 999999999999 then raise exception 'Invalid price' using errcode='22023'; end if;
 update public.cn_listings set title=btrim(new_title),description=btrim(new_description),city=btrim(new_city),price_minor=new_price,revision=revision+1
 where id=target and owner_id=auth.uid() and status='published' and revision=expected_revision;
 if not found then raise exception 'Offer changed or unavailable; reopen it' using errcode='40001'; end if;
end $$;
revoke all on function public.cn_edit_listing(uuid,integer,text,text,text,bigint) from public,anon,authenticated;
grant execute on function public.cn_edit_listing(uuid,integer,text,text,text,bigint) to authenticated;
grant select on public.cn_saved_listings to anon;
create policy cn_saved_listings_guest_empty on public.cn_saved_listings for select to anon using(false);
drop function public.cn_market(text,text,text,text,text,timestamptz,uuid);
create function public.cn_market(listing_kind text,country_filter text default '',city_filter text default '',query_text text default '',category_filter text default 'All',before_time timestamptz default null,before_id uuid default null,saved_only boolean default false)
returns table(id uuid,owner_id uuid,kind text,title text,description text,country_code text,city text,category text,currency text,price_minor bigint,created_at timestamptz,image_path text,thumbnail_path text,revision integer,saved boolean)
language sql stable security invoker set search_path='' as $$
 select l.id,l.owner_id,l.kind,l.title,l.description,l.country_code,l.city,l.category,l.currency,l.price_minor,l.created_at,m.storage_path,coalesce(t.storage_path,m.storage_path),l.revision,exists(select 1 from public.cn_saved_listings s where s.listing_id=l.id and s.user_id=auth.uid())
 from public.cn_listings l join public.cn_posts p on p.id=l.source_post_id and p.status='published'
 join public.cn_post_media m on m.post_id=p.id and m.position=0
 left join public.cn_post_thumbnails t on t.post_id=p.id and t.position=0
 where (not saved_only or exists(select 1 from public.cn_saved_listings s where s.listing_id=l.id and s.user_id=auth.uid())) and l.status='published' and l.kind=listing_kind and public.cn_can_interact(l.owner_id)
 and (country_filter='' or l.country_code=country_filter)
 and (city_filter='' or position(lower(left(city_filter,80)) in lower(l.city))>0)
 and (query_text='' or position(lower(left(query_text,80)) in lower(l.title))>0)
 and (category_filter='All' or l.category=category_filter)
 and (before_time is null or (l.created_at,l.id)<(before_time,before_id))
 order by l.created_at desc,l.id desc limit 20;
$$;
revoke all on function public.cn_market(text,text,text,text,text,timestamptz,uuid,boolean) from public,anon,authenticated;
grant execute on function public.cn_market(text,text,text,text,text,timestamptz,uuid,boolean) to anon,authenticated;
alter table public.cn_reports add column target_listing_id uuid;
create function public.cn_report_listing(target uuid,reason_text text) returns void
language plpgsql security definer set search_path='' as $$
declare owner uuid; begin
 if auth.uid() is null then raise exception 'Sign in required' using errcode='42501'; end if;
 select owner_id into owner from public.cn_listings where id=target and status='published' and public.cn_can_interact(owner_id);
 if owner is null or owner=auth.uid() then raise exception 'Offer unavailable' using errcode='42501'; end if;
 insert into public.cn_reports(reporter_id,reported_user_id,reason,target_listing_id) values(auth.uid(),owner,btrim(reason_text),target);
end $$;
revoke all on function public.cn_report_listing(uuid,text) from public,anon,authenticated;
grant execute on function public.cn_report_listing(uuid,text) to authenticated;
drop function public.cn_moderation_queue();
create function public.cn_moderation_queue() returns table(id uuid,reason text,target_post_id uuid,target_listing_id uuid,created_at timestamptz,caption text,images jsonb)
language plpgsql security definer set search_path='' as $$
begin
 if not exists(select 1 from public.cn_moderators where user_id=auth.uid()) then raise exception 'Moderator required' using errcode='42501'; end if;
 return query select r.id,r.reason,r.target_post_id,r.target_listing_id,r.created_at,coalesce(l.title,p.caption),coalesce((select jsonb_agg(m.storage_path order by m.position) from public.cn_post_media m where m.post_id=coalesce(r.target_post_id,l.source_post_id)),'[]'::jsonb)
 from public.cn_reports r left join public.cn_posts p on p.id=r.target_post_id left join public.cn_listings l on l.id=r.target_listing_id where r.review_status='open' order by r.created_at,r.id limit 50;
end $$;
revoke all on function public.cn_moderation_queue() from public,anon,authenticated;
grant execute on function public.cn_moderation_queue() to authenticated;
create or replace function public.cn_review_report(report uuid,decision text,review_note text) returns void
language plpgsql security definer set search_path='' as $$
declare item public.cn_reports; begin
 if not exists(select 1 from public.cn_moderators where user_id=auth.uid()) then raise exception 'Moderator required' using errcode='42501'; end if;
 if decision not in ('dismissed','removed') or decision is null or review_note is null or char_length(btrim(review_note)) not between 1 and 500 then raise exception 'Invalid review' using errcode='22023'; end if;
 select * into item from public.cn_reports where id=report for update;
 if not found or item.review_status<>'open' then raise exception 'Report already reviewed or missing' using errcode='22023'; end if;
 if decision='removed' then
  if item.target_listing_id is not null then
   update public.cn_listings set status='archived',revision=revision+1 where id=item.target_listing_id;
  elsif item.target_post_id is not null then
   delete from public.cn_posts where id=item.target_post_id;
  else raise exception 'No content target' using errcode='22023'; end if;
 end if;
 update public.cn_reports set review_status=decision,reviewed_at=now() where id=report;
 insert into public.cn_moderation_actions(report_id,moderator_id,action,note) values(report,auth.uid(),decision,btrim(review_note));
end $$;
create table public.cn_rental_enquiries (
 id uuid primary key, conversation_id uuid not null references public.cn_conversations(id) on delete cascade,
 user_id uuid not null references auth.users(id) on delete cascade,
 pickup date not null,dropoff date not null,created_at timestamptz not null default now(),
 check(dropoff>pickup and dropoff-pickup<=365)
);
create index cn_rental_enquiries_chat_idx on public.cn_rental_enquiries(conversation_id,created_at desc);
create index cn_rental_enquiries_owner_idx on public.cn_rental_enquiries(user_id,created_at);
alter table public.cn_rental_enquiries enable row level security;
revoke all on public.cn_rental_enquiries from public,anon,authenticated;
grant select on public.cn_rental_enquiries to authenticated;
grant all on public.cn_rental_enquiries to service_role;
create policy cn_enquiry_participant on public.cn_rental_enquiries for select to authenticated using(exists(select 1 from public.cn_conversations c where c.id=conversation_id and (select auth.uid()) in(c.requester_id,c.recipient_id) and public.cn_can_interact(case when c.requester_id=auth.uid() then c.recipient_id else c.requester_id end)));

create function public.cn_request_rental(target_listing uuid,pickup_day date,dropoff_day date,request_id uuid) returns uuid
language plpgsql security definer set search_path='' as $$
declare seller uuid; chat uuid; previous public.cn_rental_enquiries; begin
 if auth.uid() is null then raise exception 'Sign in required' using errcode='42501'; end if;
 if pickup_day is null or dropoff_day is null or pickup_day<current_date or pickup_day>current_date+730 or dropoff_day<=pickup_day or dropoff_day-pickup_day>365 then raise exception 'Invalid dates' using errcode='22023'; end if;
 select owner_id into seller from public.cn_listings where id=target_listing and kind='rental' and status='published';
 if seller is null then raise exception 'Offer unavailable' using errcode='42501'; end if;
 chat:=public.cn_request_conversation(seller,target_listing);
 if exists(select 1 from public.cn_conversations where id=chat and status='declined') then raise exception 'Request declined' using errcode='42501'; end if;
 select * into previous from public.cn_rental_enquiries where id=request_id;
 if found then
  if previous.user_id<>auth.uid() or previous.conversation_id<>chat or previous.pickup<>pickup_day or previous.dropoff<>dropoff_day then raise exception 'Request mismatch' using errcode='22023'; end if;
  return chat;
 end if;
 if (select count(*) from public.cn_rental_enquiries where user_id=auth.uid() and created_at>now()-interval '24 hours')>=20 then raise exception 'Enquiry limit reached' using errcode='P0001'; end if;
 insert into public.cn_rental_enquiries(id,conversation_id,user_id,pickup,dropoff) values(request_id,chat,auth.uid(),pickup_day,dropoff_day);
 return chat;
end $$;
revoke all on function public.cn_request_rental(uuid,date,date,uuid) from public,anon,authenticated;
grant execute on function public.cn_request_rental(uuid,date,date,uuid) to authenticated;
do $$ begin
 if exists(select 1 from pg_publication where pubname='supabase_realtime') then
  alter publication supabase_realtime add table public.cn_rental_enquiries;
 end if;
end $$;
commit;
