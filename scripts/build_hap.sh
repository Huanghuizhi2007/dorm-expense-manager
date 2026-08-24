#!/usr/bin/env bash
set -e

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

command -v flutter >/dev/null 2>&1 || {
  echo "没有找到 flutter 命令。请先安装鸿蒙版 Flutter SDK 并配置 PATH。"
  exit 1
}

: "${SUPABASE_URL:?请先设置 SUPABASE_URL}"
: "${SUPABASE_ANON_KEY:?请先设置 SUPABASE_ANON_KEY}"

OVERRIDE_SOURCE="$ROOT/scripts/ohos/pubspec_overrides.yaml"
OVERRIDE_TARGET="$ROOT/pubspec_overrides.yaml"

if [ -f "$OVERRIDE_TARGET" ]; then
  echo "项目根目录已存在 pubspec_overrides.yaml，请先移走后再执行。"
  exit 1
fi

cp "$OVERRIDE_SOURCE" "$OVERRIDE_TARGET"
trap 'rm -f "$OVERRIDE_TARGET"' EXIT

flutter pub get
flutter build hap --release \
  --dart-define=SUPABASE_URL="$SUPABASE_URL" \
  --dart-define=SUPABASE_ANON_KEY="$SUPABASE_ANON_KEY"

echo ""
echo "HAP 构建完成。请到 ohos/entry/build 或 build/ohos 下查找 signed/unsigned 包。"
