# ourbills 微信小程序

ourbills 微信小程序是 Android App 的独立客户端，两者共用同一个 Supabase 云数据库。小程序里注册的账号、创建的宿舍、添加的支出、生成的结算，Android App 都能看到；Android App 的数据也会同步到小程序。

## 一、项目目录结构

```text
miniprogram/
├─ app.js                     # 小程序入口，启动时恢复登录状态
├─ app.json                   # 页面路由与底部 Tab
├─ app.wxss                   # 全局样式（白色背景、圆角卡片、按钮）
├─ project.config.json        # 微信开发者工具项目配置
├─ sitemap.json
├─ pages/
│  ├─ login/                  # 登录（邮箱 + 微信一键登录入口）
│  ├─ register/               # 注册
│  ├─ home/                   # 首页：宿舍信息、本月支出、无限滚动账单
│  ├─ dorm-setup/             # 创建宿舍、邀请码加入、删除宿舍
│  ├─ add-expense/            # 添加 / 编辑支出
│  ├─ calendar/               # 月历：消费日期圆点、点击查看当天账单
│  ├─ stats/                  # 统计：总消费、分类环形图、排行、个人账单
│  ├─ settlement/             # 自动结算：每人应收/应付、最少转账方案
│  └─ profile/                # 我的：头像、昵称、宿舍切换、退出
└─ utils/
   ├─ config.js               # Supabase URL、anon key、分类常量
   ├─ supabase.js             # REST 请求封装、自动携带登录 token
   ├─ api.js                  # 账号、宿舍、支出、结算、头像上传接口
   ├─ format.js               # 金额、日期、分类样式
   ├─ settlement.js           # 最少转账算法
   └─ store.js                # 全局状态与本地会话缓存
```

后端扩展：

```text
supabase/
├─ functions/wechat-login/    # 微信一键登录 Edge Function（可选）
└─ migration_wechat_openid.sql # 微信登录需要的 profiles.wechat_openid 字段
```

## 二、运行方法

1. 安装并打开“微信开发者工具”（稳定版即可）。
2. 点击“导入项目”，选择本仓库下的 `miniprogram` 目录。
3. AppID 选择“测试号”或填写你自己的小程序 AppID（发布时必须使用真实 AppID）。
4. 点击“编译”即可运行。

当前 `project.config.json` 中 `appid` 为 `touristappid`，可在开发者工具里直接以游客模式预览。

## 三、后端配置

小程序已经写好当前 Supabase 的 URL 和 anon public key，位于 `miniprogram/utils/config.js`：

```js
module.exports = {
  SUPABASE_URL: 'https://vjvmtlijqhprhxjglqxf.supabase.co',
  SUPABASE_ANON_KEY: 'eyJ...',
  WECHAT_LOGIN_URL: 'https://vjvmtlijqhprhxjglqxf.supabase.co/functions/v1/wechat-login',
  CATEGORIES: ['食品', '日用品', '电费', '水费', '网络费', '维修费', '其他']
};
```

这些配置只包含公开的 anon key，可以随源码公开；绝不能把 service role key 写进小程序。

数据库使用现有 `supabase/schema.sql`，无需新建数据库。如果数据库缺少 `expense_date` 字段，请先在 Supabase SQL Editor 执行迁移：

```sql
alter table public.expenses
  add column if not exists expense_date date not null default current_date;
```

### 微信请求域名

发布前，在微信公众平台配置“服务器域名”中的 `request合法域名` 和 `uploadFile合法域名`：

```text
https://vjvmtlijqhprhxjglqxf.supabase.co
```

开发阶段如果使用游客模式，可以在开发者工具中勾选“不校验合法域名”。

## 四、微信一键登录（可选）

邮箱注册/登录开箱即用，和 Android App 共用同一套账号。微信一键登录需要额外配置：

1. 在微信公众平台注册小程序，拿到 AppID 和 AppSecret。
2. 在 Supabase Dashboard 的 Edge Functions 中部署 `supabase/functions/wechat-login`。
3. 为该函数配置环境变量：
   - `WECHAT_APP_ID`：小程序 AppID
   - `WECHAT_APP_SECRET`：小程序 AppSecret
   - `WECHAT_SIGN_IN_SECRET`：任意自定义密码盐
4. 在 Supabase SQL Editor 执行 `supabase/migration_wechat_openid.sql`。
5. 确认 Supabase 的 Edge Function 域名已在微信后台合法域名列表中。

启用后，登录页的“微信一键登录”会自动创建账号并登录；关闭邮箱验证可让新用户注册后直接进入。

## 五、发布步骤

1. 在微信公众平台完成小程序主体信息、服务类目和隐私协议配置。
2. 在微信开发者工具中上传代码。
3. 在微信公众平台提交审核。
4. 审核通过后发布。用户直接在微信中搜索或扫码打开小程序，不需要安装 APK。

发布前请确认：

- 使用真实 AppID，而不是 `touristappid`。
- 已配置 Supabase 合法请求域名。
- 已在“隐私保护指引”中说明会使用头像、相册和网络数据。

## 六、测试账号

不需要固定测试账号。小程序和 Android App 使用同一个 Supabase 用户系统，任选一种方式：

1. 在 Android App 注册后，用同一邮箱密码在小程序登录。
2. 在小程序直接注册新账号，再用该账号登录 Android App。

如需在开发阶段跳过邮箱验证，可以在 Supabase Authentication 设置中临时关闭 “Confirm email” 选项。

## 七、与 Android App 数据同步说明

| 数据 | 表 | 同步方式 |
| --- | --- | --- |
| 用户资料 | `profiles` | 同一 Supabase 账号，两端通用 |
| 宿舍 | `dormitories` | 创建者与成员共用 |
| 成员关系 | `members` | 两端实时可见 |
| 支出 | `expenses` | 小程序按分页拉取；Android 使用 Realtime 实时同步 |
| 结算 | `settlements` | 两端都调用同一个 `generate_monthly_settlements` 函数 |

关键约定：

- 添加支出时，小程序会同时写入 `expense_date`（用户选择的日期）和 `created_at`（同一天的 12:00），保证 Android 按 `created_at` 统计月份时结果一致。
- 结算函数按自然月计算，每个宿舍每月每名成员生成一条 `settlements` 记录。
- 数据权限由 Supabase RLS 控制：只有宿舍成员可以读取和修改本宿舍数据。

## 八、常见问题

### 网络连接失败

检查小程序后台是否配置了 Supabase 合法域名，或开发阶段是否勾选“不校验合法域名”。

### 邮箱验证后仍无法登录

请先到邮箱点击验证链接，再返回小程序登录。若确认已验证仍失败，检查 Supabase 是否关闭了邮箱验证。

### 创建宿舍提示 could not find relationship

数据库没有完整执行 `supabase/schema.sql`，或 `members`/`profiles` 的外键关系缺失。在 Supabase SQL Editor 重新执行一次完整脚本即可。
