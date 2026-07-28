# Jday 개발 현황 정리

*최종 업데이트: 2026-07-19*

## 개요

- **앱 이름:** Jday (제이데이)
- **번들 ID:** com.zerohyeon.jday
- **버전:** 1.0.0 (빌드 2)
- **플랫폼:** iOS 17.0+ / iPadOS 17.0+ / macOS 14.0+
- **스택:** SwiftUI Multiplatform · MVVM · SwiftData · CloudKit · UserNotifications

## 구현 완료 기능

### 홈 (PRD-01)
- 상단 날짜/요일 + 숫자 요약 카드 (할 일 남음 / 오늘 일정 / 진행률)
- 어제 미완료 섹션 + 개별/전체 "오늘로 옮기기"
- 오늘 할 일 체크리스트 — 완료 시 취소선 + 하단 이동, `completedAt` 기록
- 스와이프 삭제 + 실행 취소(Undo) 토스트, 끝까지 밀면 즉시 삭제
- 컨텍스트 메뉴 (완료/상세/삭제/우선순위 변경/날짜 변경)
- 할 일 메모 및 상세 시트 (`TaskDetailView`)
- 오늘 일정 타임라인 — 지난 일정 흐림 처리

### 빠른 추가 (PRD-02)
- 바텀시트 (iOS) / 팝오버 (macOS) / iPad 전용 스타일
- 할 일 / 일정 / 이슈 탭 전환, 탭 전환 시 입력값 초기화 확인
- 내용에 맞춰 시트 높이 자동 조정, 키보드 점프 수정 완료
- 우선순위 색상 바 표시

### 캘린더 (PRD-03)
- 월별 그리드 + 주간/월간 세그먼트 전환
- 날짜별 이벤트 도트, 여러 날 일정은 이어지는 막대로 표시 (macOS)
- 선택일 일정/할 일 리스트 + 완료 기록 (`CompletedTasksView`)
- 일정 상세 화면 (`ScheduleDetailView`) — 우선순위 편집, 시간·우선순위 변경 시 알림 재예약
- 일정 중요도 3단계(낮음/보통/높음) — 목록에서 중요도 색으로 강조(높음은 느낌표 배지)
- 이전/다음 달(주) 이동 — 화살표 버튼 + 좌우 스와이프

### 이슈 (PRD-04 / PRD-05)
- 목록 + 필터 탭 (전체/미해결/해결완료), 미해결 카운트
- 상세 화면 — 상태 뱃지, 메타 정보, 해결완료 처리
- 수정 기능 — 제목/상세 내용/알림 시간 편집 시트 (`IssueEditView`), 알림 자동 재예약
- macOS는 Mail 앱 패턴 (좌측 목록 + 우측 상세 패널)

### 설정
- 화면 모드 (라이트/다크/시스템)
- 회사/개인 작업 공간 분리 토글 + 활성 공간 전환 (`workspaceSeparationEnabled`, `activeWorkspace`)
- iCloud 동기화 상태 표시 (동기화 사용 중 / 로그인 필요 / 로컬 전용 / 오류)
- 알림 관련 설정

### 위젯 (iOS/iPadOS 17+)
- `JdayWidgets` 익스텐션 타겟 — 설계: [widgets-and-integrations-plan.md](widgets-and-integrations-plan.md)
- 홈: 소형 "오늘 요약"(진행률 링) / 중형 "오늘 할 일"(AppIntents로 위젯에서 완료 체크) / 대형 "월간 캘린더"
- 잠금화면: 원형(진행률) · 직사각형 · 인라인 "오늘 브리핑" (StandBy 모드 포함)
- 데이터 공유: App Group `group.com.zerohyeon.jday` — SwiftData 저장소·작업 공간 설정 공유, 앱 백그라운드 전환 시 타임라인 갱신
- 위젯 익스텐션은 CloudKit sync를 하지 않음(로컬 읽기 전용 + 완료 토글 쓰기, 업로드는 앱 실행 시)

### Apple 캘린더 연동 — 1·2단계 (iOS/iPadOS)
- **1단계 읽기 표시**: 설정 > 연동 > "Apple 캘린더 표시" 토글 + 표시할 캘린더 선택 (`EventKitService`)
  - 홈·캘린더 화면에 읽기 전용 카드(`ExternalEventListView`)로 표시, 월간 그리드 이벤트 도트 포함
  - `EKEventStoreChanged` 감지로 캘린더 앱 변경 자동 반영
- **2단계 내보내기**: "일정을 Apple 캘린더와 동기화" 토글 — 전용 "Jday" 캘린더(iCloud 소스 우선)에
  일정 추가·수정·삭제 자동 반영, 켤 때 기존 미종료 일정 일괄 내보내기, `exportedEventID`로 중복 방지
  - 내보낸 캘린더는 1단계 표시에서 제외 (중복 표시 방지)
- **3단계 양방향**: 'Jday' 캘린더에서의 수정·삭제·직접 추가를 Jday로 역반영 (`syncBack`)
  - 수정 시각 비교로 충돌 해소, 앱 활성화 + `EKEventStoreChanged` 트리거
  - 'Jday' 캘린더 삭제 시 일정 보존 + 동기화 자동 해제
- macOS 표시·동기화는 후속.

