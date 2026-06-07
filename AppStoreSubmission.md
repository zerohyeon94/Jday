# Jday App Store Submission

> 기준일: 2026-06-07
> 대상 프로젝트: Jday
> 실제 번들 ID: `com.zerohyeon.jday`
> 플랫폼: iOS / iPadOS / macOS

## 제출 방향

Jday는 "오늘의 업무 흐름을 한곳에서 정리하는 하루 관리 앱"으로 제출한다.

스토어 문구에서는 현재 구현된 기능인 `할 일`, `일정`, `이슈`, `빠른 추가`, `알림`, `개인/회사 작업 공간`, `iPhone/iPad/Mac 화면 구성`을 중심으로 설명한다.

아직 제출 문구에서 강하게 쓰지 않을 것:

- 위젯
- AI 자동 분석
- 이메일 요약
- 팀 협업/공유 기능
- 완전한 프로젝트 관리 도구

이 기능들은 현재 스토어 심사 기준에서 사용자가 바로 확인하기 어렵거나 추후 기능에 가까우므로 1.0.0 설명에는 넣지 않는다.

## App Store 메타데이터 초안

### 앱 이름

```text
Jday
```

### 부제

추천 1순위:

```text
할 일·일정·이슈 관리
```

대안:

```text
오늘 업무를 한 화면에
업무 흐름을 한곳에
오늘 업무와 이슈 관리
```

### 카테고리

```text
주 카테고리: 생산성
보조 카테고리: 비즈니스 또는 유틸리티
```

### 홍보 문구

```text
오늘 할 일, 일정, 이슈를 한곳에서 정리하세요. iPhone, iPad, Mac에서 하루 업무 흐름을 이어갈 수 있습니다.
```

### 짧은 설명

```text
Jday는 오늘 해야 할 일, 일정, 놓치면 안 되는 이슈를 한 화면에서 관리하는 업무용 하루 관리 앱입니다.
```

### 설명

```text
Jday는 매일의 업무 흐름을 한곳에서 정리하기 위한 하루 관리 앱입니다.

할 일, 일정, 이슈를 따로 흩어 놓지 않고 오늘 기준으로 모아 볼 수 있습니다. 아침에는 오늘 남은 할 일과 일정을 확인하고, 업무 중에는 빠른 추가로 떠오른 일이나 이슈를 바로 기록할 수 있습니다.

주요 기능
- 오늘 할 일, 일정, 진행률을 한 화면에서 확인
- 할 일, 일정, 이슈 빠른 추가
- 어제 끝내지 못한 할 일을 오늘로 이동
- 날짜별 일정과 할 일 확인
- 미해결 이슈 관리
- 이슈 및 일정 알림 설정
- 개인/회사 작업 공간 구분
- iPhone, iPad, Mac에 맞춘 화면 구성

Jday는 복잡한 프로젝트 관리 도구보다 가볍고, 기본 캘린더나 미리알림보다 업무 흐름을 함께 보기 쉽게 만드는 데 집중합니다.
```

### 키워드

100자 이하, 쉼표 뒤 공백 없이 입력한다.

```text
업무관리,할일,일정,캘린더,이슈관리,리마인더,생산성,체크리스트,오늘할일,업무일정,개인업무,회사일정
```

### SKU

사용자에게 보이지 않는 내부 식별자다. 아래처럼 단순하게 둔다.

```text
jday-ios-macos-1
```

## 스크린샷 위치

App Store Connect 업로드용 이미지는 아래 폴더를 사용한다.

```text
Screenshots/AppStore/iOS
Screenshots/AppStore/iPadOS
Screenshots/AppStore/macOS
```

현재 준비된 묶음:

- iOS: `01_today_dashboard.png`, `02_quick_add.png`, `03_calendar.png`, `04_issues.png`, `05_settings.png`
- iPadOS: `01_ipad_today_dashboard.png`, `02_ipad_quick_add.png`, `03_ipad_calendar.png`, `04_ipad_issues.png`, `05_ipad_settings.png`
- macOS: `01_mac_today.png`, `02_mac_calendar.png`, `03_mac_quick_add.png`, `04_mac_issues.png`, `05_mac_settings.png`

## 실제 배포 전 필수 확인

### 1. Bundle ID 확정

현재 실제 프로젝트 설정은 아래 값이다.

```text
com.zerohyeon.jday
```

기획 문서의 과거 값인 `com.j.jday`와 다르므로, App Store Connect와 Apple Developer Identifiers에서는 반드시 `com.zerohyeon.jday`를 사용한다.

### 2. Apple Developer Identifier 생성

Apple Developer 사이트의 `Certificates, Identifiers & Profiles > Identifiers` 화면에서 진행한다.

1. `+` 버튼 클릭
2. `App IDs` 선택
3. `App` 선택
4. Description: `Jday`
5. Bundle ID: `Explicit` 선택
6. Bundle ID 입력: `com.zerohyeon.jday`
7. Capabilities 확인
   - iCloud / CloudKit을 실제로 사용할 경우 iCloud capability 활성화
   - 알림을 사용할 경우 Push Notifications 사용 여부 확인
