# Jday — CLAUDE.md

## 프로젝트 개요
- **앱 이름:** Jday (제이데이)
- **번들 ID:** com.zerohyeon.jday
- **플랫폼:** iOS 17.0+ / iPadOS 17.0+ / macOS 14.0+
- **한 줄 설명:** 할 일 · 일정 · 이슈를 하나로 통합한 SwiftUI Multiplatform 업무 관리 앱
- **저장소:** https://github.com/zerohyeon94/Jday

## 기술 스택 (반드시 준수)
| 항목 | 선택 | 비고 |
|------|------|------|
| UI | SwiftUI | UIKit/AppKit 직접 사용 금지 (Representable 제외) |
| 아키텍처 | MVVM | ObservableObject / @Observable |
| 데이터 | SwiftData | CoreData 사용 금지 |
| 동기화 | CloudKit | `iCloud.com.zerohyeon.jday`, 서버 없음 |
| 알림 | UserNotifications | |
| 프로젝트 생성 | XcodeGen | `project.yml`이 원본 — .xcodeproj 직접 수정 금지 |
| 최소 버전 | iOS 17 / macOS 14 | 하위 버전 대응 코드 작성 금지 |

타겟/설정 변경 시 `project.yml` 수정 후 `xcodegen generate` 실행.

---

## 문서 운영 정책 (중복 작성 금지)

**같은 내용을 두 곳에 쓰지 않는다.** 역할 분담:

| 위치 | 역할 |
|------|------|
| **리포 `docs/`** | 설계·규칙·현황 문서의 **원본** (전문은 여기에만 작성) |
| **노션** | 운영 허브 — 백로그, 개선사항 트래커 DB, 로드맵, 릴리스 노트 등 제품 운영 뷰 |

- 새 설계/스펙 문서는 `docs/`에 마크다운으로 작성하고, 노션에는 **요약 몇 줄 + GitHub 파일 링크**만 등록한다.
  - 링크 형식: `https://github.com/zerohyeon94/Jday/blob/develop/docs/<파일명>.md`
