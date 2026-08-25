// 微信一键登录 Edge Function（可选）
// 启用步骤见 README-miniprogram.md：
// 1. 在 Supabase 创建 wechat-login 函数并部署本目录
// 2. 配置环境变量 WECHAT_APP_ID、WECHAT_APP_SECRET、WECHAT_SIGN_IN_SECRET
// 3. 执行 supabase/migration_wechat_openid.sql
// 4. 小程序登录页会调用 /functions/v1/wechat-login

import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';

type SupabaseClient = ReturnType<typeof createClient>;

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
  'Access-Control-Allow-Methods': 'POST, OPTIONS'
};

function json(data: unknown, status = 200) {
  return new Response(JSON.stringify(data), {
    status,
    headers: { ...corsHeaders, 'Content-Type': 'application/json' }
  });
}

async function sha256Hex(input: string) {
  const data = new TextEncoder().encode(input);
  const digest = await crypto.subtle.digest('SHA-256', data);
  return Array.from(new Uint8Array(digest))
    .map((byte) => byte.toString(16).padStart(2, '0'))
    .join('');
}

async function findOrCreateUser(
  supabase: SupabaseClient,
  openid: string,
  password: string
) {
  const { data: existing } = await supabase
    .from('profiles')
    .select('id')
    .eq('wechat_openid', openid)
    .maybeSingle();

  if (existing) {
    return existing.id;
  }

  const email = `wx_${openid.toLowerCase()}@ourbills.wechat`;
  const username = `微信用户${openid.slice(-4)}`;
  const { data: user, error: createError } = await supabase.auth.admin.createUser({
    email,
    password,
    email_confirm: true,
    user_metadata: { username, wechat_openid: openid }
  });
  if (createError) throw createError;

  const { error: updateError } = await supabase
    .from('profiles')
    .update({ wechat_openid: openid })
    .eq('id', user.user.id);
  if (updateError) throw updateError;

  return user.user.id;
}

Deno.serve(async (request: Request) => {
  if (request.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders });
  }
  if (request.method !== 'POST') {
    return json({ error: 'METHOD_NOT_ALLOWED' }, 405);
  }

  const appId = Deno.env.get('WECHAT_APP_ID');
  const appSecret = Deno.env.get('WECHAT_APP_SECRET');
  const signInSecret = Deno.env.get('WECHAT_SIGN_IN_SECRET');
  const supabaseUrl = Deno.env.get('SUPABASE_URL') || '';
  const serviceRoleKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') || '';

  if (!appId || !appSecret || !signInSecret) {
    return json({ error: 'WECHAT_NOT_CONFIGURED' }, 400);
  }

  const { code } = await request.json();
  if (!code) return json({ error: 'CODE_REQUIRED' }, 400);

  const wxUrl =
    `https://api.weixin.qq.com/sns/jscode2session?appid=${appId}` +
    `&secret=${appSecret}&js_code=${encodeURIComponent(code)}&grant_type=authorization_code`;
  const wxResponse = await fetch(wxUrl);
  const wxData = await wxResponse.json();

  if (!wxData.openid) {
    return json({ error: 'WECHAT_LOGIN_FAILED', detail: wxData.errmsg }, 400);
  }

  const password = await sha256Hex(`${wxData.openid}${signInSecret}`);

  try {
    const supabase = createClient(supabaseUrl, serviceRoleKey, {
      auth: { autoRefreshToken: false, persistSession: false }
    });
    await findOrCreateUser(supabase, wxData.openid, password);

    const anonClient = createClient(supabaseUrl, Deno.env.get('SUPABASE_ANON_KEY') || '', {
      auth: { autoRefreshToken: false, persistSession: false }
    });
    const { data: session, error: signInError } =
      await anonClient.auth.signInWithPassword({
        email: `wx_${wxData.openid.toLowerCase()}@ourbills.wechat`,
        password
      });
    if (signInError) throw signInError;

    return json({
      access_token: session.session.access_token,
      refresh_token: session.session.refresh_token,
      expires_in: session.session.expires_in,
      user: {
        id: session.user.id,
        email: session.user.email
      }
    });
  } catch (error) {
    console.error(error);
    return json({ error: 'INTERNAL_ERROR' }, 500);
  }
});
