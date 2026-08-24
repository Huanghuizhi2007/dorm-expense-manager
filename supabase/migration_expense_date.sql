-- 日历消费日期字段迁移：在 Supabase SQL Editor 中执行
alter table public.expenses
  add column if not exists expense_date date;

update public.expenses
set expense_date = (created_at at time zone 'UTC')::date
where expense_date is null;

alter table public.expenses
  alter column expense_date set default current_date;

alter table public.expenses
  alter column expense_date set not null;

