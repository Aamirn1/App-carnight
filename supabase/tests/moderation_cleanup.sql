\set ON_ERROR_STOP on
begin;
insert into auth.users(id) values('11111111-1111-1111-1111-111111111111'),('22222222-2222-2222-2222-222222222222'),('33333333-3333-3333-3333-333333333333');
insert into public.cn_profiles(id,display_name) values('11111111-1111-1111-1111-111111111111','Owner');
insert into public.cn_moderators values('33333333-3333-3333-3333-333333333333');
select public.cn_reserve_photo('11111111-1111-1111-1111-111111111111','aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa',repeat('a',64),'Photo');
select public.cn_finish_photo('11111111-1111-1111-1111-111111111111','aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa',100,100,1000);
set local role authenticated;
select set_config('request.jwt.claim.sub','22222222-2222-2222-2222-222222222222',true);
do $$ declare target uuid; begin
 select id into target from public.cn_posts limit 1;
 delete from public.cn_posts where id=target;
 if not exists(select 1 from public.cn_posts where id=target) then raise exception 'FAIL foreign deletion'; end if;
 perform public.cn_report_post(target,'Spam');
 begin
  perform public.cn_moderation_queue();
  raise exception 'FAIL unauthorized moderation';
 exception when insufficient_privilege then null; end;
 begin
  insert into public.cn_moderators values(auth.uid());
  raise exception 'FAIL moderator self assignment';
 exception when insufficient_privilege then null; end;
 begin
  perform public.cn_claim_media_cleanup();
  raise exception 'FAIL unauthorized cleanup';
 exception when insufficient_privilege then null; end;
end $$;
select set_config('request.jwt.claim.sub','33333333-3333-3333-3333-333333333333',true);
do $$ declare report uuid; begin
 select id into report from public.cn_moderation_queue() limit 1;
 if report is null then raise exception 'FAIL queue empty'; end if;
 perform public.cn_review_report(report,'removed','Scam confirmed');
 begin
  perform public.cn_review_report(report,'removed','Repeat');
  raise exception 'FAIL repeat review';
 exception when invalid_parameter_value then null; end;
end $$;
reset role;
do $$ begin
 if (select count(*) from public.cn_posts)<>0 then raise exception 'FAIL post retained'; end if;
 if (select count(*) from public.cn_media_cleanup)<>1 then raise exception 'FAIL image lost from cleanup'; end if;
 if (select state from public.cn_photo_requests limit 1)<>'deleted' then raise exception 'FAIL request not retired'; end if;
 begin
  perform public.cn_reserve_photo('11111111-1111-1111-1111-111111111111','aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa',repeat('a',64),'Photo');
  raise exception 'FAIL deleted replay';
 exception when invalid_parameter_value then null; end;
 begin
  perform public.cn_finish_photo('11111111-1111-1111-1111-111111111111','aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa',100,100,1000);
  raise exception 'FAIL deleted finalization';
 exception when invalid_parameter_value then null; end;
 if (select count(*) from public.cn_claim_media_cleanup())<>0 then raise exception 'FAIL grace period'; end if;
end $$;
update public.cn_media_cleanup set available_at=now()-interval '1 minute';
do $$ declare job record; begin
 select * into job from public.cn_claim_media_cleanup();
 if job.id is null then raise exception 'FAIL claim'; end if;
 if (select count(*) from public.cn_claim_media_cleanup())<>0 then raise exception 'FAIL overlapping lease'; end if;
 perform public.cn_finish_media_cleanup(job.id,gen_random_uuid(),true);
 if exists(select 1 from public.cn_media_cleanup where completed_at is not null) then raise exception 'FAIL stale lease'; end if;
 perform public.cn_finish_media_cleanup(job.id,job.lease_token,false);
 if exists(select 1 from public.cn_media_cleanup where completed_at is not null) then raise exception 'FAIL failed cleanup lost'; end if;
 update public.cn_media_cleanup set available_at=now()-interval '1 minute';
 select * into job from public.cn_claim_media_cleanup();
 perform public.cn_finish_media_cleanup(job.id,job.lease_token,true);
 if not exists(select 1 from public.cn_media_cleanup where completed_at is not null and attempts=2) then raise exception 'FAIL retry completion'; end if;
end $$;
-- Cascaded account deletion preserves queued paths even for unfinished uploads.
select public.cn_reserve_photo('11111111-1111-1111-1111-111111111111','bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb',repeat('b',64),'Unfinished');
delete from auth.users where id='11111111-1111-1111-1111-111111111111';
do $$ begin
 if (select count(*) from public.cn_media_cleanup)<>2 then raise exception 'FAIL cascaded cleanup lost'; end if;
 if (select count(*) from public.cn_moderation_actions)<>1 then raise exception 'FAIL audit lost'; end if;
 if (select website_marker from public.posts limit 1)<>'website-unchanged' then raise exception 'FAIL website changed'; end if;
end $$;
rollback;
