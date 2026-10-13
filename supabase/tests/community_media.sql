\set ON_ERROR_STOP on
begin;
insert into auth.users(id) values('11111111-1111-1111-1111-111111111111'),('22222222-2222-2222-2222-222222222222');
insert into auth.sessions values('aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa','11111111-1111-1111-1111-111111111111');
insert into public.cn_profiles(id,display_name,bio,city,dream_car) values('11111111-1111-1111-1111-111111111111','Driver','Public bio','Dubai','Dream car'),('22222222-2222-2222-2222-222222222222','Other','','','');
-- Private signup location must not become public without profile opt-in.
update auth.users set raw_user_meta_data='{"display_name":"Driver","city":"Private city"}'::jsonb where id='11111111-1111-1111-1111-111111111111';
do $$ begin if (select city from public.cn_profiles where id='11111111-1111-1111-1111-111111111111')<>'Dubai' then raise exception 'FAIL private metadata copied'; end if; end $$;
update auth.users set raw_user_meta_data='{"display_name":"Driver","cn_public_profile":true,"cn_bio":"Public bio","city":"Private city","cn_profile_city":"Dubai","cn_dream_car":"Dream car"}'::jsonb where id='11111111-1111-1111-1111-111111111111';
select public.cn_reserve_photo('11111111-1111-1111-1111-111111111111','bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb',repeat('a',64),'Photo');
select public.cn_finish_photo_v2('11111111-1111-1111-1111-111111111111','bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb',800,600,400000,480,360,50000);
set local role authenticated;
select set_config('request.jwt.claim.sub','22222222-2222-2222-2222-222222222222',true);
insert into public.cn_follows(follower_id,followed_id) values('22222222-2222-2222-2222-222222222222','11111111-1111-1111-1111-111111111111');
insert into public.cn_saved_posts(user_id,post_id) select auth.uid(),id from public.cn_posts;
do $$ declare item jsonb; begin
 item:=public.cn_profile('11111111-1111-1111-1111-111111111111');
 if (item->>'followers')::integer<>1 or item->>'bio'<>'Public bio' then raise exception 'FAIL public profile'; end if;
 if (select count(*) from public.cn_saved_feed())<>1 then raise exception 'FAIL saved feed'; end if;
 if (select thumbnails->>0 from public.cn_feed(false)) not like '%_thumb.jpg' then raise exception 'FAIL thumbnail projection'; end if;
 if (select count(*) from public.cn_author_feed('11111111-1111-1111-1111-111111111111'))<>1 then raise exception 'FAIL author feed'; end if;
 update public.cn_profiles set bio='Hijacked' where id='11111111-1111-1111-1111-111111111111';
 if (public.cn_profile('11111111-1111-1111-1111-111111111111')->>'bio')<>'Public bio' then raise exception 'FAIL profile ownership'; end if;
 begin
  perform public.cn_account_delete_attempt(auth.uid());
  raise exception 'FAIL deletion limit exposed';
 exception when insufficient_privilege then null; end;
end $$;
select set_config('request.jwt.claim.sub','11111111-1111-1111-1111-111111111111',true);
do $$ begin
 if (select count(*) from public.cn_saved_feed())<>0 then raise exception 'FAIL saved privacy'; end if;
end $$;
insert into public.cn_blocks(blocker_id,blocked_id) values('11111111-1111-1111-1111-111111111111','22222222-2222-2222-2222-222222222222');
select set_config('request.jwt.claim.sub','22222222-2222-2222-2222-222222222222',true);
do $$ begin
 begin
  perform public.cn_profile('11111111-1111-1111-1111-111111111111');
  raise exception 'FAIL blocked profile';
 exception when insufficient_privilege then null; end;
 if (select count(*) from public.cn_saved_feed())<>0 then raise exception 'FAIL blocked saved post'; end if;
end $$;
reset role;
do $$ begin
 if not public.cn_account_session_valid('11111111-1111-1111-1111-111111111111','aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa') then raise exception 'FAIL session check'; end if;
 if public.cn_account_session_valid('22222222-2222-2222-2222-222222222222','aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa') then raise exception 'FAIL foreign session'; end if;
end $$;
set local role service_role;
do $$ declare i integer; begin
 for i in 1..5 loop perform public.cn_account_delete_attempt('11111111-1111-1111-1111-111111111111'); end loop;
 begin
  perform public.cn_account_delete_attempt('11111111-1111-1111-1111-111111111111');
  raise exception 'FAIL delete attempt budget' using errcode='XX000';
 exception when raise_exception then null; end;
end $$;
do $$ declare i integer; begin
 for i in 1..10 loop perform public.cn_photo_process_attempt('11111111-1111-1111-1111-111111111111'); end loop;
 begin
  perform public.cn_photo_process_attempt('11111111-1111-1111-1111-111111111111');
  raise exception 'FAIL photo processing limit' using errcode='XX000';
 exception when raise_exception then null; end;
end $$;
reset role;
delete from auth.users where id='11111111-1111-1111-1111-111111111111';
do $$ begin
 if (select count(*) from public.cn_media_cleanup)<>2 then raise exception 'FAIL two derivatives not queued'; end if;
 if (select count(*) from public.cn_photo_charges)<>1 then raise exception 'FAIL budget charge disappeared'; end if;
 if (select count(*) from public.cn_saved_posts)<>0 then raise exception 'FAIL saved data remained'; end if;
 if (select count(*) from public.cn_post_thumbnails)<>0 then raise exception 'FAIL thumbnail metadata remained'; end if;
 if (select count(*) from auth.sessions)<>0 then raise exception 'FAIL session survived'; end if;
 if (select website_marker from public.posts limit 1)<>'website-unchanged' then raise exception 'FAIL website touched'; end if;
end $$;
-- Expired unfinished uploads are retired, queued and remain charged.
select public.cn_reserve_photo('22222222-2222-2222-2222-222222222222','cccccccc-cccc-4ccc-8ccc-cccccccccccc',repeat('c',64),'Unfinished');
update public.cn_photo_requests set created_at=now()-interval '8 days' where owner_id='22222222-2222-2222-2222-222222222222';
select public.cn_expire_photo_requests();
do $$ begin
 if exists(select 1 from public.cn_photo_requests where state='reserved') then raise exception 'FAIL stale reservation'; end if;
 if (select count(*) from public.cn_media_cleanup)<>4 then raise exception 'FAIL stale derivatives'; end if;
 if (select count(*) from public.cn_photo_charges)<>2 then raise exception 'FAIL stale budget charge'; end if;
end $$;
insert into public.cn_photo_charges(owner_id,request_id,created_at)
select '11111111-1111-1111-1111-111111111111',gen_random_uuid(),now() from generate_series(1,198);
do $$ begin
 begin
  perform public.cn_reserve_photo('22222222-2222-2222-2222-222222222222',gen_random_uuid(),repeat('b',64),'Cannot bypass deleted-account budget');
  raise exception 'FAIL global budget reset after deletion' using errcode='XX000';
 exception when raise_exception then null; end;
end $$;
rollback;
