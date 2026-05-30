import SwiftData
import Foundation

@MainActor
enum PreviewHelpers {
    static func makeContainer() -> ModelContainer {
        let schema = Schema([DailyTask.self, Schedule.self, Issue.self])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        let container = try! ModelContainer(for: schema, configurations: config)

        let context = container.mainContext

        // 샘플 DailyTask
        let task1 = DailyTask(title: "기획서 검토", date: .now, priority: .high)
        let task2 = DailyTask(title: "디자인 피드백", date: .now, priority: .medium)
        let task3 = DailyTask(title: "코드 리뷰", date: .now, priority: .low)
        task3.isDone = true

        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: .now)!
        let oldTask = DailyTask(title: "어제 미완료 항목", date: yesterday, priority: .medium)

        context.insert(task1)
        context.insert(task2)
        context.insert(task3)
        context.insert(oldTask)

        // 샘플 Schedule
        let now = Date()
        let startTime = Calendar.current.date(byAdding: .hour, value: 2, to: now)!
        let endTime = Calendar.current.date(byAdding: .hour, value: 3, to: now)!
        let schedule = Schedule(title: "팀 미팅", startTime: startTime, endTime: endTime, location: "회의실 A")
        context.insert(schedule)

        // 샘플 Issue
        let issue = Issue(title: "로그인 버그", detail: "특정 기기에서 로그인 실패")
        context.insert(issue)

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
