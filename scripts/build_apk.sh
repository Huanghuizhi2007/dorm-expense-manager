#!/usr/bin/env sh
set -e

SUPABASE_URL="${SUPABASE_URL:-YOUR_PROJECT_URL}"
SUPABASE_ANON_KEY="${SUPABASE_ANON_KEY:-YOUR_ANON_KEY}"

if ! command -v flutter >/dev/null 2>&1; then
  echo "Flutter is not installed or not in PATH."
  exit 1
fi

if [ ! -f android/gradlew ]; then
  flutter create --platforms=android --org com.dormbill --project-name dormbill .
fi

flutter pub get
flutter build apk --release \
  --dart-define=SUPABASE_URL="$SUPABASE_URL" \
  --dart-define=SUPABASE_ANON_KEY="$SUPABASE_ANON_KEY"

echo "APK output: build/app/outputs/flutter-apk/app-release.apk"

