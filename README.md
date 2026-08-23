# 宿舍账本 DormBill

一个接近真实产品的多人共享宿舍公共支出管理 App。宿舍成员共用一个云端数据库，任何成员添加、修改、删除支出后，其他成员会在手机上实时看到；月底自动生成每人应承担金额和谁该给谁多少的结算方案。

技术栈：Flutter（Android 优先）+ Supabase（免费云数据库、账号认证、实时同步、行级权限）。

## 一、功能清单

- 注册、登录、用户名和头像
- 创建宿舍群组、通过 8 位邀请码加入宿舍
- 宿舍成员共同维护支出记录：名称、金额、分类、时间、付款人、添加人
- 任意成员可以添加、编辑、删除支出
- 按月份浏览、按关键词搜索、按分类筛选
- 首页显示宿舍名、本月消费、成员数量、最近支出
- 统计页显示总消费、人均、成员消费排行、个人已付/应承担/差额
- 自动结算：每人应承担金额、应收/应付差额、最少转账方案
- 深色模式、离线缓存、Supabase Realtime 实时同步

## 二、项目文件结构

```text
dormbill/
├─ android/                          # Android 工程
│  └─ app/src/main/kotlin/...        # MainActivity
├─ lib/
│  ├─ main.dart                      # 应用入口
│  ├─ app.dart                       # Provider + MaterialApp
│  ├─ core/
│  │  ├─ app_config.dart             # Supabase URL / anon key 构建参数
│  │  ├─ app_constants.dart          # 分类、金额、日期、头像工具
│  │  ├─ app_theme.dart              # 浅色/深色主题
│  │  └─ settlement_calculator.dart  # 自动结算与转账算法
│  ├─ data/
│  │  ├─ supabase_service.dart       # Supabase 客户端
│  │  ├─ cache_service.dart          # SharedPreferences 离线缓存
│  │  ├─ models/                     # 用户、宿舍、成员、支出、结算模型
│  │  └─ repositories/               # 账号、宿舍、支出、结算数据仓库
│  ├─ state/
│  │  ├─ auth_controller.dart        # 登录状态
│  │  ├─ dorm_controller.dart        # 宿舍、成员、支出、实时同步状态
│  │  └─ theme_controller.dart       # 深色模式
│  └─ ui/
│     ├─ auth/                       # 登录、注册
│     ├─ home/                       # 首页、宿舍创建/加入、底部导航
│     ├─ expenses/                   # 账单列表、支出编辑
│     ├─ stats/                      # 统计、结算单
│     ├─ profile/                    # 个人资料、宿舍切换、退出
│     └─ widgets/                    # 通用卡片、头像、空状态
├─ supabase/
│  └─ schema.sql                     # 完整数据库、RLS 权限、结算函数
├─ scripts/
│  ├─ build_apk.bat                  # Windows 一键打包
│  └─ build_apk.sh                   # macOS/Linux 一键打包
├─ .github/workflows/build-apk.yml   # GitHub 云端自动打包
└─ pubspec.yaml
```

## 三、数据库结构

所有 SQL 在 `supabase/schema.sql` 中，包含建表、索引、触发器、行级安全（RLS）和结算函数。

### profiles（用户资料）

| 字段 | 类型 | 说明 |
| --- | --- | --- |
| id | uuid | 对应 Supabase `auth.users.id` |
| username | text | 用户名 |
| avatar_url | text | 可选头像 URL |
| created_at | timestamptz | 注册时间 |

### dormitories（宿舍）

| 字段 | 类型 | 说明 |
| --- | --- | --- |
| id | uuid | 宿舍 ID |
| name | text | 宿舍名称 |
| creator_id | uuid | 创建人 |
| invite_code | text | 8 位邀请码 |
| created_at | timestamptz | 创建时间 |

### members（成员）

| 字段 | 类型 | 说明 |
| --- | --- | --- |
| id | uuid | 成员记录 ID |
| dormitory_id | uuid | 宿舍 |
| user_id | uuid | 用户 |
| role | text | `creator` 或 `member` |
| joined_at | timestamptz | 加入时间 |

`dormitory_id + user_id` 唯一，防止重复加入。

### expenses（支出）

| 字段 | 类型 | 说明 |
| --- | --- | --- |
| id | uuid | 支出 ID |
| dormitory_id | uuid | 所属宿舍 |
| title | text | 支出名称 |
| amount | numeric(12,2) | 金额 |
| category | text | 食品/日用品/电费/水费/网络费/维修费/其他 |
| payer_id | uuid | 代付人 |
| creator_id | uuid | 添加人 |
| created_at | timestamptz | 支出时间 |
| updated_at | timestamptz | 修改时间 |

### settlements（每月结算）

| 字段 | 类型 | 说明 |
| --- | --- | --- |
| id | uuid | 结算 ID |
| dormitory_id | uuid | 宿舍 |
| month | text | `YYYY-MM` |
| user_id | uuid | 成员 |
| paid_amount | numeric(12,2) | 已支付 |
| share_amount | numeric(12,2) | 应承担 |
| balance | numeric(12,2) | 差额，正数为应收 |
| created_at / updated_at | timestamptz | 时间 |

`dormitory_id + month + user_id` 唯一，同一月份重复生成时自动覆盖。

### 权限规则

- 只有宿舍成员能查看该宿舍的成员、支出和结算。
- 创建宿舍后创建人自动成为成员。
- 加入宿舍只能通过 `join_dormitory` 函数和邀请码，不能猜测宿舍 ID 加入。
- 任意宿舍成员可以添加、修改、删除支出。
- 用户只能修改自己的用户名和头像。
- 结算写入只能由 `generate_monthly_settlements` 函数完成，普通客户端不能直接改结算表。

## 四、后端配置说明

