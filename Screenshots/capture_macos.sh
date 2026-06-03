#!/bin/bash
# macOS 스토어 스크린샷 캡처 헬퍼
#
# 사용법:
#   1) 이 스크립트는 "화면 기록(Screen Recording)" 권한이 필요합니다.
#      시스템 설정 ▸ 개인정보 보호 및 보안 ▸ 화면 기록 에서 사용하는 터미널 앱을 허용하세요.
#   2) 실행:  bash Screenshots/capture_macos.sh
#
# 권한 자동 캡처가 막히면, 각 화면이 떠 있는 동안 수동으로 캡처하세요:
#   Cmd+Shift+5 → "선택한 윈도우 캡처" → Jday 창 클릭 (창+그림자 포함, 스토어 권장)
set -e

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
OUT="$ROOT/Screenshots/macOS"
mkdir -p "$OUT"

echo "▶︎ macOS 앱 빌드 중..."
xcodebuild -project "$ROOT/Jday.xcodeproj" -scheme Jday_macOS -destination 'platform=macOS' \
  -derivedDataPath /tmp/jday_mac build >/dev/null 2>&1
APP=$(find /tmp/jday_mac/Build/Products -name "Jday.app" -type d | head -1)
echo "   앱: $APP"

shoot() {  # $1=forceTab  $2=파일명
  osascript -e 'tell application "Jday" to quit' >/dev/null 2>&1 || true
  sleep 1
  open "$APP" --args -storeDemoData -forceTab "$1"
  echo "   ▸ $2 ($1) 창이 떴습니다. 3초 후 캡처 시도..."
  sleep 4
  if screencapture -o -x "$OUT/$2" 2>/dev/null; then
    echo "     저장: Screenshots/macOS/$2 (전체 화면 — 창만 크롭해 사용하세요)"
  else
    echo "     ⚠︎ 자동 캡처 실패(화면 기록 권한 필요). 지금 Cmd+Shift+5 로 Jday 창을 직접 캡처하세요."
    read -r -p "     캡처를 마쳤으면 Enter를 눌러 다음 화면으로..." _
  fi
}

shoot home     01-home.png
shoot calendar 02-calendar.png
shoot issue    03-issue.png
shoot settings 04-settings.png

osascript -e 'tell application "Jday" to quit' >/dev/null 2>&1 || true
echo "✅ 완료. Screenshots/macOS/ 를 확인하세요."
echo "   팁) 창 크기를 먼저 보기 좋게 맞춘 뒤(예: 1440×900) 캡처하면 스토어 규격에 맞추기 쉽습니다."
