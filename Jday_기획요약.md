# Jday 앱 기획 요약 (Claude Code 전달용)

## 앱 개요
- **앱 이름:** Jday (제이데이)
- **번들 ID:** com.zerohyeon.jday
- **한 줄 소개:** J의 하루를 흐름있게 — 할 일, 일정, 이슈를 하나로
- **플랫폼:** iOS + macOS (SwiftUI Multiplatform)
- **핵심 가치:** 노션 + 미리알림 + 캘린더 3개 앱을 하나로 통합

---

## 문제 정의 (Pain Point)
매일 아침 노션(업무) → 캘린더(일정) → 미리알림(할 일) 3개 앱을 왔다갔다 해야 함.

**가장 불편한 두 순간:**
1. 출근 직후 → 어제 업무 + 오늘 할 일 파악에 3번 앱 전환 필요
2. 업무 중 → 할 일/일정/이슈 생길 때마다 각 앱으로 이동해서 입력

---

## 핵심 기능 (MVP)
1. 어제 업무 요약 + 오늘 할 일 통합 뷰 (홈 화면)
2. 오늘 일정 + 할 일 빠른 추가 (바텀시트/팝오버)
3. 이슈 사항 입력 + 로컬 알림
4. iCloud 동기화 (CloudKit) — 맥 ↔ 아이폰 실시간 반영

---

## 기술 스택
| 항목 | 선택 |
|------|------|
| UI Framework | SwiftUI Multiplatform |
| Architecture | MVVM |
| 로컬 저장 | SwiftData |
| 동기화 | CloudKit (iCloud, 무료) |
| 알림 | UserNotifications |
| 맥 전용 | MenuBar (WidgetKit, 2단계) |

---

## 데이터 모델 (SwiftData)

```swift
// 일일 업무
@Model class DailyTask {
    var title: String
    var isDone: Bool
    var date: Date
    var priority: Priority  // low / medium / high
    var createdAt: Date
}

// 일정
@Model class Schedule {
    var title: String
    var startTime: Date
    var endTime: Date
    var location: String?
    var createdAt: Date
}

// 이슈
@Model class Issue {
    var title: String
    var detail: String?
    var isResolved: Bool
    var notifyAt: Date?
    var createdAt: Date
}

enum Priority: String, Codable {
    case low, medium, high
}
```

---

## 화면 구조 (IA)

### iOS (탭바 기반)
```
하단 탭바: 홈 | 캘린더 | ⚡추가(FAB, 가운데) | 이슈 | 설정

홈 탭
├── 상단: 날짜 + 요일
├── 숫자 카드: 할 일 남음 / 오늘 일정 / 진행률
├── 어제 미완료 섹션 (없으면 숨김)
│   └── "모두 오늘로 옮기기" 버튼
├── 오늘 할 일 체크리스트
└── 오늘 일정 타임라인

캘린더 탭
├── 주간/월간 세그먼트 전환
├── 월별 캘린더 그리드 (날짜별 이벤트 도트)
└── 선택 날짜 하단: 일정 + 할 일 통합 리스트

⚡ 빠른 추가 (바텀시트)
├── 탭: 할 일 / 일정 / 이슈
├── 할 일: 제목 + 날짜 + 우선순위(낮음/중간/높음)
├── 일정: 제목 + 시작시간 + 종료시간 + 장소
└── 이슈: 제목 + 상세내용 + 알림시간

이슈 탭
├── 필터: 전체 / 미해결 / 해결완료
├── 이슈 카드 리스트 (제목 + 날짜 + 상태 뱃지)
└── 탭 → 이슈 상세 (내용 + 메타정보 + 해결완료 버튼)

설정 탭
├── 푸시 알림 토글
├── 기본 알림 시간 (기본값: 30분 전)
├── 시작 화면 선택
├── 한 주 시작 요일
├── 완료 항목 자동 숨김 토글
└── 프로필 + 로그아웃
```

