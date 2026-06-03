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
