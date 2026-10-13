\set ON_ERROR_STOP on
begin;
insert into auth.users(id) values('11111111-1111-1111-1111-111111111111'),('22222222-2222-2222-2222-222222222222'),('33333333-3333-3333-3333-333333333333');
insert into public.cn_conversations(id,requester_id,recipient_id,status) values('aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa','11111111-1111-1111-1111-111111111111','22222222-2222-2222-2222-222222222222','active');
insert into public.cn_messages(id,conversation_id,sender_id,body,client_id) values('bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb','aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa','11111111-1111-1111-1111-111111111111','First',gen_random_uuid());
set local role authenticated;
select set_config('request.jwt.claim.sub','22222222-2222-2222-2222-222222222222',true);
do $$ begin
 if (select unread_count from public.cn_inbox())<>1 then raise exception 'Unread missing'; end if;
end $$;
select public.cn_mark_messages_read(array['bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb']::uuid[]);
select public.cn_mark_messages_read(array['bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb']::uuid[]);
do $$ begin
 if (select unread_count from public.cn_inbox())<>0 then raise exception 'Read not idempotent'; end if;
end $$;
reset role;
insert into public.cn_messages(id,conversation_id,sender_id,body,client_id) values('cccccccc-cccc-cccc-cccc-cccccccccccc','aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa','11111111-1111-1111-1111-111111111111','Arrived later',gen_random_uuid());
set local role authenticated;
select public.cn_mark_messages_read(array['bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb']::uuid[]);
do $$ begin
 if (select unread_count from public.cn_inbox())<>1 then raise exception 'Later message incorrectly read'; end if;
end $$;
select set_config('request.jwt.claim.sub','33333333-3333-3333-3333-333333333333',true);
select public.cn_mark_messages_read(array['cccccccc-cccc-cccc-cccc-cccccccccccc']::uuid[]);
do $$ begin
 if exists(select 1 from public.cn_inbox()) or exists(select 1 from public.cn_message_reads) then raise exception 'Third party leak'; end if;
 begin
  insert into public.cn_message_reads values(auth.uid(),'cccccccc-cccc-cccc-cccc-cccccccccccc');
  raise exception 'Direct write allowed';
 exception when insufficient_privilege then null; end;
end $$;
select set_config('request.jwt.claim.sub','22222222-2222-2222-2222-222222222222',true);
insert into public.cn_blocks(blocker_id,blocked_id) values(auth.uid(),'11111111-1111-1111-1111-111111111111');
select public.cn_mark_messages_read(array['cccccccc-cccc-cccc-cccc-cccccccccccc']::uuid[]);
do $$ begin
 if exists(select 1 from public.cn_inbox()) then raise exception 'Blocked inbox leak'; end if;
 if exists(select 1 from public.cn_message_reads where message_id='cccccccc-cccc-cccc-cccc-cccccccccccc') then raise exception 'Blocked read allowed'; end if;
end $$;
rollback;
