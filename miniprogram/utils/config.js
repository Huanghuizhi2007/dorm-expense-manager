// Supabase 配置。anon key 可以公开，service role key 绝不能写在这里。
module.exports = {
  SUPABASE_URL: 'https://vjvmtlijqhprhxjglqxf.supabase.co',
  SUPABASE_ANON_KEY: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InZqdm10bGlqcWhwcmh4amdscXhmIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODc0NTkxMzYsImV4cCI6MjEwMzAzNTEzNn0.B1cd3iX6f4TNVUzAdW8qZY9g1FReZeYZdQp224F5CHA',
  WECHAT_LOGIN_URL: 'https://vjvmtlijqhprhxjglqxf.supabase.co/functions/v1/wechat-login',
  CATEGORIES: ['食品', '日用品', '电费', '水费', '网络费', '维修费', '其他']
};
