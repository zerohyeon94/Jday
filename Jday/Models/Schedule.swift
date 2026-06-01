import Foundation
import SwiftData

@Model
final class Schedule {
    var title: String
    var startTime: Date
    var endTime: Date
    var location: String?
    var createdAt: Date
    var updatedAt: Date

    init(title: String, startTime: Date, endTime: Date, location: String? = nil) {
        self.title = title
        self.startTime = startTime
        self.endTime = endTime
        self.location = location
        self.createdAt = .now
        self.updatedAt = .now
    }

    var isPast: Bool {
        endTime < .now
    }

    /// 일정 기간(startTime~endTime)이 해당 날짜와 겹치는지 판정한다.
    /// 여러 날에 걸친 일정도 포함하는 날짜마다 표시하기 위함.
    func occurs(on date: Date) -> Bool {
        startTime < date.endOfDay && endTime > date.startOfDay
    }

    /// 여러 날에 걸친 일정인지 여부.
    var isMultiDay: Bool {
        !startTime.isSameDay(as: endTime)
    }
}
