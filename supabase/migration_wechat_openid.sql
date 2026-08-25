-- 微信一键登录需要：profiles 增加 wechat_openid 字段（可选）
alter table public.profiles
  add column if not exists wechat_openid text unique;
