import Foundation
import SwiftData
import OSLog

private let logger = Logger(subsystem: "com.j.jday", category: "CalendarViewModel")

enum CalendarDisplayMode: String, CaseIterable {
    case weekly = "주간"
    case monthly = "월간"
}

@MainActor
final class CalendarViewModel: ObservableObject {
    @Published var displayMode: CalendarDisplayMode = .monthly
    @Published var selectedDate: Date = .now

    func tasksFor(date: Date, tasks: [DailyTask]) -> [DailyTask] {
        tasks.filter { $0.date.isSameDay(as: date) }
    }

    /// 해당 날짜와 기간이 겹치는 일정(여러 날 일정 포함)을 시간순으로 반환.
    func schedulesFor(date: Date, schedules: [Schedule]) -> [Schedule] {
        schedules
            .filter { $0.occurs(on: date) }
            .sorted { $0.startTime < $1.startTime }
    }

    /// 해당 날짜에 완료(completedAt)된 할 일을 완료 시각순으로 반환.
    func completedTasksFor(date: Date, tasks: [DailyTask]) -> [DailyTask] {
        tasks
            .filter { task in
                guard let completedAt = task.completedAt else { return false }
                return completedAt.isSameDay(as: date)
            }
            .sorted { ($0.completedAt ?? .distantPast) < ($1.completedAt ?? .distantPast) }
    }

    func daysInMonth(for date: Date) -> [Date] {
        guard let range = Calendar.current.range(of: .day, in: .month, for: date),
              let firstDay = Calendar.current.date(from: Calendar.current.dateComponents([.year, .month], from: date))
        else { return [] }

        return range.compactMap { day in
            Calendar.current.date(byAdding: .day, value: day - 1, to: firstDay)
        }
    }

    func daysInWeek(for date: Date) -> [Date] {
        guard let interval = Calendar.current.dateInterval(of: .weekOfYear, for: date) else { return [] }
        return (0..<7).compactMap {
            Calendar.current.date(byAdding: .day, value: $0, to: interval.start)
        }
    }

    func goToToday() {
        selectedDate = .now
    }

    func eventCount(on date: Date, tasks: [DailyTask], schedules: [Schedule]) -> (tasks: Int, schedules: Int) {
        let t = tasks.filter { $0.date.isSameDay(as: date) }.count
        let s = schedules.filter { $0.occurs(on: date) }.count
        return (t, s)
    }

    func hasEvents(on date: Date, tasks: [DailyTask], schedules: [Schedule]) -> Bool {
        let hasTasks = tasks.contains { $0.date.isSameDay(as: date) }
        let hasSchedules = schedules.contains { $0.occurs(on: date) }
        return hasTasks || hasSchedules
    }

    /// 해당 날짜에 완료된 할 일이 있는지(셀 완료 마커용).
    func hasCompletions(on date: Date, tasks: [DailyTask]) -> Bool {
        tasks.contains { ($0.completedAt?.isSameDay(as: date)) == true }
    }
}
