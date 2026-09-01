-- ============================================================
-- ourbills 云端更新服务
-- 在 Supabase Dashboard -> SQL Editor 中整体执行一次。
-- 执行后 App 会优先从本表读取最新版本，GitHub 作为备用。
-- ============================================================

create table if not exists public.app_releases (
  id uuid primary key default gen_random_uuid(),
  version text not null unique check (version ~ '^[0-9]+\.[0-9]+\.[0-9]+$'),
  url text not null,
  notes text,
  created_at timestamptz not null default now()
);

alter table public.app_releases enable row level security;

-- 版本信息是公开数据，所有用户都可以读取。
drop policy if exists "Public read app releases" on public.app_releases;
create policy "Public read app releases"
  on public.app_releases for select
  to anon, authenticated
  using (true);

-- 写入只通过 Supabase 后台或 service role 完成，客户端不能改。
revoke all on table public.app_releases from anon, authenticated;
grant select on table public.app_releases to anon, authenticated;

-- ------------------------------------------------------------
-- 公开 APK 存储桶
-- 上传 APK 后，公开下载地址为：
-- {SUPABASE_URL}/storage/v1/object/public/releases/ourbills-v1.0.12.apk
-- ------------------------------------------------------------
insert into storage.buckets (id, name, public)
values ('releases', 'releases', true)
on conflict (id) do update set public = true;

drop policy if exists "Release public read" on storage.objects;
create policy "Release public read"
  on storage.objects for select
  to public
  using (bucket_id = 'releases');

-- ------------------------------------------------------------
-- 发布新版本示例（在 SQL Editor 中按需执行）
-- ------------------------------------------------------------
-- insert into public.app_releases (version, url, notes)
-- values (
--   '1.0.12',
--   'https://vjvmtlijqhprhxjglqxf.supabase.co/storage/v1/object/public/releases/ourbills-v1.0.12.apk',
--   '修复更新提示、优化统计页'
-- );
