begin;
-- Hosted grants had drifted from the source migrations. These operations require
-- an authenticated caller; their own identity/consent checks remain in force.
revoke all on function public.cn_request_conversation(uuid,uuid),public.cn_respond_conversation(uuid,boolean),public.cn_send_message(uuid,text,uuid) from public,anon;
grant execute on function public.cn_request_conversation(uuid,uuid),public.cn_respond_conversation(uuid,boolean),public.cn_send_message(uuid,text,uuid) to authenticated;
commit;
