# Jday 업데이트 내역

*git 커밋 이력 기반으로 정리한 변경 내역입니다. 최신이 위에 옵니다.*

## [미배포] Apple Pencil 필기 메모 (2026-07-19)

### 신규
- 할 일·일정·이슈에 필기 메모 첨부 (iOS/iPadOS)
  - 상세/수정 화면에 "필기 추가" → PencilKit 캔버스 시트 (iPad는 Apple Pencil + 도구 팔레트, iPhone은 손가락)
  - 미리보기 탭으로 수정, 삭제 가능. 이슈 상세에는 읽기 전용 카드 표시
- `drawingData` 필드 추가 (DailyTask·Schedule·Issue, externalStorage) — CloudKit으로 기기 간 동기화
- macOS는 보기 전용 (이미지 렌더링), 수정은 iPhone·iPad에서

## [미배포] Apple 캘린더 연동 1단계 (2026-07-19)

### 신규
- Apple 캘린더 읽기 표시 (iOS/iPadOS) — 설정 > 연동 > "Apple 캘린더 표시" 토글
  - 홈·캘린더 화면에 Apple 캘린더 일정을 읽기 전용 카드로 표시 (캘린더 색상·이름 구분)
  - 캘린더 선택 (전체 표시 기본, 개별 선택 가능), 캘린더 앱에서 변경 시 자동 반영
  - 캘린더 월간 그리드 이벤트 도트에 Apple 캘린더 일정 포함
- iOS 17 권한 모델 적용 (`NSCalendarsFullAccessUsageDescription`), 거부 시 설정 화면에 안내 + 시스템 설정 바로가기

### 기타
- macOS 표시는 후속 (설정 토글은 iOS에서만 노출)
- 내보내기(2단계)·양방향(3단계)·미리 알림 연동은 [widgets-and-integrations-plan.md](widgets-and-integrations-plan.md) 로드맵 참고

## [미배포] 위젯 추가 (2026-07-19)

### 신규
- WidgetKit 위젯 4종 (iOS/iPadOS 17+, `JdayWidgets` 익스텐션 타겟)
  - 홈 소형 "오늘 요약" (진행률 링) / 중형 "오늘 할 일" (위젯에서 바로 완료 체크 — AppIntents) / 대형 "월간 캘린더"
  - 잠금화면 원형(진행률 Gauge)·직사각형·인라인 "오늘 브리핑"
- 앱 백그라운드 전환 시 위젯 타임라인 자동 갱신

### 기타
- iOS SwiftData 저장소를 App Group(`group.com.zerohyeon.jday`) 컨테이너로 이전 — 기존 저장소는 최초 실행 시 자동 이동(실패 시 기존 위치 유지)
- 작업 공간·주 시작 요일 설정을 App Group defaults로 이전 (위젯과 공유)
- 설계 문서: [widgets-and-integrations-plan.md](widgets-and-integrations-plan.md)

## [미배포] 버그 수정 및 개선 (2026-07-08)

### 수정
- 회사/개인 공간 분리 시 분리 이전(미분류) 항목이 사라지던 버그 — 미분류 항목을 "개인" 공간으로 표시
- 이슈 상세의 알림 시간이 "30분 전"으로 고정 표시되던 것을 실제 알림 시각으로 표시

### 신규
- 이슈 수정 기능 — 상세 화면 "수정" 버튼으로 제목/상세 내용/알림 시간 편집 (iOS/macOS), 알림 자동 재예약
- 캘린더 좌우 스와이프로 이전/다음 달(주) 이동
- 설정에 "iCloud" 섹션 — 동기화 상태(사용 중/로그인 필요/로컬 전용/오류) 표시

### 기타
- CloudKit 컨테이너 폴백 시 Logger 에러 기록 (기존에는 조용히 로컬 전용 전환)
- `UIBackgroundModes: remote-notification` 추가 — CloudKit 변경 푸시 기반 백그라운드 동기화

## [1.0.0 (빌드 2)] — App Store 제출 준비 (2026-06-08 ~ 2026-06-27)

### 수정
- iPad 멀티태스킹 대응을 위한 `UISupportedInterfaceOrientations` 명시
- App Store 아카이브를 위한 `LSApplicationCategoryType` 추가
- CloudKit 비호환 모델로 인한 실행 크래시 해결 + macOS 샌드박스 엔타이틀먼트 정리

### 기타
- CloudKit / 푸시 엔타이틀먼트 구성 (`iCloud.com.zerohyeon.jday`)
- App Store 제출 가이드 문서 추가 ([AppStoreSubmission.md](../AppStoreSubmission.md))
- iPadOS App Store 스크린샷 추가
- 시드 프리뷰 실행 지원 (`-seedPreviewData`)
- Xcode 프로젝트 포맷 정규화

## iPad 지원 (2026-06-06 ~ 2026-06-08)

### 신규
- iPad 전용 루트 뷰 분리 (`iPadRootView`)
- iPad 사이드바 레이아웃 적용 (iPadOS 디자인 반영)
- iPad 빠른 추가/툴바를 iPadOS 디자인에 맞춤

### 수정
- iPad 사이드바 하단 잘림 + 헤더 배경 이질감 해결
- 잘못 추가된 Jday_iPadOS 타깃 제거, 서명 정보 project.yml 반영

### 기타
- 로그인/로그아웃·계정 표시 제거 (인증 미사용)
- 설정 아이콘을 톱니바퀴(gearshape)로 변경

## 작업 공간 · 캘린더 고도화 (2026-06-03 ~ 2026-06-05)

### 신규
- 회사/개인 작업 공간 분리 (옵션 A: 엄격 분리)
- 작업 공간 토글·일정 상세·빠른 추가 컨텍스트 반영
- macOS 캘린더에서 여러 날 일정을 이어지는 막대로 표시
- 할 일 컨텍스트 메뉴 (완료/상세/삭제) + macOS 삭제 지원
- iOS 끝까지 밀면 즉시 삭제 + 컨텍스트 메뉴에서 우선순위/날짜 변경
- 오늘 할 일 스와이프 삭제 + 실행 취소 토스트

### 기타
- 데모 시드 코드 제거 + 전체 검증, App Store 스크린샷 자동화

## 초기 개발 (2026-05-30 ~ 2026-06-02)

### 신규
- 프로젝트 초기 구조 생성 (iOS/macOS Multiplatform)
- DayFlow 디자인 시스템 적용 및 전체 화면 UI 구현
- 설정 화면 모드 (라이트/다크/시스템) 선택
- 홈: 할 일 메모, 상세 시트, 탭바 간격 조정, macOS 로고
- 빠른 추가 시트를 내용에 맞춰 한 번에 표시

### 수정
- 빠른 추가 키보드 점프 수정 + 할 일 우선순위 색상 바 표시
- 낮음 우선순위 색상 회색→파랑 변경
- 할 일 완료 시 제목 줄바꿈 현상 수정
