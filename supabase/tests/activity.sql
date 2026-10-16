\set ON_ERROR_STOP on
begin;
insert into auth.users(id) values('11111111-1111-1111-1111-111111111111'),('22222222-2222-2222-2222-222222222222'),('33333333-3333-3333-3333-333333333333');
insert into public.cn_profiles(id,display_name) values('11111111-1111-1111-1111-111111111111','Owner'),('22222222-2222-2222-2222-222222222222','Driver');
insert into public.cn_posts(id,owner_id,caption,status) values('aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa','11111111-1111-1111-1111-111111111111','Car','published');
insert into public.cn_likes(user_id,post_id) values('22222222-2222-2222-2222-222222222222','aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa');
insert into public.cn_comments(user_id,post_id,body) values('22222222-2222-2222-2222-222222222222','aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa','Nice car');
insert into public.cn_follows(follower_id,followed_id) values('22222222-2222-2222-2222-222222222222','11111111-1111-1111-1111-111111111111');
insert into public.cn_conversations(id,requester_id,recipient_id,status) values('bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb','22222222-2222-2222-2222-222222222222','11111111-1111-1111-1111-111111111111','pending');
set local role authenticated;
select set_config('request.jwt.claim.sub','11111111-1111-1111-1111-111111111111',true);
do $$ begin
 if (select count(*) from public.cn_activity())<>4 then raise exception 'Activity missing';end if;
 if (select count(*) from public.cn_activity_post('aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa'))<>1 then raise exception 'Post destination missing';end if;
end $$;
select public.cn_read_activity(array(select event_key from public.cn_activity()));
do $$ begin if exists(select 1 from public.cn_activity() where not is_read) then raise exception 'Read markers not persisted';end if;end $$;
select set_config('request.jwt.claim.sub','33333333-3333-3333-3333-333333333333',true);
do $$ begin
 if exists(select 1 from public.cn_activity()) or exists(select 1 from public.cn_activity_reads) then raise exception 'Third-party activity leak';end if;
 begin insert into public.cn_activity_reads values(auth.uid(),'fake',now());raise exception 'Direct read insertion allowed';exception when insufficient_privilege then null;end;
end $$;
select set_config('request.jwt.claim.sub','11111111-1111-1111-1111-111111111111',true);
select public.cn_respond_conversation('bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb',true);
select set_config('request.jwt.claim.sub','22222222-2222-2222-2222-222222222222',true);
select public.cn_send_message('bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb','Private content','cccccccc-cccc-cccc-cccc-cccccccccccc');
do $$ begin if exists(select 1 from public.cn_activity()) then raise exception 'Self or recipient activity leaked';end if;end $$;
select set_config('request.jwt.claim.sub','11111111-1111-1111-1111-111111111111',true);
do $$ begin
 if not exists(select 1 from public.cn_activity() where kind='message' and not is_read) then raise exception 'New message read accidentally';end if;
end $$;
insert into public.cn_blocks(blocker_id,blocked_id) values(auth.uid(),'22222222-2222-2222-2222-222222222222');
do $$ begin if exists(select 1 from public.cn_activity()) then raise exception 'Blocked activity leak';end if;end $$;
reset role;
update public.cn_posts set status='archived' where id='aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa';
set local role authenticated;
do $$ begin if exists(select 1 from public.cn_activity_post('aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa')) then raise exception 'Archived post accessible';end if;end $$;
set local role anon;
do $$ begin begin perform public.cn_activity();raise exception 'Guest activity allowed';exception when insufficient_privilege then null;end;end $$;
rollback;
