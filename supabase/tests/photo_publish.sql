\set ON_ERROR_STOP on
begin;
insert into auth.users(id) values('11111111-1111-1111-1111-111111111111');
insert into public.cn_profiles(id,display_name) values('11111111-1111-1111-1111-111111111111','Test photographer');
set local role authenticated;
select set_config('request.jwt.claim.sub','11111111-1111-1111-1111-111111111111',true);
do $$ begin
 begin
  perform public.cn_reserve_photo(auth.uid(),gen_random_uuid(),repeat('a',64),'caption');
  raise exception 'FAIL: client called privileged reservation';
 exception when insufficient_privilege then null; end;
 begin
  perform public.cn_finish_photo(auth.uid(),gen_random_uuid(),10,10,100);
  raise exception 'FAIL: client called publisher';
 exception when insufficient_privilege then null; end;
 begin
  insert into storage.objects(bucket_id,name) values('cn-media','fake.jpg');
  raise exception 'FAIL: client bypassed media validator';
 exception when insufficient_privilege then null; end;
 -- The restrictive media policy must not block website buckets.
 insert into storage.objects(bucket_id,name) values('website-fixture','okay.jpg');
end $$;
reset role;
set local role service_role;
select public.cn_reserve_photo('11111111-1111-1111-1111-111111111111','aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa',repeat('a',64),'My first photo');
select public.cn_finish_photo('11111111-1111-1111-1111-111111111111','aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa',800,600,100000);
do $$ declare first_id uuid; retry_id uuid; i integer; begin
 select post_id into first_id from public.cn_photo_requests where request_id='aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa';
 retry_id:=public.cn_finish_photo('11111111-1111-1111-1111-111111111111','aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa',800,600,100000);
 if first_id<>retry_id or (select count(*) from public.cn_posts)<>1 then raise exception 'FAIL: duplicated retry'; end if;
 begin
  perform public.cn_reserve_photo('11111111-1111-1111-1111-111111111111','aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa',repeat('b',64),'My first photo');
  raise exception 'FAIL: mismatched retry';
 exception when invalid_parameter_value then null; end;
 for i in 1..4 loop
  perform public.cn_reserve_photo('11111111-1111-1111-1111-111111111111',gen_random_uuid(),repeat('c',64),'Another photo');
 end loop;
 begin
  perform public.cn_reserve_photo('11111111-1111-1111-1111-111111111111',gen_random_uuid(),repeat('d',64),'Over quota');
  raise exception 'FAIL: exceeded quota' using errcode='XX000';
 exception when raise_exception then null; end;
end $$;
reset role;
set local role anon;
do $$ begin
 if (select count(*) from public.cn_feed(false))<>1 then raise exception 'FAIL: published photo not visible'; end if;
 if (select jsonb_array_length(images) from public.cn_feed(false) limit 1)<>1 then raise exception 'FAIL: image metadata missing'; end if;
end $$;
reset role;
rollback;
