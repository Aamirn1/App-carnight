\set ON_ERROR_STOP on
begin;
insert into auth.users(id) values ('11111111-1111-1111-1111-111111111111'),('22222222-2222-2222-2222-222222222222'),('33333333-3333-3333-3333-333333333333');
insert into public.cn_profiles(id,display_name) values ('11111111-1111-1111-1111-111111111111','Alice'),('22222222-2222-2222-2222-222222222222','Bob');
insert into public.cn_posts(id,owner_id,caption,status) values
 ('aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa','22222222-2222-2222-2222-222222222222','Public photo','published'),
 ('bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb','22222222-2222-2222-2222-222222222222','Private draft','draft');
insert into public.cn_listings(id,owner_id,kind,title,city,currency,price_minor,status) values
 ('cccccccc-cccc-cccc-cccc-cccccccccccc','22222222-2222-2222-2222-222222222222','sale','Car','Dubai','USD',10000,'published');
set local role authenticated;
select set_config('request.jwt.claim.sub','11111111-1111-1111-1111-111111111111',true);
do $$ begin
 begin
  perform public.cn_request_conversation('22222222-2222-2222-2222-222222222222');
  raise exception 'FAIL: non-followed unsolicited request accepted';
 exception when insufficient_privilege then null; end;
 begin
  insert into public.cn_likes(user_id,post_id) values(auth.uid(),'bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb');
  raise exception 'FAIL: private draft could be liked';
 exception when insufficient_privilege then null; end;
end $$;
insert into public.cn_follows(follower_id,followed_id) values(auth.uid(),'22222222-2222-2222-2222-222222222222');
insert into public.cn_likes(user_id,post_id) values(auth.uid(),'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa');
insert into public.cn_comments(user_id,post_id,body) values(auth.uid(),'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa','Great car');
select set_config('test.chat',public.cn_request_conversation('22222222-2222-2222-2222-222222222222')::text,true);
do $$ begin
 if (select count(*) from public.cn_feed(true))<>1 then raise exception 'FAIL: following feed'; end if;
 if not (select liked from public.cn_feed(false) limit 1) then raise exception 'FAIL: like not reflected'; end if;
 if (select like_count from public.cn_feed(false) limit 1)<>1 then raise exception 'FAIL: like count'; end if;
 begin
  perform public.cn_respond_conversation(current_setting('test.chat')::uuid,true);
  raise exception 'FAIL: requester accepted own request';
 exception when insufficient_privilege then null; end;
 begin
  perform public.cn_send_message(current_setting('test.chat')::uuid,'Before consent','dddddddd-dddd-dddd-dddd-dddddddddddd');
  raise exception 'FAIL: message before acceptance';
 exception when insufficient_privilege then null; end;
 begin
  insert into public.cn_conversations(requester_id,recipient_id,status) values(auth.uid(),'22222222-2222-2222-2222-222222222222','active');
  raise exception 'FAIL: direct active conversation insert';
 exception when insufficient_privilege then null; end;
end $$;
-- Recipient accepts. The sender retries exactly the same idempotent request.
select set_config('request.jwt.claim.sub','22222222-2222-2222-2222-222222222222',true);
select public.cn_respond_conversation(current_setting('test.chat')::uuid,true);
select set_config('request.jwt.claim.sub','11111111-1111-1111-1111-111111111111',true);
select public.cn_send_message(current_setting('test.chat')::uuid,'Hello','dddddddd-dddd-dddd-dddd-dddddddddddd');
select public.cn_send_message(current_setting('test.chat')::uuid,'Hello','dddddddd-dddd-dddd-dddd-dddddddddddd');
do $$ begin
 if (select count(*) from public.cn_messages)<>1 then raise exception 'FAIL: duplicate message'; end if;
 begin
  perform public.cn_request_conversation('33333333-3333-3333-3333-333333333333','cccccccc-cccc-cccc-cccc-cccccccccccc');
  raise exception 'FAIL: fake listing recipient';
 exception when insufficient_privilege then null; end;
end $$;
-- A third user has no conversation or message visibility.
select set_config('request.jwt.claim.sub','33333333-3333-3333-3333-333333333333',true);
do $$ begin
 if (select count(*) from public.cn_messages)<>0 then raise exception 'FAIL: third-party messages leak'; end if;
 if (select count(*) from public.cn_conversations)<>0 then raise exception 'FAIL: third-party inbox leak'; end if;
 begin
  perform public.cn_send_message(current_setting('test.chat')::uuid,'Intruder','eeeeeeee-eeee-eeee-eeee-eeeeeeeeeeee');
  raise exception 'FAIL: third-party send';
 exception when insufficient_privilege then null; end;
end $$;
-- A public listing permits a request without following, not an accepted order.
select public.cn_request_conversation('22222222-2222-2222-2222-222222222222','cccccccc-cccc-cccc-cccc-cccccccccccc');
-- Recipient blocks the original sender; reads and sends are denied both ways.
select set_config('request.jwt.claim.sub','22222222-2222-2222-2222-222222222222',true);
insert into public.cn_blocks(blocker_id,blocked_id) values(auth.uid(),'11111111-1111-1111-1111-111111111111');
select set_config('request.jwt.claim.sub','11111111-1111-1111-1111-111111111111',true);
do $$ begin
 if (select count(*) from public.cn_messages)<>0 then raise exception 'FAIL: blocked messages visible'; end if;
 if (select count(*) from public.cn_feed(false))<>0 then raise exception 'FAIL: blocked author in feed'; end if;
 begin
  perform public.cn_send_message(current_setting('test.chat')::uuid,'Blocked send','ffffffff-ffff-ffff-ffff-ffffffffffff');
  raise exception 'FAIL: blocked send';
 exception when insufficient_privilege then null; end;
end $$;
set local role anon;
select set_config('request.jwt.claim.sub','',true);
do $$ begin
 if (select count(*) from public.cn_feed(false))<>1 then raise exception 'FAIL: public feed exposes drafts'; end if;
 begin
  perform 1 from public.cn_messages;
  raise exception 'FAIL: anonymous messages readable';
 exception when insufficient_privilege then null; end;
end $$;
rollback;
\echo 'All social privacy and consent checks passed.'
