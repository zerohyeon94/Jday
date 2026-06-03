import SwiftData
import Foundation

@MainActor
enum PreviewHelpers {
    static func makeContainer() -> ModelContainer {
        let schema = Schema([DailyTask.self, Schedule.self, Issue.self])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        let container = try! ModelContainer(for: schema, configurations: config)

        let context = container.mainContext

        let now = Date()
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: now)!

        // 샘플 DailyTask — 회사/개인 양쪽 (분리 검증용)
        let workTask1 = DailyTask(title: "기획서 검토", detail: "2장 사용자 시나리오 위주로 확인", date: now, priority: .high, workspace: .work)
        let workTask2 = DailyTask(title: "디자인 피드백", date: now, priority: .medium, workspace: .work)
        let personalTask1 = DailyTask(title: "장보기", date: now, priority: .medium, workspace: .personal)
        let personalTask2 = DailyTask(title: "운동하기", date: now, priority: .low, workspace: .personal)
        personalTask2.setDone(true) // 완료 시각 기록
        let workOld = DailyTask(title: "어제 미완료 보고서", date: yesterday, priority: .medium, workspace: .work)

        [workTask1, workTask2, personalTask1, personalTask2, workOld].forEach(context.insert)

        // 샘플 Schedule — 회사/개인
        let startTime = Calendar.current.date(byAdding: .hour, value: 2, to: now)!
        let endTime = Calendar.current.date(byAdding: .hour, value: 3, to: now)!
        let workMeeting = Schedule(title: "팀 미팅", startTime: startTime, endTime: endTime, location: "회의실 A", workspace: .work)
        context.insert(workMeeting)

        let dinnerStart = Calendar.current.date(byAdding: .hour, value: 6, to: now)!
        let dinnerEnd = Calendar.current.date(byAdding: .hour, value: 8, to: now)!
        let personalDinner = Schedule(title: "친구 저녁 약속", startTime: dinnerStart, endTime: dinnerEnd, location: "강남", workspace: .personal)
        context.insert(personalDinner)

        // 여러 날에 걸친 일정(출장) — 어제부터 내일까지 (회사)
        let tripStart = Calendar.current.date(byAdding: .day, value: -1, to: now)!
        let tripEnd = Calendar.current.date(byAdding: .day, value: 1, to: now)!
        let trip = Schedule(title: "출장 (3일)", startTime: tripStart, endTime: tripEnd, location: "부산", workspace: .work)
        context.insert(trip)

        // 샘플 Issue — 회사/개인
        context.insert(Issue(title: "로그인 버그", detail: "특정 기기에서 로그인 실패", workspace: .work))
        context.insert(Issue(title: "집 인터넷 AS 문의", workspace: .personal))

