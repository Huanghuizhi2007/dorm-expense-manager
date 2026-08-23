-- 删除宿舍功能：请在 Supabase SQL Editor 中执行这一段
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

revoke all on function public.delete_dormitory(uuid) from anon, public;
grant execute on function public.delete_dormitory(uuid) to authenticated;

