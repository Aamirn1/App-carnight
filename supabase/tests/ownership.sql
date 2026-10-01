\set ON_ERROR_STOP on
begin;
insert into auth.users values ('11111111-1111-1111-1111-111111111111'), ('22222222-2222-2222-2222-222222222222');
insert into public.posts(id,owner_id,caption,status) values
 ('aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa','11111111-1111-1111-1111-111111111111','Visible post','published');
set local role authenticated;
select set_config('request.jwt.claim.sub','11111111-1111-1111-1111-111111111111',true);
insert into public.profiles(id,display_name) values (auth.uid(),'First owner');
insert into public.posts(id,owner_id,caption) values ('bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb',auth.uid(),'Private draft');
insert into public.listings(id,owner_id,kind,title,city,currency,price_minor)
 values ('cccccccc-cccc-cccc-cccc-cccccccccccc',auth.uid(),'sale','Car','Dubai','USD',10000);
insert into public.saved_posts(user_id,post_id) values (auth.uid(),'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa');

do $$ begin
 begin
  insert into public.posts(owner_id,caption,status) values (auth.uid(),'Bypass','published');
  raise exception 'FAIL: client published a post';
 exception when insufficient_privilege then null; end;
 begin
  update public.posts set status='published' where id='bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb';
  raise exception 'FAIL: client approved a draft';
 exception when insufficient_privilege then null; end;
 begin
  insert into public.posts(owner_id,caption) values ('22222222-2222-2222-2222-222222222222','Impersonation');
  raise exception 'FAIL: owner spoofing accepted';
 exception when insufficient_privilege then null; end;
 begin
  insert into public.posts(owner_id,caption) values (auth.uid(),'  ');
  raise exception 'FAIL: empty caption accepted';
 exception when check_violation then null; end;
end $$;

select set_config('request.jwt.claim.sub','22222222-2222-2222-2222-222222222222',true);
do $$ declare touched integer; begin
 if (select count(*) from public.posts) <> 1 then raise exception 'FAIL: private draft leaked'; end if;
 if (select count(*) from public.saved_posts) <> 0 then raise exception 'FAIL: saved collection leaked'; end if;
 if (select count(*) from public.listings) <> 0 then raise exception 'FAIL: draft listing leaked'; end if;
 update public.posts set caption='Stolen' where id='bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb';
 get diagnostics touched = row_count;
 if touched <> 0 then raise exception 'FAIL: another user updated a post'; end if;
 delete from public.listings where id='cccccccc-cccc-cccc-cccc-cccccccccccc';
 get diagnostics touched = row_count;
 if touched <> 0 then raise exception 'FAIL: another user deleted a listing'; end if;
 update public.profiles set display_name='Stolen' where id='11111111-1111-1111-1111-111111111111';
 get diagnostics touched = row_count;
 if touched <> 0 then raise exception 'FAIL: another user updated a profile'; end if;
 begin
  insert into public.saved_posts(user_id,post_id) values (auth.uid(),'bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb');
  raise exception 'FAIL: private draft could be saved';
 exception when insufficient_privilege then null; end;
end $$;

set local role anon;
select set_config('request.jwt.claim.sub','',true);
do $$ begin
 if (select count(*) from public.posts) <> 1 then raise exception 'FAIL: anonymous visibility wrong'; end if;
 begin
  insert into public.posts(owner_id,caption) values ('11111111-1111-1111-1111-111111111111','Anonymous post');
  raise exception 'FAIL: anonymous write accepted';
 exception when insufficient_privilege then null; end;
end $$;

set local role authenticated;
select set_config('request.jwt.claim.sub','11111111-1111-1111-1111-111111111111',true);
update public.posts set caption='Updated own draft' where id='bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb';
do $$ begin
 if not exists(select 1 from public.posts where caption='Updated own draft') then
  raise exception 'FAIL: owner edit rejected'; end if;
end $$;
rollback;
\echo 'All content ownership checks passed.'
