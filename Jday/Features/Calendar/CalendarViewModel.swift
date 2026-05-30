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

    func schedulesFor(date: Date, schedules: [Schedule]) -> [Schedule] {
        schedules.filter { $0.startTime.isSameDay(as: date) }
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
        let s = schedules.filter { $0.startTime.isSameDay(as: date) }.count
        return (t, s)
    }

    func hasEvents(on date: Date, tasks: [DailyTask], schedules: [Schedule]) -> Bool {
        let hasTasks = tasks.contains { $0.date.isSameDay(as: date) }
        let hasSchedules = schedules.contains { $0.startTime.isSameDay(as: date) }
        return hasTasks || hasSchedules
    }
}
