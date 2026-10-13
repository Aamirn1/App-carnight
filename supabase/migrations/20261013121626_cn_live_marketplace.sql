begin;
alter table public.cn_listings add column country_code text not null default '' check(country_code='' or country_code ~ '^[A-Z]{2}$'),
 add column category text not null default 'Sedan' check(category in('Luxury','SUV','Sports','Sedan','Other')),
 add column description text not null default '' check(char_length(description)<=2000),
 add column source_post_id uuid references public.cn_posts(id) on delete cascade;
create index cn_listings_source_idx on public.cn_listings(source_post_id);
drop policy cn_listings_read on public.cn_listings;
create policy cn_listings_read on public.cn_listings for select to anon,authenticated using(
 owner_id=(select auth.uid()) or (status='published' and public.cn_can_interact(owner_id) and exists(select 1 from public.cn_posts p where p.id=source_post_id and p.status='published')));
create function public.cn_publish_listing(request_id uuid,photo_post uuid,listing_kind text,listing_title text,listing_description text,listing_country text,listing_city text,listing_category text,listing_currency text,listing_price bigint)
returns uuid language plpgsql security definer set search_path='' as $$
declare me uuid:=auth.uid(); existing public.cn_listings; begin
 if me is null then raise exception 'Sign in required' using errcode='42501'; end if;
 perform pg_advisory_xact_lock(hashtextextended(me::text,7));
 if not exists(select 1 from public.cn_posts p join public.cn_post_media m on m.post_id=p.id where p.id=photo_post and p.owner_id=me and p.status='published') then raise exception 'Choose your own published photo' using errcode='42501'; end if;
 if listing_country !~ '^[A-Z]{2}$' or listing_currency not in('USD','PKR','AED','EUR','GBP','SAR','INR','JPY','KWD','BHD') or listing_price not between 1 and 999999999999 then raise exception 'Invalid price or country' using errcode='22023'; end if;
 select * into existing from public.cn_listings where id=request_id;
 if found then
  if existing.owner_id<>me or existing.source_post_id is distinct from photo_post or existing.title<>btrim(listing_title) or existing.description<>btrim(listing_description) or existing.price_minor<>listing_price or existing.currency<>listing_currency or existing.kind<>listing_kind or existing.country_code<>listing_country or existing.city<>btrim(listing_city) or existing.category<>listing_category or existing.status<>'published' then raise exception 'Request already used' using errcode='22023'; end if;
  return existing.id;
 end if;
 if (select count(*) from public.cn_listings where owner_id=me)>=20 then raise exception 'Listing limit reached' using errcode='P0001'; end if;
 insert into public.cn_listings(id,owner_id,kind,title,description,country_code,city,category,currency,price_minor,source_post_id,status)
 values(request_id,me,listing_kind,btrim(listing_title),btrim(listing_description),listing_country,btrim(listing_city),listing_category,listing_currency,listing_price,photo_post,'published');
 return request_id;
end $$;
create function public.cn_market(listing_kind text,country_filter text default '',city_filter text default '',query_text text default '',category_filter text default 'All',before_time timestamptz default null,before_id uuid default null)
returns table(id uuid,owner_id uuid,kind text,title text,description text,country_code text,city text,category text,currency text,price_minor bigint,created_at timestamptz,image_path text,thumbnail_path text)
language sql stable security invoker set search_path='' as $$
 select l.id,l.owner_id,l.kind,l.title,l.description,l.country_code,l.city,l.category,l.currency,l.price_minor,l.created_at,m.storage_path,coalesce(t.storage_path,m.storage_path)
 from public.cn_listings l join public.cn_posts p on p.id=l.source_post_id and p.status='published'
 join public.cn_post_media m on m.post_id=p.id and m.position=0
 left join public.cn_post_thumbnails t on t.post_id=p.id and t.position=0
 where l.status='published' and l.kind=listing_kind and public.cn_can_interact(l.owner_id)
 and (country_filter='' or l.country_code=country_filter)
 and (city_filter='' or position(lower(left(city_filter,80)) in lower(l.city))>0)
 and (query_text='' or position(lower(left(query_text,80)) in lower(l.title))>0)
 and (category_filter='All' or l.category=category_filter)
 and (before_time is null or (l.created_at,l.id)<(before_time,before_id))
 order by l.created_at desc,l.id desc limit 20;
$$;
revoke all on function public.cn_publish_listing(uuid,uuid,text,text,text,text,text,text,text,bigint),public.cn_market(text,text,text,text,text,timestamptz,uuid) from public,anon,authenticated;
grant execute on function public.cn_publish_listing(uuid,uuid,text,text,text,text,text,text,text,bigint) to authenticated;
grant execute on function public.cn_market(text,text,text,text,text,timestamptz,uuid) to anon,authenticated;
-- Ensure requests cannot be sent to an offer whose supporting photo was removed.
-- Existing request function validates published status; retire associated offers.
create function public.cn_retire_post_listings() returns trigger language plpgsql security definer set search_path='' as $$
begin
 if new.status<>'published' then update public.cn_listings set status='archived' where source_post_id=new.id and status='published'; end if;
 return new;
end $$;
revoke all on function public.cn_retire_post_listings() from public,anon,authenticated;
create trigger cn_retire_post_listings after update of status on public.cn_posts for each row execute function public.cn_retire_post_listings();
commit;