1. 打开 [supabase.com](https://supabase.com) 注册并创建免费项目。
2. 进入项目，左侧菜单打开 **SQL Editor**。
3. 复制 `supabase/schema.sql` 的全部内容，粘贴后点击 **Run**。
4. 打开 **Project Settings -> API**，复制 `Project URL` 和 `anon public key`。
5. 建议在 **Authentication -> Providers -> Email** 中关闭 “Confirm email”（仅用于测试）；正式发布建议开启邮箱验证。

App 不会在代码里硬编码数据库密钥。打包时通过两个构建参数传入：

```text
SUPABASE_URL
SUPABASE_ANON_KEY
```

## 五、Android APK 打包方法

### 方法 A：本机打包

前置条件：

- Flutter SDK（stable）
- Android Studio 或 Android SDK
- 可用的 Java 17

打开终端进入项目目录，先让 Flutter 生成缺失的 Gradle wrapper：

```bat
flutter create --platforms=android --org com.dormbill --project-name dormbill .
flutter pub get
```

然后打包：

```bat
set SUPABASE_URL=https://你的项目.supabase.co
set SUPABASE_ANON_KEY=你的anon_key
flutter build apk --release --dart-define=SUPABASE_URL=%SUPABASE_URL% --dart-define=SUPABASE_ANON_KEY=%SUPABASE_ANON_KEY%
```

也可以直接运行：

```bat
scripts\build_apk.bat
```

输出文件：

```text
build/app/outputs/flutter-apk/app-release.apk
```

### 方法 B：GitHub 云端打包（不需要本机安装 Flutter）

1. 把本项目推送到 GitHub 仓库。
2. 在仓库 **Settings -> Secrets and variables -> Actions** 添加：
   - `SUPABASE_URL`
   - `SUPABASE_ANON_KEY`
3. 打开 **Actions**，运行 `Build Android APK` 工作流。
4. 构建完成后，在运行记录中下载 `dormbill-release-apk` 产物。

每次推送到 `main`/`master` 也会自动触发构建。构建参数写入 `.github/workflows/build-apk.yml`，云端自动执行 `flutter create` 补齐平台文件。

## 六、如何发布到手机

### 直接安装

1. 把 `app-release.apk` 发送到手机（微信文件传输助手、网盘、USB 拷贝等均可）。
2. 在手机上打开 APK 文件，允许“安装未知来源应用”。
3. 完成安装后打开“宿舍账本”。

### adb 安装

手机开启开发者模式并连接电脑后：

```bat
adb install -r build\app\outputs\flutter-apk\app-release.apk
```

正式上架应用商店时，建议替换 `android/app/build.gradle` 中的 debug 签名，使用自己的 release 签名并生成 `.aab`。

## 七、测试账号

由于每个 Supabase 项目都归属于用户本人，无法提供已经注册在某个云端项目里的通用测试账号。项目配置完成后，在 App 中按下面信息注册即可得到可直接使用的测试账号：

| 用户名 | 邮箱 | 密码 |
| --- | --- | --- |
| 张三 | demo1@dormapp.com | Dorm123456 |
| 李四 | demo2@dormapp.com | Dorm123456 |
| 王五 | demo3@dormapp.com | Dorm123456 |
| 赵六 | demo4@dormapp.com | Dorm123456 |

测试流程：

1. 用“张三”注册并登录，创建宿舍“测试宿舍”，记下邀请码。
2. 另外三个账号分别注册，通过邀请码加入同一宿舍。
3. 任意成员添加几笔支出，例如卫生纸、饮水机维修、公共零食。
4. 打开“统计”或“结算单”，查看自动均摊和转账方案。
5. 在另一台设备登录其他成员，验证修改和新增支出会实时同步。

如果关闭了邮箱确认，注册后会自动登录；如果开启邮箱确认，注册后先点击邮件中的验证链接再登录。

## 八、使用说明

### 注册登录

打开 App 后点击“注册新账号”，填写用户名、邮箱和密码。登录后进入宿舍创建或加入页面。

### 创建/加入宿舍

- 创建宿舍：输入宿舍名称，系统自动生成 8 位邀请码。
- 加入宿舍：输入舍友分享的邀请码。

邀请码可以在首页宿舍卡片上看到。

### 记录支出

首页或账单页点击“记一笔”，填写：

- 支出名称，例如“购买卫生纸”
- 金额，例如 `25.50`
- 分类：食品、日用品、电费、水费、网络费、维修费、其他
- 付款人：选择这次实际先付钱的成员
- 支出时间

添加后，其他成员的账单页会实时出现这条记录。

### 修改和删除

账单页任意支出卡片右上角菜单里有“编辑”和“删除”。任意宿舍成员都可以修改名称、金额、分类、付款人和时间，也可以删除错误记录。

### 搜索和月份

账单页顶部可以左右切换月份，也可以输入关键词搜索支出名称或付款人，还可以按分类筛选。

### 统计和结算

- 统计页显示本月总支出、人均、笔数、成员消费排行、个人已付/应承担/差额。
- 打开“结算单”可以看到谁应该给谁多少钱，以及每位成员的完整明细。
- 结算结果同时写入云端的 `settlements` 表，打开统计页时会自动生成并同步。

### 深色模式与离线缓存

“我的”页可以切换深色模式。最近一次宿舍、成员和支出会缓存在手机本地，网络断开时仍能查看上次数据，恢复网络后自动同步。

## 九、后续可扩展

- iOS：在已安装 Xcode 的电脑执行 `flutter create --platforms=ios --org com.dormbill .`。
- 头像上传：可接入 Supabase Storage，把图片 URL 写入 `avatar_url`。
- 结算提醒：可接入 FCM 推送或 App 内通知。
- 宿舍规则：可扩展“按人头/按房间/按入住天数”等均摊方式。