- 노션 문서의 전문을 리포로 복사하거나, 리포 문서 전문을 노션에 다시 쓰지 않는다.
- **예외:** 개인정보처리방침 등 외부 공개용 문서는 노션(공개 페이지)이 원본.
- 관련 노션 페이지:
  - [Jday 기획 메인](https://app.notion.com/p/36fe5d4a0bac804a9dfadc57da5f6e90) — PRD, 와이어프레임, 로드맵
  - [화면별 개선사항 트래커](https://app.notion.com/p/371e5d4a0bac81328974de29021d99d6) — 버그/개선 항목 관리 DB

### 리포 내 주요 문서
| 문서 | 내용 |
|------|------|
| [docs/development-overview.md](docs/development-overview.md) | 구현된 기능·아키텍처·동기화 정책 현황 |
| [docs/CHANGELOG.md](docs/CHANGELOG.md) | 버전별 업데이트 내역 |
| [docs/bugs-and-improvements.md](docs/bugs-and-improvements.md) | 버그·개선 항목 원인 분석과 계획 |
| [Jday_기획요약.md](Jday_기획요약.md) | 초기 기획 요약 (PRD 개요) |
| [AppStoreSubmission.md](AppStoreSubmission.md) | App Store 제출 자료 |

기능 구현·버그 수정 후에는 `docs/development-overview.md`와 `docs/CHANGELOG.md`를 갱신한다.

---

## 프로젝트 구조

```
Jday/
├── App/                  # JdayApp(진입점, ModelContainer 폴백), ContentView(플랫폼 분기)
├── Models/               # DailyTask, Schedule, Issue, Priority, Workspace
├── Features/             # 기능별 화면 + ViewModel
│   ├── Home/             #   요약 카드, 어제 미완료, 오늘 할 일/일정 (Components/ 포함)
│   ├── Calendar/         #   월/주 캘린더, 일정 상세, 완료 기록
│   ├── QuickAdd/         #   빠른 추가 (할 일/일정/이슈 탭)
│   ├── Issue/            #   이슈 목록/상세/수정
│   └── Settings/         #   화면 모드, 작업 공간, iCloud 상태, 알림
├── Platform/
│   ├── iOS/              # iOSRootView — 하단 탭바 + FAB
│   ├── iPad/             # iPadRootView — 사이드바 레이아웃
│   └── Shared/           # SidebarRootView, MacHomeView 등 (macOS 포함)
└── Core/
    ├── DesignSystem/     # Theme, Toast, SharedComponents, AppearanceMode, WorkspaceFilterBar
    ├── Extensions/       # Date+, Color+
    ├── Services/         # NotificationService, CloudSyncStatus
    └── Helpers/          # PreviewHelpers
```

새 파일은 위 구조에 맞는 폴더에 배치. 새 기능 화면은 `Features/<기능명>/`에 View + ViewModel 세트로 생성.

---

## 코딩 컨벤션

### 네이밍
```swift
struct DailyTaskRowView: View { }               // View: ~View 접미사
class HomeViewModel: ObservableObject { }        // ViewModel: ~ViewModel
@Model final class DailyTask { }                 // Model: 명사형, 접미사 없음
enum Priority: String, Codable { }               // Enum: 단수형
@State private var isPresented = false           // Bool: is~/has~/can~ 접두사
var tasks: [DailyTask]                           // 배열: 복수형 (taskList ❌)
```

### SwiftUI View 구조
프로퍼티 선언 순서: ① Environment → ② @Query → ③ ViewModel → ④ @State(로컬 UI 상태만).
body는 간결하게 — 복잡한 부분은 computed property나 subview로 분리.

### 플랫폼 분기
`#if os(macOS)` 분기는 최소화. 값 차이는 `platformPadding` 같은 computed property로 분리.
플랫폼별 루트/레이아웃이 통째로 다르면 `Platform/` 아래에 배치.

### ✅ 반드시 지킬 것
- Swift 5.9+ 문법, `async/await`, `@MainActor` (ViewModel에 명시)
- SwiftData 필터링은 `#Predicate` 매크로 사용
- 에러 처리: `do-catch` + `Logger` 기록 + 사용자에게 Toast 표시
- Accessibility (`accessibilityLabel`, `accessibilityHint`)
- 사용자 노출 문자열은 `LocalizedStringKey` 또는 `String(localized:)`
- 모든 View에 `#Preview` 작성 — `PreviewHelpers.makeContainer()` 활용, in-memory 컨테이너

### ❌ 절대 사용 금지
- UIKit/AppKit 직접 사용 (SwiftUI Representable 제외)
- CoreData, `DispatchQueue.main.async` (MainActor 사용)
- Force unwrapping (`!`) — Optional binding 사용
- `print()` — `os.Logger` 사용 (subsystem: `com.j.jday`)
- .xcodeproj 직접 편집 — `project.yml` + XcodeGen

---

## 데이터 & 동기화

### SwiftData 모델
| 모델 | 주요 필드 |
|------|-----------|
| `DailyTask` | title, isDone, date, priority, completedAt, memo, workspace |
| `Schedule` | title, startTime, endTime, location, workspace |
| `Issue` | title, detail, createdAt, isResolved, notifyAt, workspace |
| `Workspace` (enum) | personal / work — `nil`은 미분류 (작업 공간 분리 OFF 시 저장분) |

모델 추가/변경 시 `JdayApp.swift`의 `Schema`와 CloudKit 호환성(기본값 있는 옵셔널, 관계 규칙)을 함께 확인.

### CloudKit 정책
- 모든 CRUD는 SwiftData 로컬 먼저 → CloudKit 자동 sync. 오프라인 → 온라인 복구 시 자동 sync.
- `ModelConfiguration(cloudKitDatabase: .automatic)` — 실패 시 로컬 전용(`.none`) → 인메모리 순 폴백 ([JdayApp.swift](Jday/App/JdayApp.swift))
- 폴백 발생 시 `Logger` 기록 + `CloudSyncStatus.shared`에 모드 저장 → 설정 화면에 상태 표시
- `UIBackgroundModes: remote-notification`으로 백그라운드 동기화

## 알림 정책
- 이슈: `notifyAt` 시간에 로컬 알림. 해결완료 처리 시 예약 알림 즉시 취소.
- 일정: `startTime` 30분 전 (설정에서 변경 가능).
- 권한 미허용 시 설정 화면에 권한 요청 배너 표시.

---

## UI/UX 원칙

### 빈 상태
- 어제 미완료 없음 → 섹션 전체 숨김
- 오늘 할 일 없음 → "할 일을 추가해보세요 +" 버튼
- 오늘 일정 없음 → "일정 없음" 텍스트
- 이슈 없음 → "등록된 이슈가 없어요 ✅"

### 인터랙션
- 할 일 체크 → 취소선 + 하단 이동 (애니메이션), `completedAt` 기록
- 스와이프 삭제 → Undo 토스트, 끝까지 밀면 즉시 삭제
- 지난 일정 → 흐림 처리
- 빠른 추가 탭 전환 → 입력값 초기화 (확인 Alert)
- 저장 실패 → Toast 에러 메시지

### 색상
시스템 색상 우선 (`Color.primary/secondary/accentColor`, `Color(.systemBackground)`) — 다크모드 자동 대응.
공통 스타일은 `Core/DesignSystem/Theme.swift` 참고. 상태 색: 미해결 이슈 파랑, 해결완료 회색, 완료 체크 초록.

---

## 작업 요청 시 기대 출력 형식
1. **파일 경로** 명시 (`// Features/Home/HomeView.swift`)
2. **전체 파일 코드** (import부터 끝까지)
3. **핵심 구현 설명** (3줄 이내)
4. **다음 단계 제안** (연관 파일 작업 순서)
