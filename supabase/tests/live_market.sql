\set ON_ERROR_STOP on
begin;
insert into auth.users(id) values('11111111-1111-1111-1111-111111111111'),('22222222-2222-2222-2222-222222222222');
insert into public.cn_posts(id,owner_id,caption,status) values('aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa','11111111-1111-1111-1111-111111111111','My car','published');
insert into public.cn_post_media(post_id,position,storage_path,width,height,bytes) values('aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa',0,'11111111-1111-1111-1111-111111111111/car.jpg',800,600,1000);
set local role authenticated;
select set_config('request.jwt.claim.sub','22222222-2222-2222-2222-222222222222',true);
do $$begin
 begin
 perform public.cn_publish_listing('cccccccc-cccc-cccc-cccc-cccccccccccc','aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa','sale','Car','Details','PK','Rawalpindi','Sedan','PKR',10000);
 raise exception 'Other owner photo accepted';
 exception when insufficient_privilege then null;end;
end $$;
select set_config('request.jwt.claim.sub','11111111-1111-1111-1111-111111111111',true);
select public.cn_publish_listing('cccccccc-cccc-cccc-cccc-cccccccccccc','aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa','sale','Car','Details','PK','Rawalpindi','Sedan','PKR',10000);
select public.cn_publish_listing('cccccccc-cccc-cccc-cccc-cccccccccccc','aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa','sale','Car','Details','PK','Rawalpindi','Sedan','PKR',10000);
do $$begin
 if (select count(*) from public.cn_market('sale','PK','rawal','car'))<>1 then raise exception 'Search failed';end if;
 if exists(select 1 from public.cn_market('rental')) or exists(select 1 from public.cn_market('sale','AE')) then raise exception 'Filter failed';end if;
 begin
 perform public.cn_publish_listing('cccccccc-cccc-cccc-cccc-cccccccccccc','aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa','sale','Changed','Details','PK','Rawalpindi','Sedan','PKR',10000);
 raise exception 'Retry mismatch accepted';
 exception when invalid_parameter_value then null;end;
end $$;
select set_config('request.jwt.claim.sub','22222222-2222-2222-2222-222222222222',true);
select public.cn_request_conversation('11111111-1111-1111-1111-111111111111','cccccccc-cccc-cccc-cccc-cccccccccccc');
insert into public.cn_blocks(blocker_id,blocked_id) values(auth.uid(),'11111111-1111-1111-1111-111111111111');
do $$begin
 if exists(select 1 from public.cn_market('sale')) then raise exception 'Blocked seller visible';end if;
end $$;
select set_config('request.jwt.claim.sub','11111111-1111-1111-1111-111111111111',true);
update public.cn_posts set status='archived' where id='aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa';
do $$begin
 if exists(select 1 from public.cn_market('sale')) then raise exception 'Archived photo listing visible';end if;
 if (select status from public.cn_listings where id='cccccccc-cccc-cccc-cccc-cccccccccccc')<>'archived' then raise exception 'Offer not retired';end if;
end $$;
rollback;
