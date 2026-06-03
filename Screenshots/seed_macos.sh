#!/bin/bash
# macOS 앱에 스토어용 데모 데이터를 "영구 저장소"에 채우고 앱을 띄웁니다.
# 그 다음 Cmd+Shift+5 → "선택한 윈도우 캡처" → Jday 창 클릭 으로 직접 캡처하세요.
#
# 데모 데이터는 "오늘" 기준으로 생성되므로, 캡처하는 날에 이 스크립트를 실행하세요.
# (앱은 실제 SwiftData 저장소를 사용하므로, 끝나면 설정 ▸ "모든 데이터 삭제"로 정리 가능)
set -e
ROOT="$(cd "$(dirname "$0")/.." && pwd)"

echo "▶︎ macOS 앱 빌드..."
xcodebuild -project "$ROOT/Jday.xcodeproj" -scheme Jday_macOS -destination 'platform=macOS' \
  -derivedDataPath /tmp/jday_mac build >/dev/null 2>&1
APP=$(find /tmp/jday_mac/Build/Products -name "Jday.app" -type d | head -1)

osascript -e 'tell application "Jday" to quit' >/dev/null 2>&1 || true
sleep 1
defaults write com.j.jday workspaceSeparationEnabled -bool NO

echo "▶︎ 데모 데이터 적재 + 실행..."
open "$APP" --args -seedPersistentDemo -forceTab home -workspaceSeparationEnabled NO
sleep 6

if [ -f /tmp/jday_seed_result.txt ]; then
  echo "   적재 결과: $(cat /tmp/jday_seed_result.txt)"
fi

cat <<'GUIDE'

✅ Jday 창에 데모 데이터가 표시됩니다.

캡처 방법 (스토어 권장):
  1) Cmd+Shift+5 → "선택한 윈도우 캡처" 선택 → Jday 창 클릭 (창+그림자 포함)
  2) 좌측 사이드바에서 홈 / 캘린더 / 이슈 / 설정 을 눌러가며 각각 캡처
  3) 저장 위치: 데스크탑(기본) 또는 옵션에서 Screenshots/macOS 로 지정

스토어 규격(픽셀): 1280×800 · 1440×900 · 2560×1600 · 2880×1800
  · 창 크기를 미리 보기 좋게 맞춘 뒤 캡처하면 맞추기 쉽습니다.

정리: 캡처가 끝나면 앱에서 설정 ▸ "모든 데이터 삭제" 로 데모 데이터를 지울 수 있습니다.
GUIDE
