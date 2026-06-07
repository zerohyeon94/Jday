# Jday — CLAUDE.md

## 프로젝트 개요
- **앱 이름:** Jday (제이데이)
- **번들 ID:** com.zerohyeon.jday
- **플랫폼:** iOS 17.0+ / macOS 14.0+
- **한 줄 설명:** 할 일 · 일정 · 이슈를 하나로 통합한 SwiftUI Multiplatform 업무 관리 앱

---

## 기술 스택 (반드시 준수)
| 항목 | 선택 | 비고 |
|------|------|------|
| UI | SwiftUI | UIKit 절대 사용 금지 |
| 아키텍처 | MVVM | ObservableObject / @Observable |
| 데이터 | SwiftData | CoreData 사용 금지 |
| 동기화 | CloudKit | 서버 없이 iCloud 무료 동기화 |
| 알림 | UserNotifications | |
| 최소 버전 | iOS 17 / macOS 14 | 하위 버전 대응 코드 작성 금지 |

---

## 코딩 컨벤션 (Swift 스타일 가이드)

### 네이밍
```swift
// ✅ Swift 네이밍 원칙 준수
struct DailyTaskRowView: View { }        // View: ~View 접미사
class DailyTaskViewModel: ObservableObject { }  // ViewModel: ~ViewModel
@Model class DailyTask { }               // Model: 명사형, 접미사 없음
enum Priority: String, Codable { }       // Enum: 단수형

// ✅ 프로퍼티
@State private var isPresented = false   // Bool: is~/has~/can~ 접두사
@Environment(\.modelContext) private var context  // 환경 변수

// ❌ 금지
var taskList: [DailyTask]  // List 대신 복수형 사용
var taskViewModel: TaskViewModel  // 불필요한 타입 반복
```

### SwiftData 모델
```swift
// ✅ 올바른 SwiftData 패턴
@Model
final class DailyTask {
    var title: String
    var isDone: Bool
    var date: Date
    var priority: Priority
    var createdAt: Date

    init(title: String, date: Date = .now, priority: Priority = .medium) {
        self.title = title
        self.isDone = false
        self.date = date
        self.priority = priority
        self.createdAt = .now
    }
}

// ✅ Query 사용법
@Query(sort: \DailyTask.date) private var tasks: [DailyTask]
@Query(filter: #Predicate { !$0.isDone }) private var pendingTasks: [DailyTask]
```

### SwiftUI View 구조
```swift
// ✅ View 작성 원칙
struct HomeView: View {
    // 1. Environment / EnvironmentObject
    @Environment(\.modelContext) private var context

    // 2. Query (SwiftData)
    @Query private var tasks: [DailyTask]

    // 3. ViewModel (필요 시)
    @StateObject private var viewModel = HomeViewModel()

    // 4. State (로컬 UI 상태만)
    @State private var isAddingTask = false

    var body: some View {
        // body는 간결하게, 복잡한 로직은 computed property나 subview로 분리
        content
            .sheet(isPresented: $isAddingTask) {
                QuickAddView()
            }
    }

    // ✅ body 분리: computed property 활용
    private var content: some View {
        ScrollView {
            summaryCards
            yesterdaySection
            todayTasksSection
            todayScheduleSection
        }
    }
}
```

### 플랫폼 분기
```swift
// ✅ 플랫폼 분기 원칙: 최소화하고 명확하게
#if os(macOS)
NavigationSplitView { ... } detail: { ... }
#else
TabView { ... }
#endif

// ✅ 플랫폼별 수식어
.padding(platformPadding)

private var platformPadding: CGFloat {
    #if os(macOS)
    return 20
    #else
    return 16
    #endif
}
```

### 에러 처리
```swift
// ✅ Swift 6 에러 처리 패턴
func saveTask(_ task: DailyTask) {
    do {
        context.insert(task)
        try context.save()
    } catch {
        // 에러 로깅 + 유저에게 Toast 표시
        print("❌ Save failed: \(error.localizedDescription)")
        errorMessage = error.localizedDescription
    }
}
```

---

## 프로젝트 구조 (반드시 준수)

```
Jday/
├── App/
│   ├── JdayApp.swift          # @main 진입점
│   └── ContentView.swift      # 플랫폼 분기 루트 뷰
│
├── Models/                    # SwiftData 모델
│   ├── DailyTask.swift
│   ├── Schedule.swift
│   ├── Issue.swift
│   └── Priority.swift
│
├── Features/                  # 기능별 폴더 (화면 + ViewModel)
│   ├── Home/
│   │   ├── HomeView.swift
│   │   ├── HomeViewModel.swift
│   │   └── Components/
│   │       ├── SummaryCardView.swift
│   │       ├── YesterdayTasksView.swift
│   │       ├── TodayTasksView.swift
│   │       └── TodayScheduleView.swift
│   ├── Calendar/
│   │   ├── CalendarView.swift
│   │   └── CalendarViewModel.swift
│   ├── QuickAdd/
│   │   ├── QuickAddView.swift
│   │   └── QuickAddViewModel.swift
│   ├── Issue/
│   │   ├── IssueListView.swift
│   │   ├── IssueDetailView.swift
│   │   └── IssueViewModel.swift
│   └── Settings/
│       └── SettingsView.swift
│
├── Platform/                  # 플랫폼별 전용 코드
│   ├── iOS/
│   │   └── iOSRootView.swift  # TabView 기반
│   └── macOS/
│       └── macOSRootView.swift # NavigationSplitView 기반
│
└── Core/                      # 공통 유틸리티
    ├── Extensions/
    │   ├── Date+Extensions.swift
    │   └── Color+Extensions.swift
    ├── Services/
    │   └── NotificationService.swift
    └── Helpers/
        └── PreviewHelpers.swift
```

