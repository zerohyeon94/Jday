# 버그 · 개선 항목 분석

*최종 업데이트: 2026-07-08*
*노션 [개선사항 트래커](https://app.notion.com/p/371e5d4a0bac81328974de29021d99d6)와 동기화하여 관리합니다.*

---

## 1. 캘린더 좌우 스와이프로 달 이동 — 개선 · ✅ 완료 (2026-07-08)

**현상**
캘린더에서 이전/다음 달 이동이 상단 화살표 버튼으로만 가능했다.

**처리 내역**
[CalendarView.swift](../Jday/Features/Calendar/CalendarView.swift)의 캘린더 그리드 카드에 `simultaneousGesture(DragGesture)`를 추가했다. 수평 이동량이 50pt를 넘고 세로 이동량의 1.5배 이상일 때만 달/주 이동이 동작해 세로 스크롤과 충돌하지 않는다. 월간 뷰에서는 달, 주간 뷰에서는 주 단위로 이동한다 (`shiftMonth` 재사용). macOS는 기존 버튼 유지.

---

## 2. 이슈 수정 기능 — 신규 · ✅ 완료 (2026-07-08)

**현상**
등록한 이슈의 제목/내용/알림 시간을 수정할 수 없었다 (PRD-05가 상세 화면을 "표시 전용"으로 정의).

**처리 내역**
1. [IssueEditView.swift](../Jday/Features/Issue/IssueEditView.swift) 신규 — 제목/상세 내용/알림 토글+시간 편집 시트 (iOS/macOS 공용). 빈 제목이면 저장 비활성화, 과거 알림 시간은 경고 표시
2. [IssueViewModel.swift](../Jday/Features/Issue/IssueViewModel.swift)에 `update()` 추가 — 저장 후 기존 예약 알림을 취소하고 미해결 이슈면 재등록
3. [IssueDetailContent.swift](../Jday/Features/Issue/IssueDetailContent.swift) 헤더에 "수정" 버튼 (iOS 시트/macOS 패널 공용). 해결완료 이슈도 수정 가능 (상태 유지)
4. 메타 카드의 알림 시간이 하드코딩("30분 전")이던 것을 실제 `notifyAt` 시각 표시로 수정
5. 노션 PRD-05 명세를 "표시 + 수정"으로 업데이트 필요 (잔여)

---

## 3. 업데이트 내역 정리 — 문서 · 우선순위 중간

**현상**
버전별 변경 내역이 정리돼 있지 않았다.

**처리 내역 (완료)**
- [CHANGELOG.md](CHANGELOG.md)에 git 이력 기반 업데이트 내역 정리
- 노션 "앱 버전 관리" DB에 1.0.0 (빌드 2) 항목 등록
- 이후 릴리즈마다 CHANGELOG.md와 노션 버전 DB를 함께 갱신하는 것을 규칙으로 함

---

## 4. 위젯 개발 — 신규 · 우선순위 중간

**현상**
홈 화면 위젯과 macOS 메뉴바 위젯이 없다. 기획서 3단계(고도화) 항목.

**개선 계획**
1. **Widget Extension 타깃 추가** (`project.yml`에 WidgetKit extension 정의)
2. **App Group 설정** — 메인 앱과 위젯이 SwiftData 저장소를 공유하려면 `group.com.zerohyeon.jday` App Group + `ModelConfiguration(groupContainer:)` 필요. 기존 기본 위치 저장소에서 App Group 컨테이너로 마이그레이션 필요 (기존 데이터 이동 처리 주의)
3. **위젯 종류 (1차)**
   - 소형: 오늘 남은 할 일 개수 + 진행률
   - 중형: 오늘 할 일 상위 3개 + 다음 일정
4. **인터랙션**: iOS 17 `AppIntent` 기반 위젯 버튼으로 할 일 완료 체크
5. **macOS 메뉴바**: `MenuBarExtra` 씬으로 오늘 할 일/일정 빠른 확인 (WidgetKit과 별개로 앱 내 구현 가능해 난이도 낮음 — 먼저 진행 권장)
6. 데이터 변경 시 `WidgetCenter.shared.reloadAllTimelines()` 호출

---

## 5. Apple 캘린더 · 미리 알림 연동 (EventKit) — 검토 · 우선순위 중간

**검토 결과: 연동 가능**

| 항목 | 내용 |
|------|------|
| 프레임워크 | EventKit (`EKEventStore`) — iOS/macOS 공통 |
| 캘린더 | `EKEvent` 읽기/쓰기 모두 가능 |
| 미리 알림 | `EKReminder` 읽기/쓰기 모두 가능 |
| 권한 (iOS 17+) | `NSCalendarsFullAccessUsageDescription`, `NSRemindersFullAccessUsageDescription` Info.plist 키 + `requestFullAccessToEvents()` / `requestFullAccessToReminders()` |
| 읽기 전용 옵션 | 캘린더는 `requestWriteOnlyAccessToEvents()`도 제공 — 최소 권한 원칙 적용 가능 |

**적용 방안 (단계적)**
1. **1차 — 읽기 통합**: Apple 캘린더 일정을 Jday 캘린더/홈 타임라인에 함께 표시 (Jday `Schedule`과 시각적으로 구분, 예: 회색 칩)
2. **2차 — 내보내기**: Jday에서 만든 일정을 Apple 캘린더에 선택적으로 추가
3. **미리 알림**: Jday 할 일 ↔ 미리 알림 양방향 동기화는 충돌 처리 복잡도가 높아 후순위. 우선 "미리 알림 가져오기" 단방향부터
4. 설정 화면에 연동 토글 + 권한 요청 배너 추가
5. 주의: EventKit 데이터는 CloudKit 동기화 대상이 아니므로 기기별로 각각 권한 필요

---

## 6. 회사/개인 공간 분리 시 기존 데이터가 사라짐 — 버그 · ✅ 완료 (2026-07-08)

**현상**
설정에서 "회사/개인 공간 분리"를 켜면 분리 이전에 만든 항목이 화면에서 전부 사라진다. 기존 항목은 "개인"으로 표시돼야 한다.

**원인 분석 (확인됨)**
분리 OFF 상태에서 저장된 항목은 `workspace == nil`(미분류)이다. [Workspace.swift:40](../Jday/Models/Workspace.swift)의 필터가 엄격 비교를 사용한다:

```swift
func workspaceFiltered(enabled: Bool, active: Workspace) -> [Element] {
    guard enabled else { return self }
    return self.filter { $0.workspace == active }   // nil은 어느 공간에도 매칭 안 됨
}
```

분리를 켜는 순간 `nil` 항목은 개인/회사 어느 필터에도 걸리지 않아 화면에서 사라진다. 데이터가 삭제된 것은 아니고 **표시만 안 되는 것**이다.

**처리 내역 (✅ 완료, 2026-07-08)**
1안(표시 규칙 변경)으로 수정 완료. [Workspace.swift](../Jday/Models/Workspace.swift)의 `workspaceFiltered`가 `($0.workspace ?? .personal) == active`로 비교해 미분류(nil) 항목은 항상 "개인" 공간에 표시된다. 마이그레이션 불필요, CloudKit 레이스 위험 없음.

---

## 7. iCloud로 iPad ↔ iPhone 동기화 안 됨 — 버그 · 🔄 코드 개선 완료, 실기기 검증 잔여

**현상**
iPad와 iPhone 간 데이터가 동기화되지 않는다. (참고: "별도의 폴더가 생성되지 않음" — CloudKit은 iCloud Drive에 보이는 폴더를 만들지 않는 것이 정상. 설정 > Apple ID > iCloud > 앱 목록에서 확인해야 함)

**원인 후보 분석**
1. **조용한 로컬 폴백**: [JdayApp.swift:20-33](../Jday/App/JdayApp.swift)에서 CloudKit 컨테이너 생성 실패 시 아무 표시 없이 로컬 전용으로 폴백한다. 한 기기라도 폴백되면 동기화가 안 되는데 사용자는 알 방법이 없다.
2. **엔타이틀먼트/서명**: `aps-environment`가 `development` — TestFlight/App Store 빌드는 원격 알림(동기화 푸시)이 production 환경이어야 함. 프로비저닝에 iCloud capability가 포함됐는지 확인 필요.
3. **CloudKit 스키마 배포**: 개발 환경에서만 스키마가 생성되고 Production 환경으로 배포(Deploy Schema)하지 않으면 배포 빌드에서 동기화 실패.
4. **기기 설정**: 각 기기에서 동일 Apple ID 로그인 + 설정 > iCloud > Jday 토글 ON 여부.
5. **Background Modes**: `remote-notification` background mode가 없으면 백그라운드 푸시 기반 즉시 동기화가 안 되고 앱 실행 시에만 동기화됨.

**처리 내역 (🔄 코드 개선 완료, 검증 잔여 — 2026-07-08)**
1. ✅ [CloudSyncStatus.swift](../Jday/Core/Services/CloudSyncStatus.swift) 신규 — 저장소 모드(CloudKit/로컬 전용/인메모리) 추적 + `CKContainer.accountStatus()` 확인
2. ✅ [JdayApp.swift](../Jday/App/JdayApp.swift) — 폴백 발생 시 `Logger`로 에러 기록 + 모드 기록
3. ✅ [SettingsView.swift](../Jday/Features/Settings/SettingsView.swift) — "iCloud" 섹션 추가: 동기화 상태(사용 중/로그인 필요/로컬 전용/오류) 표시 + 미로그인 안내
4. ✅ `UIBackgroundModes: [remote-notification]` 추가 (project.yml → Info.plist) — CloudKit 변경 푸시로 백그라운드 즉시 동기화

**잔여 확인 사항 (수동)**
- [ ] CloudKit Console에서 Production 환경으로 스키마 배포(Deploy Schema Changes) 확인 — 배포 빌드 동기화의 필수 조건
- [ ] 실기기 2대(iPhone + iPad)에서 동일 Apple 계정으로 동기화 검증 (설정 화면의 동기화 상태가 "동기화 사용 중"인지 확인)
- [ ] `aps-environment`는 개발 서명 시 `development`가 정상 — App Store 배포 시 Xcode가 자동으로 production 전환

---

## 우선순위 요약

| # | 항목 | 유형 | 상태 |
|---|------|------|------|
| 6 | 작업 공간 분리 시 기존 데이터 미표시 | 버그 | ✅ 완료 (2026-07-08) |
| 7 | iCloud 기기 간 동기화 안 됨 | 버그 | 🔄 코드 개선 완료, 실기기 검증 잔여 |
| 2 | 이슈 수정 기능 | 신규 | ✅ 완료 (2026-07-08) |
| 1 | 캘린더 좌우 스와이프 | 개선 | ✅ 완료 (2026-07-08) |
| 4 | 위젯 개발 | 신규 | 시작 전 (중간) |
| 5 | EventKit 연동 | 신규 | 시작 전 (중간) |
| 3 | 업데이트 내역 정리 | 문서 | ✅ 완료 |
