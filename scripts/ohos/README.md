# HarmonyOS 打包说明

ourbills 的 `ohos/` 工程已经配置为同时支持鸿蒙手机和鸿蒙电脑（`2in1`），并已声明网络权限。

打包前必须完成两件事：

1. 安装鸿蒙版 Flutter SDK：

```bash
git clone -b br_3.27.4-ohos-1.0.4 https://gitcode.com/openharmony-tpc/flutter_flutter.git
```

把 `flutter_flutter/bin` 加入 `PATH`，并用 DevEco Studio 5.1+ 的 Command Line Tools 配置 `DEVECO_SDK_HOME`。

2. 用 DevEco Studio 打开本目录，在 `File -> Project Structure -> Signing Configs` 中完成自动签名，或手动填写 `ohos/build-profile.json5` 的签名信息。

签名完成后，回到项目根目录执行：

Windows:

```bat
set SUPABASE_URL=https://你的项目.supabase.co
set SUPABASE_ANON_KEY=你的anon_key
scripts\build_hap.bat
```

macOS / Linux:

```bash
export SUPABASE_URL=https://你的项目.supabase.co
export SUPABASE_ANON_KEY=你的anon_key
./scripts/build_hap.sh
```

构建脚本会自动启用 `image_picker` 和 `shared_preferences` 的鸿蒙适配版本，结束后自动清理临时覆盖文件。

注意：DevEco Studio 自动签名生成的是调试证书，只能安装到绑定了该证书的测试设备。如果要把 App 发给其他鸿蒙电脑或上架华为应用市场，需要在 AppGallery Connect 申请正式签名。