### Apple 미리 알림 연동 (iOS/iPadOS)
- 설정 > 연동 > "할 일을 미리 알림과 동기화" — 전용 "Jday" 미리 알림 목록(iCloud 소스 우선), `ReminderService`
- 할 일 추가·수정·완료·삭제 → 미리 알림 반영 (제목·메모·마감일·우선순위·완료 상태 매핑)
- 미리 알림에서의 완료 체크·수정·삭제·직접 추가 → 할 일로 역반영 (`syncBack`, 수정 시각 비교로 충돌 해소)
- 캘린더와 권한이 분리되어 있어 별도 `EKEventStore`·설정 키로 관리
- 역동기화는 재진입 가드로 보호 (조회 대기 중 다른 트리거가 끼어들면 중복 가져오기가 발생하므로)

### Apple Pencil 필기 메모 (iOS/iPadOS)
- 할 일·일정·이슈 상세/수정 화면에서 필기 첨부 (`DrawingAttachmentRow` + PencilKit 캔버스 시트)
- `drawingData: Data?` (externalStorage) 필드로 저장 — CloudKit 동기화, macOS는 보기 전용 렌더링
- iPad는 Apple Pencil + PKToolPicker, iPhone은 손가락 입력 (`drawingPolicy: .anyInput`)

### 플랫폼 대응
- iOS: 하단 탭바 + FAB (`iOSRootView`)
- iPadOS: 사이드바 레이아웃 전용 루트 (`iPadRootView`)
- macOS: NavigationSplitView 사이드바 + 우측 패널 (`SidebarRootView`, `MacHomeView` 등)
- iPad 멀티태스킹 대응 (`UISupportedInterfaceOrientations`)

## 데이터 & 동기화

### SwiftData 모델
| 모델 | 주요 필드 |
|------|-----------|
| `DailyTask` | title, isDone, date, priority, completedAt, memo, workspace, drawingData, exportedReminderID |
| `Schedule` | title, startTime, endTime, location, priority, workspace, drawingData, exportedEventID |
| `Issue` | title, detail, createdAt, isResolved, notifyAt, workspace, drawingData |
| `Workspace` (enum) | personal / work — `nil`은 미분류 (분리 OFF 시 저장된 항목) |

### CloudKit
- `ModelConfiguration(cloudKitDatabase: .automatic)` — 컨테이너: `iCloud.com.zerohyeon.jday`
- 컨테이너 생성 실패 시 로컬 전용(.none) → 인메모리 순으로 폴백 ([JdayApp.swift](../Jday/App/JdayApp.swift))
- 폴백 발생 시 `Logger` 기록 + `CloudSyncStatus`에 모드 저장 → 설정 화면 "iCloud" 섹션에서 상태 확인 가능
- `UIBackgroundModes: remote-notification` — CloudKit 변경 푸시로 백그라운드 동기화
- 엔타이틀먼트: `aps-environment`는 `development` (App Store 배포 시 Xcode가 production 자동 전환)
- 엔타이틀먼트: `com.apple.developer.usernotifications.time-sensitive`(iOS) — 높음 중요도 일정의 시간 민감 알림용.
  Apple Developer 포털에서 "Time Sensitive Notifications" capability 활성화 필요(미활성 시 `.active`로 자동 강등)

### 일정 알림 정책 (중요도 차등)
- 중요도별 알림 강도: 높음 `.timeSensitive` / 보통 `.active` / 낮음 `.passive` ([NotificationService.swift](../Jday/Core/Services/NotificationService.swift))
- 중요도별 미리 알림: 높음 = 하루 전·1시간 전·기본 리드타임 / 보통 = 기본 리드타임 1회 / 낮음 = 10분 전 1회
- 기본 리드타임 = 설정 `notifyMinutesBefore`(기본 30분). 하나의 일정이 여러 알림을 가지므로 식별자는 `schedule-<id>-<offset>`

## 프로젝트 구조

```
Jday/
├── App/            # JdayApp(진입점), ContentView(플랫폼 분기)
├── Models/         # DailyTask, Schedule, Issue, Priority, Workspace
├── Features/       # Home, Calendar, QuickAdd, Issue, Settings
├── Platform/       # iOS, iPad, Shared(macOS 포함)
└── Core/           # DesignSystem, Extensions, Services, Helpers
```

- 프로젝트 생성: `project.yml` (XcodeGen)
- App Store 제출 자료: [AppStoreSubmission.md](../AppStoreSubmission.md)

## 미구현 / 예정 기능

자세한 분석은 [bugs-and-improvements.md](bugs-and-improvements.md) 참고.

- macOS 위젯 / 메뉴바 (iOS 위젯 인프라 재사용) + macOS Apple 캘린더 표시
- macOS 캘린더·미리 알림 연동 (엔타이틀먼트 추가 필요)
- iCloud 실기기 동기화 검증 + CloudKit Production 스키마 배포 확인 (수동)
- App Group `group.com.zerohyeon.jday` 포털 등록 확인 + 실기기에서 저장소 이전 검증 (수동)
- (3단계) 회고 기록, Claude API 일일 업무 분석

2026-07-20에 완료: Apple 미리 알림 ↔ 할 일 양방향 동기화, 역동기화 중복 생성 버그 수정
2026-07-19에 완료: WidgetKit 위젯 4종(홈 3 + 잠금화면 3형태), App Group 저장소 이전, Apple 캘린더 연동 1·2·3단계(표시·내보내기·양방향), Apple Pencil 필기 메모
2026-07-08에 완료: 캘린더 좌우 스와이프, 이슈 수정 기능, 작업 공간 분리 데이터 미표시 버그, iCloud 동기화 상태 표시
