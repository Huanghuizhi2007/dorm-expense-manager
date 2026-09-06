-- ============================================================
-- ourbills 宿舍值日排班
-- 在 Supabase Dashboard -> SQL Editor 中执行一次。
-- 依赖 schema.sql 中已有的 is_member()、set_updated_at()。
-- ============================================================

-- ------------------------------------------------------------
-- 值日规则：每个宿舍最多一条
-- member_order 保存排班成员顺序，按 user_id 排列
-- ------------------------------------------------------------
create table if not exists public.chore_rules (
  id uuid primary key default gen_random_uuid(),
  dormitory_id uuid not null references public.dormitories(id) on delete cascade,
  member_order jsonb not null default '[]'::jsonb,
  interval_days integer not null default 1
    check (interval_days >= 1 and interval_days <= 366),
  start_date date not null default current_date,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (dormitory_id)
);

-- ------------------------------------------------------------
-- 排班任务：每个宿舍每天一条，可自动生成或手动调整
-- ------------------------------------------------------------
create table if not exists public.chore_tasks (
  id uuid primary key default gen_random_uuid(),
  dormitory_id uuid not null references public.dormitories(id) on delete cascade,
  member_id uuid not null references auth.users(id) on delete cascade,
  task_date date not null,
  source text not null default 'auto' check (source in ('auto', 'manual')),
  status text not null default 'pending' check (status in ('pending', 'done')),
  completed_by uuid references auth.users(id),
  completed_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (dormitory_id, task_date)
);

create index if not exists chore_tasks_dorm_date_idx
  on public.chore_tasks (dormitory_id, task_date);

-- ------------------------------------------------------------
-- 值日完成记录：每次完成写入一条
-- ------------------------------------------------------------
create table if not exists public.chore_records (
  id uuid primary key default gen_random_uuid(),
  dormitory_id uuid not null references public.dormitories(id) on delete cascade,
  member_id uuid not null references auth.users(id) on delete cascade,
  task_date date not null,
  status text not null default 'done' check (status = 'done'),
  is_manual boolean not null default false,
  completed_by uuid not null references auth.users(id),
  completed_at timestamptz not null default now(),
  created_at timestamptz not null default now()
);

create index if not exists chore_records_dorm_date_idx
  on public.chore_records (dormitory_id, task_date);

-- ------------------------------------------------------------
-- 自动更新时间
-- ------------------------------------------------------------
drop trigger if exists chore_rules_set_updated_at on public.chore_rules;
create trigger chore_rules_set_updated_at
  before update on public.chore_rules
  for each row execute function public.set_updated_at();

drop trigger if exists chore_tasks_set_updated_at on public.chore_tasks;
create trigger chore_tasks_set_updated_at
  before update on public.chore_tasks
  for each row execute function public.set_updated_at();

-- ------------------------------------------------------------
-- 行级安全：仅宿舍成员可读写
-- ------------------------------------------------------------
alter table public.chore_rules enable row level security;
alter table public.chore_tasks enable row level security;
alter table public.chore_records enable row level security;

drop policy if exists "Members can view chore rules" on public.chore_rules;
create policy "Members can view chore rules"
  on public.chore_rules for select
  to authenticated
  using (public.is_member(dormitory_id));

drop policy if exists "Members can create chore rules" on public.chore_rules;
create policy "Members can create chore rules"
  on public.chore_rules for insert
  to authenticated
  with check (public.is_member(dormitory_id));

drop policy if exists "Members can update chore rules" on public.chore_rules;
create policy "Members can update chore rules"
  on public.chore_rules for update
  to authenticated
  using (public.is_member(dormitory_id))
  with check (public.is_member(dormitory_id));

drop policy if exists "Members can delete chore rules" on public.chore_rules;
create policy "Members can delete chore rules"
  on public.chore_rules for delete
  to authenticated
  using (public.is_member(dormitory_id));

drop policy if exists "Members can view chore tasks" on public.chore_tasks;
create policy "Members can view chore tasks"
  on public.chore_tasks for select
  to authenticated
  using (public.is_member(dormitory_id));

drop policy if exists "Members can create chore tasks" on public.chore_tasks;
create policy "Members can create chore tasks"
  on public.chore_tasks for insert
  to authenticated
  with check (
    public.is_member(dormitory_id)
    and exists (
      select 1 from public.members m
      where m.dormitory_id = chore_tasks.dormitory_id
        and m.user_id = chore_tasks.member_id
    )
  );

drop policy if exists "Members can update chore tasks" on public.chore_tasks;
create policy "Members can update chore tasks"
  on public.chore_tasks for update
  to authenticated
  using (public.is_member(dormitory_id))
  with check (
    public.is_member(dormitory_id)
    and exists (
      select 1 from public.members m
      where m.dormitory_id = chore_tasks.dormitory_id
        and m.user_id = chore_tasks.member_id
    )
  );

drop policy if exists "Members can delete chore tasks" on public.chore_tasks;
create policy "Members can delete chore tasks"
  on public.chore_tasks for delete
  to authenticated
  using (public.is_member(dormitory_id));

drop policy if exists "Members can view chore records" on public.chore_records;
create policy "Members can view chore records"
  on public.chore_records for select
  to authenticated
  using (public.is_member(dormitory_id));

drop policy if exists "Members can create chore records" on public.chore_records;
create policy "Members can create chore records"
  on public.chore_records for insert
  to authenticated
  with check (
    public.is_member(dormitory_id)
    and completed_by = auth.uid()
    and exists (
      select 1 from public.members m
      where m.dormitory_id = chore_records.dormitory_id
        and m.user_id = chore_records.member_id
    )
  );

drop policy if exists "Members can update chore records" on public.chore_records;
create policy "Members can update chore records"
  on public.chore_records for update
  to authenticated
  using (public.is_member(dormitory_id))
  with check (public.is_member(dormitory_id));

drop policy if exists "Members can delete chore records" on public.chore_records;
create policy "Members can delete chore records"
  on public.chore_records for delete
  to authenticated
  using (public.is_member(dormitory_id));

-- 匿名用户无权限，客户端写入仍由 RLS 控制
revoke all on table public.chore_rules from anon, authenticated;
revoke all on table public.chore_tasks from anon, authenticated;
revoke all on table public.chore_records from anon, authenticated;

grant select, insert, update, delete on table public.chore_rules to authenticated;
grant select, insert, update, delete on table public.chore_tasks to authenticated;
grant select, insert, update, delete on table public.chore_records to authenticated;
