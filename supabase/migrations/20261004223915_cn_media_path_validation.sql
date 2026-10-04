-- Correct hosted schema escaping without changing website tables.
begin;
alter table public.cn_post_media drop constraint cn_post_media_storage_path_check;
alter table public.cn_post_media add constraint cn_post_media_storage_path_check
  check (storage_path ~ '^[a-zA-Z0-9/_-]+[.](webp|jpg)$');
commit;