8. Register

주의:

- 프로젝트의 `Jday.entitlements`가 현재 비어 있으므로, Xcode에서 iCloud/CloudKit Capability가 실제로 추가되어 있는지 반드시 확인한다.
- SwiftData `ModelConfiguration(... cloudKitDatabase: .automatic)`만으로는 제출 설정이 끝난 것이 아니다. App ID와 Xcode Signing & Capabilities가 맞아야 한다.

### 3. Xcode Signing & Capabilities 확인

Xcode에서 아래를 확인한다.

```text
Target: Jday_iOS
Bundle Identifier: com.zerohyeon.jday
Version: 1.0.0
Build: 1
Signing Team: 본인 Apple Developer Team
Capabilities:
- iCloud / CloudKit 필요 여부 확인
- Push Notifications 필요 여부 확인
```

macOS target도 같은 기준으로 확인한다.

### 4. App Store Connect 앱 레코드 생성

App Store Connect의 `Apps`에서 진행한다.

1. `+` 버튼 클릭
2. `New App` 선택
3. Platforms: iOS, macOS 선택
4. Name: `Jday`
5. Primary Language: `Korean`
6. Bundle ID: `com.zerohyeon.jday`
7. SKU: `jday-ios-macos-1`
8. User Access: 보통 `Full Access`
9. Create

### 5. 개인정보 처리방침 URL 준비

iOS/macOS 앱에는 개인정보 처리방침 URL이 필요하다.

Jday는 현재 아래 데이터를 기기와 iCloud에 저장할 수 있다.

- 할 일 제목/메모/날짜/우선순위/완료 여부
- 일정 제목/시간/장소
- 이슈 제목/상세/알림 시간/해결 여부
- 개인/회사 작업 공간 구분
- 알림 설정

개인정보 처리방침에는 최소한 아래를 적는다.

- 수집/저장되는 데이터 종류
- 데이터가 사용자의 기기 및 iCloud에 저장될 수 있다는 점
- 계정/서버를 별도로 운영하지 않는다면 개발자 서버로 전송하지 않는다는 점
- 데이터 삭제 방법
- 문의 이메일

### 6. Archive 및 업로드

Xcode에서 진행한다.

1. Scheme 선택
2. Destination을 `Any iOS Device` 또는 배포 대상에 맞게 선택
3. `Product > Archive`
4. Organizer에서 Archive 선택
5. `Validate App`
6. 문제가 없으면 `Distribute App`
7. `App Store Connect` 선택
8. Upload

업로드 후 App Store Connect에서 빌드 처리가 끝날 때까지 기다린다.

### 7. App Store Connect 제출 정보 입력

각 플랫폼 버전에 아래를 채운다.

- 앱 이름
- 부제
- 설명
- 키워드
- 홍보 문구
- 카테고리
- 지원 URL
- 개인정보 처리방침 URL
- 스크린샷
- 앱 개인정보 보호 항목
- 연령 등급
- 가격 및 배포 지역
- 빌드 선택
- 심사 메모

심사 메모 예시:

```text
Jday는 할 일, 일정, 이슈를 로컬 및 iCloud 기반으로 관리하는 생산성 앱입니다.
로그인 없이 사용할 수 있으며, 알림 권한은 이슈와 일정 리마인더에 사용됩니다.
```

### 8. 첫 제출 전 점검

- [ ] `com.zerohyeon.jday` App ID 생성 완료
- [ ] Xcode Bundle Identifier와 App Store Connect Bundle ID 일치
- [ ] iCloud/CloudKit 사용 여부 확정
- [ ] entitlements에 필요한 capability 반영
- [ ] Version `1.0.0`, Build `1` 확인
- [ ] iOS/iPadOS/macOS 핵심 화면 1회 실행 확인
- [ ] 알림 권한 거부 상태에서도 앱 사용 가능 확인
- [ ] iCloud 미로그인 상태에서 앱이 로컬 폴백으로 동작하는지 확인
- [ ] 개인정보 처리방침 URL 준비
- [ ] 지원 URL 준비
- [ ] App Privacy 작성
- [ ] App Store 스크린샷 업로드
- [ ] Archive Validate 통과
- [ ] App Store Connect 빌드 처리 완료

## 참고 링크

- App Store Connect 앱 레코드 생성: https://developer.apple.com/help/app-store-connect/create-an-app-record/add-a-new-app/
- Apple Developer App ID 등록: https://developer.apple.com/help/account/identifiers/register-an-app-id/
- App capabilities 설정: https://developer.apple.com/help/account/identifiers/enable-app-capabilities/
- 빌드 업로드: https://developer.apple.com/help/app-store-connect/manage-builds/upload-builds/
- App Store 상품 페이지 작성: https://developer.apple.com/app-store/product-page/
