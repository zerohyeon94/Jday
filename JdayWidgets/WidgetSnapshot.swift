import Foundation
import WidgetKit

/// 위젯에 표시할 할 일 스냅샷. @Model을 위젯 뷰로 직접 넘기지 않고 값 타입으로 변환한다.
struct WidgetTaskItem: Identifiable, Hashable {
    /// PersistentIdentifier를 JSON 인코딩한 문자열 — ToggleTaskIntent에서 역참조에 사용.
    let id: String
    let title: String
    let isDone: Bool
    let priority: Priority
}

/// 위젯에 표시할 일정 스냅샷.
struct WidgetScheduleItem: Identifiable, Hashable {
    let id: String
    let title: String
    let startTime: Date
    let endTime: Date
}

struct JdayTimelineEntry: TimelineEntry {
    let date: Date
    /// 오늘 할 일 — 미완료 먼저, 생성 순 정렬.
    let tasks: [WidgetTaskItem]
    /// 오늘 일정 — 시작 시각 순 정렬.
    let schedules: [WidgetScheduleItem]
    /// 이번 달에서 일정이 있는 날짜(일).
    let eventDays: Set<Int>

    var remainingCount: Int { tasks.filter { !$0.isDone }.count }
    var doneCount: Int { tasks.count - remainingCount }
    var progress: Double { tasks.isEmpty ? 0 : Double(doneCount) / Double(tasks.count) }
    /// 아직 끝나지 않은 가장 가까운 일정.
    var nextSchedule: WidgetScheduleItem? { schedules.first { $0.endTime > date } }

    /// 같은 데이터로 시각만 바꾼 엔트리 — 일정 경계 시각용 타임라인 생성에 사용.
    func with(date newDate: Date) -> JdayTimelineEntry {
        JdayTimelineEntry(date: newDate, tasks: tasks, schedules: schedules, eventDays: eventDays)
    }

    static func empty(date: Date) -> JdayTimelineEntry {
        JdayTimelineEntry(date: date, tasks: [], schedules: [], eventDays: [])
    }

    /// 위젯 갤러리 미리보기용 샘플.
    static var preview: JdayTimelineEntry {
        let now = Date()
        let calendar = Calendar.current
        let today = calendar.component(.day, from: now)
        return JdayTimelineEntry(
            date: now,
            tasks: [
                WidgetTaskItem(id: "1", title: String(localized: "주간 보고서 작성"), isDone: false, priority: .high),
                WidgetTaskItem(id: "2", title: String(localized: "디자인 리뷰 준비"), isDone: false, priority: .medium),
                WidgetTaskItem(id: "3", title: String(localized: "운동 30분"), isDone: true, priority: .low)
            ],
            schedules: [
                WidgetScheduleItem(
                    id: "s1",
                    title: String(localized: "팀 미팅"),
                    startTime: calendar.date(bySettingHour: 14, minute: 0, second: 0, of: now) ?? now,
                    endTime: calendar.date(bySettingHour: 15, minute: 0, second: 0, of: now) ?? now
                )
            ],
            eventDays: [today, min(today + 3, 28)]
        )
    }
}
