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

## macOS — 영구 저장소에 데모 적재 후 직접 캡처 (권장)
macOS 창 자동 위치/캡처는 환경(다중 디스플레이·Spaces)에 따라 불안정합니다.
대신 **실제 SwiftData 저장소에 데모 데이터를 채운 뒤** 직접 캡처하세요:

```bash
bash Screenshots/seed_macos.sh
```

- 데모 데이터(`-seedPersistentDemo`)가 영구 저장소에 적재되어 앱을 평소처럼 열어도 유지됩니다.
- 데이터는 **"오늘" 기준**으로 생성되니, 캡처하는 날에 실행하세요.
- 캡처: **Cmd+Shift+5 → "선택한 윈도우 캡처" → Jday 창 클릭** (창+그림자 포함). 사이드바로 홈/캘린더/이슈/설정 이동하며 각각 캡처.
- 정리: 캡처 후 앱에서 **설정 ▸ "모든 데이터 삭제"** 로 데모 데이터 제거.
- 스토어 규격(px): 1280×800 / 1440×900 / 2560×1600 / 2880×1800.

> 결과 예시는 `Screenshots/macOS/Jday_macOS_*.png` 참고.

### 관련 DEBUG 런치 인자
- `-seedPersistentDemo` : 영구 저장소를 비우고 데모 데이터 적재(ContentView `.task`)
- `-storeDemoData` : 인메모리 데모(저장 안 됨, iOS 시뮬레이터 캡처용)
- `-forceTab home|calendar|issue|settings`, `-openQuickAdd`, `-dumpCounts`

---

## 참고
- `-storeDemoData` / `-forceTab` / `-openQuickAdd` 는 모두 **DEBUG 빌드 전용** 런치 인자입니다(릴리스에 영향 없음).
- 제출 전 상태바·배터리·시간이 깔끔한지, 텍스트 잘림이 없는지 확인하세요.