### macOS (NavigationSplitView 기반)
```
왼쪽 사이드바: 홈 / 캘린더 / 이슈 / 설정
상단 툴바: 검색 + + 빠른 추가 버튼

홈: 중앙 메인(숫자카드 + 미완료 + 할 일) + 우측 패널(오늘 일정)
캘린더: 중앙 월별 그리드 + 우측 패널(선택일 일정 + 할 일)
이슈: 중앙 목록 + 우측 패널(이슈 상세)
설정: 단일 뷰
```

---

## 플랫폼별 UI 분기 전략
```swift
struct ContentView: View {
    var body: some View {
        #if os(macOS)
        MacRootView()  // NavigationSplitView
        #else
        iOSRootView()  // TabView
        #endif
    }
}
```

---

## 컨텍스트 어웨어 첫 화면 (Context-Aware UX)
```swift
// 월요일 or 공휴일 다음날 → 캘린더 홈 (주간 계획 모드)
// 그 외 평일 → 홈 대시보드 (어제 요약 + 오늘 할 일)
var defaultTab: Tab {
    let today = Calendar.current.component(.weekday, from: Date())
    return today == 2 ? .calendar : .home  // 2 = 월요일
}
```

---

## PRD 핵심 동작 명세

### 홈 화면
- 숫자 카드 - 할 일 남음: 미완료 DailyTask 개수 (0이면 "모두 완료! 🎉")
- 숫자 카드 - 진행률: 완료/전체 할 일 % (할 일 0개면 카드 숨김)
- 어제 미완료: 전날 isDone == false 항목 (없으면 섹션 전체 숨김)
- "모두 오늘로 옮기기": 확인 Alert 없이 즉시 date → 오늘로 변경
- 할 일 체크: 완료 시 취소선 + 하단으로 이동
- 지난 일정: opacity 0.4로 흐리게 처리

### 빠른 추가
- 제목 비어있으면 저장 버튼 비활성화
- 일정: 종료시간 < 시작시간이면 저장 버튼 비활성화
- 이슈 알림: 과거 시간 설정 시 경고 표시
- 저장 실패 시 Toast 에러 메시지
- 탭 전환 시 입력값 초기화 + Alert 확인

### 이슈
- 미해결: 파란 뱃지 / 해결완료: 회색 뱃지
- iOS 왼쪽 스와이프 → 삭제 버튼 (삭제 확인 Alert 필요)
- 해결완료 버튼 탭 → isResolved = true + 예약 알림 자동 취소

### 공통
- CloudKit 동기화: 모든 CRUD → SwiftData 로컬 저장 → CloudKit 자동 sync
- 오프라인: 로컬 저장 → 온라인 복구 시 자동 sync
- 충돌: 최신 updatedAt 기준 덮어쓰기

---

## 개발 로드맵
### 1단계 (MVP)
- [ ] Xcode SwiftUI Multiplatform 프로젝트 생성 (번들 ID: com.zerohyeon.jday)
- [ ] SwiftData 모델 3개 구현 (DailyTask / Schedule / Issue)
- [ ] iOS 홈 화면 구현
- [ ] 빠른 추가 바텀시트 구현
- [ ] CloudKit 동기화 연결

### 2단계
- [ ] 캘린더 화면 (월별/주간 뷰)
- [ ] 이슈 목록 + 상세 화면
- [ ] UserNotifications 알림 구현
- [ ] macOS NavigationSplitView 레이아웃

### 3단계
- [ ] 맥 메뉴바 위젯 (WidgetKit)
- [ ] 배운 점 / 회고 기록
- [ ] Claude API 연동 (일일 업무 자동 분석)

---

## Xcode 프로젝트 초기 설정
1. Xcode → New Project → Multiplatform → App
2. Product Name: **Jday**
3. Bundle Identifier: **com.zerohyeon.jday**
4. Team: 본인 Apple ID
5. Targets: iOS 17.0+ / macOS 14.0+
6. CloudKit 활성화: Signing & Capabilities → + Capability → CloudKit
7. iCloud 활성화: Signing & Capabilities → + Capability → iCloud → CloudKit 체크

---

*이 문서는 Claude와 함께 진행한 앱 기획 세션을 바탕으로 작성됐습니다.*
*노션 기획서: https://www.notion.so/36fe5d4a0bac804a9dfadc57da5f6e90*
