-- ============================================================
-- 宿舍账本 DormBill
-- Supabase SQL 初始化脚本
-- 在 Supabase Dashboard -> SQL Editor 中整体执行一次即可。
-- ============================================================

create extension if not exists pgcrypto;

-- ------------------------------------------------------------
-- 用户资料
-- 说明：Supabase 自带 auth.users，因此自定义用户资料表命名为 profiles。
-- ------------------------------------------------------------
create table if not exists public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  username text not null,
  avatar_url text,
  created_at timestamptz not null default now()
);

-- ------------------------------------------------------------
-- 宿舍群组
-- ------------------------------------------------------------
create table if not exists public.dormitories (
  id uuid primary key default gen_random_uuid(),
  name text not null check (char_length(trim(name)) between 1 and 40),
  creator_id uuid not null references auth.users(id) on delete cascade,
  invite_code text not null unique,
  created_at timestamptz not null default now()
);

-- ------------------------------------------------------------
-- 宿舍成员
-- ------------------------------------------------------------
create table if not exists public.members (
  id uuid primary key default gen_random_uuid(),
  dormitory_id uuid not null references public.dormitories(id) on delete cascade,
  user_id uuid not null references auth.users(id) on delete cascade,
  role text not null default 'member' check (role in ('creator', 'member')),
  joined_at timestamptz not null default now(),
  unique (dormitory_id, user_id)
);

