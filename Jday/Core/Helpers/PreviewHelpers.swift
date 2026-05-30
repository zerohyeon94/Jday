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
}
