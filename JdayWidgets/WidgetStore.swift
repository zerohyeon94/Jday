import Foundation
import SwiftData
import WidgetKit
import OSLog

private let logger = Logger(subsystem: "com.j.jday", category: "Widget")

/// 위젯 익스텐션에서 App Group의 SwiftData 저장소를 읽는다.
/// CloudKit 동기화는 메인 앱만 수행 — 익스텐션은 로컬 파일만 사용한다(cloudKitDatabase: .none).
enum WidgetStore {
    static let container: ModelContainer? = {
        let schema = Schema([DailyTask.self, Schedule.self, Issue.self, Retrospective.self])
        let config = ModelConfiguration(schema: schema, groupContainer: .identifier(AppGroup.id), cloudKitDatabase: .none)
        do {
            return try ModelContainer(for: schema, configurations: config)
        } catch {
            logger.error("위젯 ModelContainer 생성 실패: \(error.localizedDescription)")
            return nil
        }
    }()

    /// 주어진 시각 기준으로 오늘 할 일·일정, 이번 달 이벤트 도트를 조회해 엔트리를 만든다.
    static func makeEntry(for date: Date) -> JdayTimelineEntry {
        guard let container else { return .empty(date: date) }
        let context = ModelContext(container)
        let wsEnabled = AppGroup.defaults.bool(forKey: "workspaceSeparationEnabled")
        let wsActive = Workspace(rawValue: AppGroup.defaults.string(forKey: "activeWorkspace") ?? "") ?? .personal

        let dayStart = date.startOfDay
        let dayEnd = date.endOfDay

        var tasks: [DailyTask] = []
        do {
            let predicate = #Predicate<DailyTask> { $0.date >= dayStart && $0.date <= dayEnd }
            tasks = try context.fetch(FetchDescriptor(predicate: predicate, sortBy: [SortDescriptor(\.createdAt)]))
        } catch {
            logger.error("위젯 할 일 조회 실패: \(error.localizedDescription)")
        }

        var schedules: [Schedule] = []
        do {
            let predicate = #Predicate<Schedule> { $0.startTime < dayEnd && $0.endTime > dayStart }
            schedules = try context.fetch(FetchDescriptor(predicate: predicate, sortBy: [SortDescriptor(\.startTime)]))
        } catch {
            logger.error("위젯 일정 조회 실패: \(error.localizedDescription)")
        }

        let filteredTasks = tasks.workspaceFiltered(enabled: wsEnabled, active: wsActive)
            .sorted { !$0.isDone && $1.isDone }
        let filteredSchedules = schedules.workspaceFiltered(enabled: wsEnabled, active: wsActive)

        let taskItems = filteredTasks.map {
            WidgetTaskItem(id: encodeID($0.persistentModelID), title: $0.title, isDone: $0.isDone, priority: $0.priority)
        }
        let scheduleItems = filteredSchedules.map {
            WidgetScheduleItem(id: encodeID($0.persistentModelID), title: $0.title, startTime: $0.startTime, endTime: $0.endTime)
        }

        return JdayTimelineEntry(
            date: date,
            tasks: taskItems,
            schedules: scheduleItems,
            eventDays: eventDays(in: date, context: context, wsEnabled: wsEnabled, wsActive: wsActive)
        )
    }

    /// 이번 달에서 일정이 하나라도 있는 날짜(일) 집합.
    private static func eventDays(in date: Date, context: ModelContext, wsEnabled: Bool, wsActive: Workspace) -> Set<Int> {
        let calendar = Calendar.current
        guard let monthInterval = calendar.dateInterval(of: .month, for: date),
              let dayRange = calendar.range(of: .day, in: .month, for: date) else { return [] }

        let monthStart = monthInterval.start
        let monthEnd = monthInterval.end
        var schedules: [Schedule] = []
        do {
            let predicate = #Predicate<Schedule> { $0.startTime < monthEnd && $0.endTime > monthStart }
            schedules = try context.fetch(FetchDescriptor(predicate: predicate))
        } catch {
            logger.error("위젯 월간 일정 조회 실패: \(error.localizedDescription)")
        }
        let filtered = schedules.workspaceFiltered(enabled: wsEnabled, active: wsActive)
        guard !filtered.isEmpty else { return [] }

        var days = Set<Int>()
        for day in dayRange {
            guard let dayDate = calendar.date(byAdding: .day, value: day - 1, to: monthStart) else { continue }
            if filtered.contains(where: { $0.occurs(on: dayDate) }) {
                days.insert(day)
            }
        }
        return days
    }

    static func encodeID(_ id: PersistentIdentifier) -> String {
        guard let data = try? JSONEncoder().encode(id) else { return "" }
        return String(decoding: data, as: UTF8.self)
    }

    static func decodeID(_ string: String) -> PersistentIdentifier? {
        try? JSONDecoder().decode(PersistentIdentifier.self, from: Data(string.utf8))
    }
}

/// 모든 위젯이 공유하는 타임라인 — 현재 시각 + 오늘 일정 경계 시각 + 자정 갱신.
struct JdayTimelineProvider: TimelineProvider {
    func placeholder(in context: Context) -> JdayTimelineEntry {
        .preview
    }

    func getSnapshot(in context: Context, completion: @escaping (JdayTimelineEntry) -> Void) {
        completion(context.isPreview ? .preview : WidgetStore.makeEntry(for: .now))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<JdayTimelineEntry>) -> Void) {
        let now = Date()
        let entry = WidgetStore.makeEntry(for: now)

        // "다음 일정" 표시가 일정 시작/종료 시각마다 갱신되도록 경계 시각에 엔트리 추가
        var dates: Set<Date> = [now]
        for schedule in entry.schedules {
            for boundary in [schedule.startTime, schedule.endTime] where boundary > now && boundary < now.endOfDay {
                dates.insert(boundary)
            }
        }
        let entries = dates.sorted().map { entry.with(date: $0) }
        let nextMidnight = now.endOfDay.addingTimeInterval(1)
        completion(Timeline(entries: entries, policy: .after(nextMidnight)))
    }
}