-- ------------------------------------------------------------
-- 支出记录
-- ------------------------------------------------------------
create table if not exists public.expenses (
  id uuid primary key default gen_random_uuid(),
  dormitory_id uuid not null references public.dormitories(id) on delete cascade,
  title text not null check (char_length(trim(title)) between 1 and 80),
  amount numeric(12, 2) not null check (amount >= 0),
  category text not null default '其他'
    check (category in ('食品', '日用品', '电费', '水费', '网络费', '维修费', '其他')),
  payer_id uuid not null references auth.users(id) on delete restrict,
  creator_id uuid not null references auth.users(id) on delete restrict,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists expenses_dormitory_created_idx
  on public.expenses (dormitory_id, created_at desc);

-- 开启支出表实时同步
do $$
begin
  alter publication supabase_realtime add table public.expenses;
exception
  when duplicate_object then null;
end;
$$;

-- ------------------------------------------------------------
-- 每月结算结果
-- month 使用 'YYYY-MM' 文本格式，例如 '2026-08'。
-- ------------------------------------------------------------
create table if not exists public.settlements (
  id uuid primary key default gen_random_uuid(),
  dormitory_id uuid not null references public.dormitories(id) on delete cascade,
  month text not null check (month ~ '^[0-9]{4}-[0-9]{2}$'),
  user_id uuid not null references auth.users(id) on delete cascade,
  paid_amount numeric(12, 2) not null default 0,
  share_amount numeric(12, 2) not null default 0,
  balance numeric(12, 2) not null default 0,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (dormitory_id, month, user_id)
);

-- ------------------------------------------------------------
-- 注册时自动创建用户资料
-- ------------------------------------------------------------
create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  insert into public.profiles (id, username, avatar_url)
  values (
    new.id,
    coalesce(nullif(trim(new.raw_user_meta_data ->> 'username'), ''), split_part(new.email, '@', 1)),
    null
  )
  on conflict (id) do update
    set username = excluded.username;
  return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();

-- ------------------------------------------------------------
-- 更新时间触发器
-- ------------------------------------------------------------
create or replace function public.set_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

drop trigger if exists expenses_set_updated_at on public.expenses;
create trigger expenses_set_updated_at
  before update on public.expenses
  for each row execute function public.set_updated_at();

drop trigger if exists settlements_set_updated_at on public.settlements;
create trigger settlements_set_updated_at
  before update on public.settlements
  for each row execute function public.set_updated_at();

-- ------------------------------------------------------------
-- 行级安全（RLS）
-- ------------------------------------------------------------
alter table public.profiles enable row level security;
alter table public.dormitories enable row level security;
alter table public.members enable row level security;
alter table public.expenses enable row level security;
alter table public.settlements enable row level security;

-- 统一的成员判断函数，避免 RLS 策略中自引用递归
create or replace function public.is_member(p_dormitory_id uuid)
returns boolean
language sql
security definer
set search_path = public
stable
as $$
  select exists (
    select 1
    from public.members
    where dormitory_id = p_dormitory_id
      and user_id = auth.uid()
  );
$$;

revoke all on function public.is_member(uuid) from anon, public;
grant execute on function public.is_member(uuid) to authenticated;

-- 创建人判断函数，供创建宿舍后自动加入成员时使用
create or replace function public.is_creator(p_dormitory_id uuid)
returns boolean
language sql
security definer
set search_path = public
stable
as $$
  select exists (
    select 1
    from public.dormitories
    where id = p_dormitory_id
      and creator_id = auth.uid()
  );
$$;

revoke all on function public.is_creator(uuid) from anon, public;
grant execute on function public.is_creator(uuid) to authenticated;

-- profiles
create policy "Profiles are readable by authenticated users"
  on public.profiles for select
  to authenticated
  using (true);

create policy "Users can update their own profile"
  on public.profiles for update
  to authenticated
  using (auth.uid() = id)
  with check (auth.uid() = id);

-- dormitories
create policy "Dormitories are readable by members"
  on public.dormitories for select
  to authenticated
  using (creator_id = auth.uid() or public.is_member(id));

create policy "Users can create dormitories"
  on public.dormitories for insert
  to authenticated
  with check (creator_id = auth.uid());

create policy "Members can update dormitory"
  on public.dormitories for update
  to authenticated
  using (public.is_member(id) or creator_id = auth.uid())
  with check (public.is_member(id) or creator_id = auth.uid());

-- members
create policy "Members can view dorm members"
  on public.members for select
  to authenticated
  using (public.is_member(dormitory_id));

create policy "Creator can add themselves as member"
  on public.members for insert
  to authenticated
  with check (
    user_id = auth.uid()
    and public.is_creator(dormitory_id)
  );

create policy "Members can delete themselves"
  on public.members for delete
  to authenticated
  using (user_id = auth.uid());

-- expenses
create policy "Members can view expenses"
  on public.expenses for select
  to authenticated
  using (public.is_member(dormitory_id));

create policy "Members can add expenses"
  on public.expenses for insert
  to authenticated
  with check (
    creator_id = auth.uid()
    and public.is_member(dormitory_id)
    and exists (
      select 1 from public.members m2
      where m2.dormitory_id = public.expenses.dormitory_id
        and m2.user_id = public.expenses.payer_id
    )
  );

create policy "Members can update expenses"
  on public.expenses for update
  to authenticated
  using (public.is_member(dormitory_id))
  with check (
    public.is_member(dormitory_id)
    and exists (
      select 1 from public.members m2
      where m2.dormitory_id = public.expenses.dormitory_id
        and m2.user_id = public.expenses.payer_id
    )
  );

create policy "Members can delete expenses"
  on public.expenses for delete
  to authenticated
  using (public.is_member(dormitory_id));

-- settlements：普通用户只能读，写入由 security definer 函数完成。
create policy "Members can view settlements"
  on public.settlements for select
  to authenticated
  using (public.is_member(dormitory_id));

-- ------------------------------------------------------------
-- 通过邀请码加入宿舍（security definer，防止任意猜测宿舍 ID）
-- ------------------------------------------------------------
create or replace function public.join_dormitory(p_invite_code text)
returns table (
  id uuid,
  name text,
  invite_code text,
  created_at timestamptz
)
language plpgsql
security definer
set search_path = public
as $$
declare
  v_dorm record;
begin
  select d.id, d.name, d.invite_code, d.created_at
    into v_dorm
    from public.dormitories d
   where upper(d.invite_code) = upper(p_invite_code)
   limit 1;

  if not found then
    raise exception 'INVITE_NOT_FOUND';
  end if;

  insert into public.members (dormitory_id, user_id, role)
  values (v_dorm.id, auth.uid(), 'member')
  on conflict (dormitory_id, user_id) do nothing;

  return query
    select v_dorm.id, v_dorm.name, v_dorm.invite_code, v_dorm.created_at;
end;
$$;

-- ------------------------------------------------------------
-- 删除宿舍（仅创建者，security definer 保证级联删除成员、支出、结算）
-- ------------------------------------------------------------
create or replace function public.delete_dormitory(p_dormitory_id uuid)
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  if not exists (
    select 1
    from public.dormitories
    where id = p_dormitory_id
      and creator_id = auth.uid()
  ) then
    raise exception 'NOT_DORMITORY_CREATOR';
  end if;

  delete from public.dormitories
  where id = p_dormitory_id;
end;
$$;

-- ------------------------------------------------------------
-- 自动生成某月结算
-- 结果写入 settlements，同时返回本宿舍每位成员的明细。
-- ------------------------------------------------------------
create or replace function public.generate_monthly_settlements(
  p_dormitory_id uuid,
  p_month text
)
returns table (
  user_id uuid,
  username text,
  paid numeric,
  share numeric,
  balance numeric
)
language plpgsql
security definer
set search_path = public
as $$
declare
  v_start date;
  v_end date;
  v_total numeric := 0;
  v_count integer := 0;
  v_share_base numeric := 0;
  v_remainder integer := 0;
  v_index integer := 0;
  v_share numeric := 0;
  v_member record;
begin
  if not exists (
    select 1 from public.members
    where dormitory_id = p_dormitory_id
      and user_id = auth.uid()
  ) then
    raise exception 'NOT_A_MEMBER';
  end if;

  v_start := to_date(p_month, 'YYYY-MM');
  v_end := (v_start + interval '1 month')::date;

  select coalesce(sum(amount), 0)
    into v_total
    from public.expenses
   where dormitory_id = p_dormitory_id
     and created_at >= v_start
     and created_at < v_end;

  select count(*) into v_count
    from public.members
   where dormitory_id = p_dormitory_id;

  if v_count > 0 then
    -- 按分精确分配，余数分给前几名成员，保证每人均摊之和等于总支出。
    v_share_base := floor((v_total / v_count) * 100) / 100;
    v_remainder := (v_total * 100)::integer - (v_share_base * v_count * 100)::integer;
  end if;

  for v_member in
    select m.user_id,
           p.username,
           coalesce(sum(e.amount) filter (
             where e.payer_id = m.user_id
           ), 0) as paid
      from public.members m
      join public.profiles p on p.id = m.user_id
      left join public.expenses e
        on e.dormitory_id = m.dormitory_id
       and e.payer_id = m.user_id
       and e.created_at >= v_start
       and e.created_at < v_end
     where m.dormitory_id = p_dormitory_id
     group by m.user_id, p.username
     order by m.user_id
  loop
    v_index := v_index + 1;
    v_share := v_share_base
      + case when v_index <= v_remainder then 0.01 else 0 end;

    insert into public.settlements (
      dormitory_id, month, user_id, paid_amount, share_amount, balance
    ) values (
      p_dormitory_id, p_month, v_member.user_id,
      v_member.paid, v_share, v_member.paid - v_share
    )
    on conflict (dormitory_id, month, user_id)
    do update set
      paid_amount = excluded.paid_amount,
      share_amount = excluded.share_amount,
      balance = excluded.balance,
      updated_at = now();

    return query
      select v_member.user_id, v_member.username,
             v_member.paid, v_share, v_member.paid - v_share;
  end loop;
end;
$$;

-- ------------------------------------------------------------
-- 权限收紧
-- ------------------------------------------------------------
revoke all on table public.settlements from anon;
revoke all on table public.settlements from authenticated;
grant select on table public.settlements to authenticated;

revoke all on function public.join_dormitory(text) from anon, public;
revoke all on function public.generate_monthly_settlements(uuid, text) from anon, public;
revoke all on function public.delete_dormitory(uuid) from anon, public;
grant execute on function public.join_dormitory(text) to authenticated;
grant execute on function public.generate_monthly_settlements(uuid, text) to authenticated;
grant execute on function public.delete_dormitory(uuid) to authenticated;

revoke all on function public.handle_new_user() from public;
revoke all on function public.set_updated_at() from public;

-- ------------------------------------------------------------
-- 头像云存储
-- ------------------------------------------------------------
insert into storage.buckets (id, name, public)
values ('avatars', 'avatars', true)
on conflict (id) do update set public = true;

drop policy if exists "Avatar public read" on storage.objects;
create policy "Avatar public read"
  on storage.objects for select
  to public
  using (bucket_id = 'avatars');

drop policy if exists "Avatar owner upload" on storage.objects;
create policy "Avatar owner upload"
  on storage.objects for insert
  to authenticated
  with check (
    bucket_id = 'avatars'
    and (storage.foldername(name))[1] = auth.uid()::text
  );

drop policy if exists "Avatar owner update" on storage.objects;
create policy "Avatar owner update"
  on storage.objects for update
  to authenticated
  using (
    bucket_id = 'avatars'
    and (storage.foldername(name))[1] = auth.uid()::text
  )
  with check (
    bucket_id = 'avatars'
    and (storage.foldername(name))[1] = auth.uid()::text
  );

drop policy if exists "Avatar owner delete" on storage.objects;
create policy "Avatar owner delete"
  on storage.objects for delete
  to authenticated
  using (
    bucket_id = 'avatars'
    and (storage.foldername(name))[1] = auth.uid()::text
  );