        return container
    }

    // MARK: - App Store 스크린샷용 데모 데이터 (공간 분리 OFF, 풍부한 콘텐츠)

    static func makeStoreDemoContainer() -> ModelContainer {
        let schema = Schema([DailyTask.self, Schedule.self, Issue.self])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        let container = try! ModelContainer(for: schema, configurations: config)
        let context = container.mainContext
        let cal = Calendar.current
        let now = Date()
        let today = cal.startOfDay(for: now)

        func time(_ day: Date, _ h: Int, _ m: Int) -> Date {
            cal.date(bySettingHour: h, minute: m, second: 0, of: day) ?? day
        }
        func day(_ offset: Int) -> Date {
            cal.date(byAdding: .day, value: offset, to: today) ?? today
        }

        // 오늘 할 일 — 진행률이 보기 좋게 (6개 중 3개 완료 = 50%)
        let doneTitles: [(String, Priority, Int, Int)] = [
            ("디자인 시스템 컴포넌트 정리", .high, 9, 15),
            ("주간 회고 작성", .medium, 10, 40),
            ("아침 스트레칭", .low, 8, 0)
        ]
        for (title, p, h, m) in doneTitles {
            let t = DailyTask(title: title, date: time(today, h, m), priority: p)
            t.setDone(true)
            t.completedAt = time(today, h, m)
            context.insert(t)
        }
        let pending: [(String, String?, Priority, Int)] = [
            ("스프린트 리뷰 발표 준비", "데모 시나리오 3개 + 지표 슬라이드", .high, 13),
            ("API 연동 통합 테스트", nil, .medium, 15),
            ("운동 30분", "퇴근 후 헬스장", .low, 19)
        ]
        for (title, detail, p, h) in pending {
            context.insert(DailyTask(title: title, detail: detail, date: time(today, h, 0), priority: p))
        }

        // 어제 미완료 (홈 섹션 노출용)
        context.insert(DailyTask(title: "릴리즈 노트 초안", date: time(day(-1), 17, 0), priority: .medium))
        context.insert(DailyTask(title: "팀 이메일 회신", date: time(day(-1), 18, 0), priority: .low))

        // 오늘 일정 타임라인 — 지난 일정으로 흐려지지 않도록 "지금 이후"로 배치
        let baseHour = cal.component(.hour, from: now) + 1
        let todaySchedules: [(String, Int, String)] = [
            ("데일리 스탠드업", 0, "회의실 A · 15분"),
            ("디자인 리뷰", 1, "김지원 외 3명"),
            ("1:1 미팅", 2, "박서준"),
            ("제품 기획 회의", 3, "전체 · 1시간")
        ]
        for (title, offset, loc) in todaySchedules where baseHour + offset <= 22 {
            let sh = baseHour + offset
            context.insert(Schedule(title: title, startTime: time(today, sh, 0), endTime: time(today, sh, 45), location: loc))
        }

        // 여러 날 일정(캘린더 이어지는 막대) + 이번 달 곳곳의 단일 일정(도트)
        context.insert(Schedule(title: "제주 워크숍", startTime: time(day(2), 9, 0), endTime: time(day(4), 18, 0), location: "제주"))
        let monthEvents: [(Int, String, Int)] = [
            (-6, "분기 OKR 리뷰", 14), (-3, "디자인 QA", 11), (3, "스프린트 플래닝", 10),
            (6, "고객 인터뷰", 15), (9, "배포 점검", 16), (12, "회고", 17)
        ]
        for (off, title, h) in monthEvents {
            context.insert(Schedule(title: title, startTime: time(day(off), h, 0), endTime: time(day(off), h + 1, 0), location: "온라인"))
        }

        // 이슈 — 미해결/해결완료 혼합
        let unresolved: [(String, String?)] = [
            ("결제 플로우 결제 버튼 무반응", "iOS 17 일부 기기에서 결제 버튼을 눌러도 다음 화면으로 넘어가지 않음. 재현율 약 40%."),
            ("다크모드에서 카드 색상 깨짐", "다크모드 전환 시 일부 카드 배경이 흰색으로 남음."),
            ("로그인 세션이 5분 만에 만료됨", nil)
        ]
        for (i, (title, detail)) in unresolved.enumerated() {
            let issue = Issue(title: title, detail: detail, notifyAt: time(day(-i), 9, 12))
            issue.createdAt = time(day(-i - 1), 9, 12)
            context.insert(issue)
        }
        for (i, title) in ["푸시 알림 도착 지연", "이미지 업로드 간헐적 실패"].enumerated() {
            let issue = Issue(title: title)
            issue.isResolved = true
            issue.createdAt = time(day(-i - 4), 14, 0)
            context.insert(issue)
        }

        return container
    }

    // MARK: - 컴포넌트 프리뷰용 샘플 데이터

    static var sampleTasks: [DailyTask] {
        let done = DailyTask(title: "디자인 시안 검토")
        done.isDone = true
        return [
            done,
            DailyTask(title: "API 명세서 작성"),
            DailyTask(title: "주간 리포트 초안")
        ]
    }

    static var sampleYesterdayTasks: [DailyTask] {
        [
            DailyTask(title: "사용자 인터뷰 노트 정리"),
            DailyTask(title: "결제 플로우 버그 재현"),
            DailyTask(title: "스프린트 회고 메모")
        ]
    }

    static var sampleSchedules: [Schedule] {
        let now = Date()
        func at(_ h: Int, _ m: Int) -> Date {
            Calendar.current.date(bySettingHour: h, minute: m, second: 0, of: now) ?? now
        }
        return [
            Schedule(title: "데일리 스탠드업", startTime: at(9, 0), endTime: at(9, 15), location: "회의실 A · 15분"),
            Schedule(title: "디자인 리뷰", startTime: at(11, 0), endTime: at(12, 0), location: "김지원 외 3명")
        ]
    }

    static var sampleIssue: Issue {
        Issue(
            title: "결제 플로우 결제 버튼 무반응",
            detail: "iOS 17 일부 기기에서 결제 버튼을 눌러도 다음 화면으로 넘어가지 않음. 재현율 약 40%.",
            notifyAt: .now
        )
    }
}
