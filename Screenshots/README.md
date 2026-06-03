# App Store 스크린샷 가이드

데모 데이터(`-storeDemoData`)를 주입해 홈·캘린더·빠른추가·이슈·설정을 캡처합니다.
데모 데이터는 인메모리(저장 안 됨)라 실제 사용자 데이터에 영향을 주지 않습니다.

## 데모 데이터 내용
- **오늘 할 일** 6개(3개 완료 → 진행률 50%), 우선순위 색상 바, 어제 미완료 2개
- **오늘 일정** 4개 타임라인(앱 실행 시점 이후로 자동 배치 → 흐려지지 않음)
- **캘린더**: 여러 날 일정(제주 워크숍) + 이번 달 곳곳의 단일 일정(도트/막대)
- **이슈** 5개(미해결 3 / 해결완료 2)
- 작업 공간 분리는 OFF (모든 콘텐츠 표시)

---

## iOS (자동 캡처 완료)
`Screenshots/iOS/` 에 6.7" iPhone(15 Pro Max, 1290×2796) 기준으로 저장됨:
`01-home · 02-calendar · 03-quickadd · 04-issue · 05-settings`

재생성:
```bash
DEV="CD40C80F-6713-4B80-84AA-301CF61C5DCF"   # iPhone 15 Pro Max
xcrun simctl boot "$DEV"; sleep 3
xcrun simctl ui "$DEV" appearance light
xcrun simctl status_bar "$DEV" override --time "9:41" --batteryState charged \
  --batteryLevel 100 --cellularBars 4 --wifiBars 3 --dataNetwork wifi
xcodebuild -project Jday.xcodeproj -scheme Jday_iOS -destination "id=$DEV" \
  -derivedDataPath /tmp/jday_store build
APP=$(find /tmp/jday_store/Build/Products -name "Jday.app" -type d | head -1)
xcrun simctl install "$DEV" "$APP"

# 화면별 (forceTab: home|calendar|issue|settings, 빠른추가는 -openQuickAdd)
xcrun simctl launch "$DEV" com.j.jday -storeDemoData -forceTab calendar
sleep 3; xcrun simctl io "$DEV" screenshot Screenshots/iOS/02-calendar.png
```

> 6.9"(iPhone 16 Pro Max, 1320×2868)도 제출 가능: 해당 시뮬레이터를 설치하고 DEV만 교체.
> 다크 모드 버전이 필요하면 `xcrun simctl ui "$DEV" appearance dark` 후 다시 캡처.

---

## macOS (수동/반자동)
이 저장소 자동화 환경에서는 "화면 기록" 권한이 없어 자동 캡처가 불가합니다.
사용자 Mac에서 아래 스크립트를 실행하세요:

```bash
bash Screenshots/capture_macos.sh
```

- 시스템 설정 ▸ 개인정보 보호 및 보안 ▸ **화면 기록**에서 사용하는 터미널을 허용해야 합니다.
- 권장: 각 화면이 뜬 동안 **Cmd+Shift+5 → "선택한 윈도우 캡처" → Jday 창 클릭** (창+그림자 포함).
- 창 크기를 먼저 보기 좋게(예: 1440×900) 맞춘 뒤 캡처하면 스토어 규격(1280×800 / 1440×900 / 2560×1600 / 2880×1800)에 맞추기 쉽습니다.

수동 실행 예:
```bash
APP=/tmp/jday_mac/Build/Products/Debug/Jday.app   # capture_macos.sh가 빌드해 둠
open "$APP" --args -storeDemoData -forceTab calendar
```

---

## 참고
- `-storeDemoData` / `-forceTab` / `-openQuickAdd` 는 모두 **DEBUG 빌드 전용** 런치 인자입니다(릴리스에 영향 없음).
- 제출 전 상태바·배터리·시간이 깔끔한지, 텍스트 잘림이 없는지 확인하세요.
