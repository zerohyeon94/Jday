# 위젯 · 시스템 연동 기획 (2026-07-19)

4개 요청 항목의 가능성 검토 결과와 개발 계획. 이번 구현 범위는 **위젯(잠금화면 + 홈 화면)**이며,
EventKit 연동과 Apple Pencil 메모는 후속 단계 로드맵으로 정리한다.

## 요청 항목별 가능성 검토

| # | 항목 | 가능 여부 | 핵심 기술 | 이번 구현 |
|---|------|-----------|-----------|-----------|
| 1 | iPad Apple Pencil 메모 | ✅ 가능 | PencilKit (`PKCanvasView` Representable) | ❌ 후속 |
| 2 | Apple 캘린더·미리 알림 연동 | ✅ 가능 | EventKit (iOS 17 권한 모델) | ❌ 후속 |
| 3 | 잠금화면 캘린더 표시 | ✅ 가능 (요약형) | WidgetKit accessory 위젯 | ✅ 이번 |
| 4 | 홈 화면 위젯 라인업 | ✅ 가능 | WidgetKit + AppIntents (인터랙티브) | ✅ 이번 |

### 검토 상세

1. **Apple Pencil 메모** — `PKCanvasView`를 `UIViewRepresentable`로 감싸 사용 (CLAUDE.md의 Representable 예외에 해당).
   그림은 `PKDrawing.dataRepresentation()` → `Data`로 SwiftData에 저장(`@Attribute(.externalStorage)`)하면 CloudKit 동기화도 그대로 작동.
   손글씨→텍스트 변환(Scribble)은 iPadOS 기본 기능이라 추가 개발 불필요. macOS는 그리기 입력 불가(보기 전용 렌더링만).
   **결정: 메모 필드에 "필기 첨부" 형태**로 붙인다 (독립 노트 탭 아님).
2. **EventKit 연동** — iOS 17 신규 권한(`NSCalendarsFullAccessUsageDescription` 등) 기반.
   **결정: 1단계 읽기 표시**(Apple 캘린더 일정을 Jday 캘린더/홈에 함께 표시)부터. 양방향 동기화는 충돌 처리 설계가 필요해 이후 단계.
   macOS는 `com.apple.security.personal-information.calendars` 엔타이틀먼트 필요.
3. **잠금화면** — 잠금화면 위젯은 공간이 작아 월간 달력 전체는 불가. "다음 일정 / 오늘 할 일 요약 / 진행률" 형태로 제공.
   iPhone StandBy 모드, Apple Watch 스마트 스택(향후)도 동일한 accessory 패밀리를 재사용.
4. **위젯 라인업** — 아래 설계 참고.

## 위젯 설계 (이번 구현)

### 라인업

| 패밀리 | 위젯 | 내용 |
|--------|------|------|
| systemSmall | 오늘 요약 | 진행률 링 + 남은 할 일 수 + 오늘 일정 수 |
| systemMedium | 오늘 할 일 | 할 일 최대 5개, **위젯에서 바로 완료 체크** (AppIntents) + 다음 일정 한 줄 |
| systemLarge | 월간 캘린더 | 달력 그리드(이벤트 도트) + 오늘 일정 목록 |
| accessoryInline | 다음 일정 | 잠금화면 시계 위 한 줄 ("14:00 팀 미팅") |
| accessoryCircular | 진행률 링 | 오늘 할 일 완료율 Gauge |
| accessoryRectangular | 오늘 브리핑 | 남은 할 일 N개 + 다음 일정 |

지원: iOS 17+/iPadOS 17+ (잠금화면 위젯은 iPadOS 17부터 지원). macOS 위젯은 후속.

### 아키텍처

```
JdayWidgets/                     # 신규 앱 익스텐션 타겟 (iOS 전용)
├── JdayWidgetsBundle.swift      # @main WidgetBundle — 위젯 6종 등록
├── WidgetSnapshot.swift         # TimelineEntry + 값 타입 스냅샷 (할 일/일정/이벤트 도트)
├── WidgetDataProvider.swift     # App Group 저장소에서 SwiftData 읽기 (cloudKitDatabase: .none)
├── ToggleTaskIntent.swift       # AppIntent — 위젯에서 할 일 완료 토글
├── TodayProgressWidget.swift    # systemSmall
├── TodayTasksWidget.swift       # systemMedium (인터랙티브)
├── MonthCalendarWidget.swift    # systemLarge
├── LockScreenWidgets.swift      # accessory 3종
└── JdayWidgets.entitlements     # App Group
```

모델 파일(`Jday/Models/*`)과 `Date+Extensions.swift`는 위젯 타겟에 소스로 공유(타겟 멤버십 추가, 파일 이동 없음).

### 데이터 공유 — App Group (핵심 변경)

- App Group ID: `group.com.zerohyeon.jday` (iOS 앱 + 위젯 엔타이틀먼트에 추가)
- **iOS 앱의 SwiftData 저장소를 App Group 컨테이너로 이동**:
  `ModelConfiguration(schema:, groupContainer: .identifier(...), cloudKitDatabase: .automatic)`
- **기존 저장소 마이그레이션**: 앱 시작 시 기존 위치(Application Support/default.store)에 파일이 있고
  그룹 컨테이너에 없으면 `default.store`, `-shm`, `-wal` 3개 파일을 이동. 실패 시 기존 경로 유지(데이터 손실 방지 우선).
- macOS는 위젯이 없으므로 기존 기본 위치 유지 (`#if os(iOS)` 분기).
- 작업 공간 설정(`workspaceSeparationEnabled`, `activeWorkspace`)을 위젯도 읽어야 하므로
  `@AppStorage`의 store를 App Group `UserDefaults`로 전환(iOS). 기존 standard 값은 최초 1회 그룹으로 복사.

### 갱신 정책

- 앱이 백그라운드로 전환될 때 `WidgetCenter.shared.reloadAllTimelines()` 호출 → 앱에서 변경한 내용 즉시 반영.
- 타임라인 엔트리: 현재 시각 + 오늘 각 일정의 시작/종료 시각 + 자정(다음 날 전환).
- 위젯 AppIntent로 완료 토글 시 로컬 저장 후 타임라인 재생성. CloudKit 업로드는 다음 앱 실행 시 반영(익스텐션은 sync 안 함 — 의도된 제약).

### 확인 필요 (수동)

- Apple Developer 포털에 App Group `group.com.zerohyeon.jday` 등록 여부 — Xcode 자동 서명이 보통 처리하지만 실기기 빌드에서 확인.
- 실기기에서 저장소 마이그레이션 후 기존 데이터 표시 확인.

## 후속 로드맵

1. **EventKit 1단계 (읽기 표시)** — `EventKitService` 신설, 설정에 "Apple 캘린더 표시" 토글 + 캘린더 선택,
   CalendarView/HomeView 타임라인에 읽기 전용 이벤트 표시(회색 계열 구분). 이후 2단계(내보내기), 3단계(양방향).
2. **Apple Pencil 메모 (첨부형)** — `DailyTask`/`Issue`/`Schedule` 상세의 메모 영역에 "필기 추가" 버튼 →
   `PKCanvasView` 시트에서 작성, `drawingData: Data?` 필드 추가(CloudKit 호환: 옵셔널). iPhone은 손가락 입력, macOS는 이미지 보기 전용.
3. **macOS 위젯 / 메뉴바** — 위젯 인프라 재사용.