---

## 핵심 비즈니스 로직

### 컨텍스트 어웨어 첫 화면
```swift
// 월요일(2) → 캘린더 / 그 외 → 홈
var defaultTab: Tab {
    Calendar.current.component(.weekday, from: .now) == 2 ? .calendar : .home
}
```

### 어제 미완료 판단
```swift
// 전날 isDone == false 인 DailyTask
let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: .now)!
@Query(filter: #Predicate<DailyTask> {
    !$0.isDone && $0.date >= yesterday.startOfDay && $0.date < yesterday.endOfDay
}) var yesterdayPendingTasks: [DailyTask]
```

### 진행률 계산
```swift
var progressPercentage: Double {
    guard !todayTasks.isEmpty else { return 0 }
    let done = todayTasks.filter(\.isDone).count
    return Double(done) / Double(todayTasks.count) * 100
}
```

---

## 알림 정책
```swift
// 이슈 알림: notifyAt 시간에 로컬 알림
// 일정 알림: startTime 30분 전 (설정에서 변경 가능)
// 해결완료 이슈: 예약 알림 즉시 취소
// 앱 권한 미허용 시: 설정 화면에서 권한 요청 배너 표시
```

---

## CloudKit 동기화 정책
- 모든 CRUD → SwiftData 로컬 먼저 → CloudKit 자동 sync
- 오프라인 → 로컬 저장 → 온라인 복구 시 자동 sync
- 충돌 → 최신 `updatedAt` 기준 덮어쓰기
- SwiftData + CloudKit 연동: `ModelContainer` 설정에서 `cloudKitDatabase` 활성화

```swift
// JdayApp.swift
let schema = Schema([DailyTask.self, Schedule.self, Issue.self])
let config = ModelConfiguration(schema: schema, cloudKitDatabase: .automatic)
let container = try ModelContainer(for: schema, configurations: config)
```

---

## UI/UX 원칙 (반드시 준수)

### 빈 상태 (Empty State)
```
어제 미완료 없음 → 섹션 전체 숨김
오늘 할 일 없음 → "할 일을 추가해보세요 +" 버튼
오늘 일정 없음 → "일정 없음" 텍스트
이슈 없음 → "등록된 이슈가 없어요 ✅"
```

### 인터랙션
```
할 일 체크 → 취소선 + 하단 이동 (애니메이션 포함)
지난 일정 → opacity(0.4) 처리
빠른 추가 탭 전환 → 입력값 초기화 (Alert 확인)
저장 실패 → Toast 에러 메시지
```

### 색상 시스템
```swift
// 시스템 색상 우선 사용 (다크모드 자동 대응)
Color.primary       // 메인 텍스트
Color.secondary     // 서브 텍스트
Color.accentColor   // 강조색 (파란색)
Color(.systemBackground)  // 배경
Color(.secondarySystemBackground)  // 카드 배경

// 상태 색상
Color.blue   // 미해결 이슈 뱃지
Color.gray   // 해결완료 이슈 뱃지
Color.green  // 완료 체크
```

---

## Preview 작성 원칙
```swift
// ✅ 모든 View에 Preview 필수 작성
#Preview {
    HomeView()
        .modelContainer(for: [DailyTask.self, Schedule.self, Issue.self],
                        inMemory: true)
}

// ✅ 샘플 데이터 포함 Preview
#Preview("할 일 있음") {
    let container = PreviewHelpers.makeContainer()
    // 샘플 데이터 삽입
    return HomeView()
        .modelContainer(container)
}
```

---

## 코드 생성 시 주의사항

### ✅ 반드시 지킬 것
- Swift 최신 문법 사용 (Swift 5.9+, Swift 6 준비)
- `@Observable` 매크로 활용 (iOS 17+)
- `async/await` 비동기 처리
- `#Predicate` 매크로로 SwiftData 필터링
- Accessibility 지원 (`accessibilityLabel`, `accessibilityHint`)
- 모든 String은 `LocalizedStringKey` 또는 `String(localized:)` 사용

### ❌ 절대 사용 금지
- `UIKit` / `AppKit` 직접 사용 (SwiftUI Representable 제외)
- `CoreData` (SwiftData 사용)
- `DispatchQueue.main.async` (MainActor 사용)
- `@objc` / `dynamic` (불필요한 경우)
- Force unwrapping (`!`) — Optional binding 사용
- `print()` 디버그 로그 남기기 (os_log 또는 Logger 사용)

### Swift 6 대비 패턴
```swift
// ✅ MainActor 명시
@MainActor
class HomeViewModel: ObservableObject { }

// ✅ Sendable 준수
@Model
final class DailyTask: Sendable { }

// ✅ async/await
func loadTasks() async throws -> [DailyTask] { }
```

---

## 작업 요청 시 기대 출력 형식

코드 생성 요청 시 아래 순서로 출력:
1. **파일 경로** 명시 (`// Features/Home/HomeView.swift`)
2. **전체 파일 코드** (import부터 끝까지)
3. **핵심 구현 설명** (3줄 이내)
4. **다음 단계 제안** (연관 파일 작업 순서)

---

*노션 기획서: https://www.notion.so/36fe5d4a0bac804a9dfadc57da5f6e90*
*기획 요약: Jday_기획요약_ClaudeCode용.md 참고*
