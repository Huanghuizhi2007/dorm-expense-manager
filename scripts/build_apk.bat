@echo off
setlocal

if "%SUPABASE_URL%"=="" set SUPABASE_URL=YOUR_PROJECT_URL
if "%SUPABASE_ANON_KEY%"=="" set SUPABASE_ANON_KEY=YOUR_ANON_KEY

where flutter >nul 2>nul
if errorlevel 1 (
  echo Flutter is not installed or not in PATH.
  echo Install Flutter from https://docs.flutter.dev/get-started/install
  exit /b 1
)

if not exist android\gradlew.bat (
  echo Regenerating Android platform files...
  call flutter create --platforms=android --org com.dormbill --project-name dormbill .
)

call flutter pub get
call flutter build apk --release ^
  --dart-define=SUPABASE_URL=%SUPABASE_URL% ^
  --dart-define=SUPABASE_ANON_KEY=%SUPABASE_ANON_KEY%

echo.
echo APK output: build\app\outputs\flutter-apk\app-release.apk
endlocal

