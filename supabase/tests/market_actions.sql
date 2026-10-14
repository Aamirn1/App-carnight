\set ON_ERROR_STOP on
begin;
insert into auth.users(id) values('11111111-1111-1111-1111-111111111111'),('22222222-2222-2222-2222-222222222222'),('33333333-3333-3333-3333-333333333333');
insert into public.cn_posts(id,owner_id,caption,status) values('aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa','11111111-1111-1111-1111-111111111111','Car','published');
insert into public.cn_post_media(post_id,position,storage_path,width,height,bytes) values('aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa',0,'11111111-1111-1111-1111-111111111111/car.jpg',800,600,1000);
insert into public.cn_listings(id,owner_id,kind,title,city,currency,price_minor,status,source_post_id,country_code) values('bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb','11111111-1111-1111-1111-111111111111','rental','Car','Dubai','AED',10000,'published','aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa','AE');
insert into public.cn_moderators values('33333333-3333-3333-3333-333333333333');
set local role anon;
do $$ begin if (select count(*) from public.cn_market('rental'))<>1 then raise exception 'Guest market failed'; end if; end $$;
set local role authenticated;
select set_config('request.jwt.claim.sub','22222222-2222-2222-2222-222222222222',true);
insert into public.cn_saved_listings(user_id,listing_id) values(auth.uid(),'bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb');
do $$ begin
 if (select count(*) from public.cn_market('rental',saved_only=>true))<>1 then raise exception 'Saved collection failed';end if;
 begin perform public.cn_edit_listing('bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb',1,'Stolen','Details','Dubai',20000);raise exception 'Wrong owner edited';exception when serialization_failure then null;end;
 begin perform public.cn_request_rental('bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb',current_date+2,current_date+1,gen_random_uuid());raise exception 'Invalid dates allowed';exception when invalid_parameter_value then null;end;
end $$;
select public.cn_request_rental('bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb',current_date+1,current_date+3,'cccccccc-cccc-cccc-cccc-cccccccccccc');
select public.cn_request_rental('bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb',current_date+1,current_date+3,'cccccccc-cccc-cccc-cccc-cccccccccccc');
select public.cn_report_listing('bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb','Misleading offer');
do $$ begin
 if (select count(*) from public.cn_rental_enquiries)<>1 then raise exception 'Duplicate enquiry';end if;
 begin perform public.cn_moderation_queue();raise exception 'Non-moderator read reports';exception when insufficient_privilege then null;end;
end $$;
select set_config('request.jwt.claim.sub','11111111-1111-1111-1111-111111111111',true);
do $$ begin
 if exists(select 1 from public.cn_market('rental',saved_only=>true)) then raise exception 'Other users saved cars leaked';end if;
 if (select count(*) from public.cn_rental_enquiries)<>1 then raise exception 'Seller cannot see requested dates';end if;
end $$;
select public.cn_edit_listing('bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb',1,'Updated','Details','Dubai',20000);
do $$ begin
 begin perform public.cn_edit_listing('bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb',1,'Old','Details','Dubai',20000);raise exception 'Stale write accepted';exception when serialization_failure then null;end;
end $$;
select set_config('request.jwt.claim.sub','33333333-3333-3333-3333-333333333333',true);
do $$ declare report_id uuid; begin
 if exists(select 1 from public.cn_rental_enquiries) then raise exception 'Third party sees dates';end if;
 select id into report_id from public.cn_moderation_queue() where target_listing_id='bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb';
 if report_id is null then raise exception 'Listing report missing';end if;
 perform public.cn_review_report(report_id,'removed','Misleading offer confirmed');
 if exists(select 1 from public.cn_market('rental')) then raise exception 'Removed offer still visible';end if;
end $$;
reset role;
do $$ begin
 if not exists(select 1 from public.cn_posts where id='aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa') then raise exception 'Listing removal deleted social photo';end if;
end $$;
rollback;
