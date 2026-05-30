import Foundation
import SwiftData

@Model
final class DailyTask {
    var title: String
    var isDone: Bool
    var date: Date
    var priority: Priority
    var createdAt: Date
    var updatedAt: Date

    init(title: String, date: Date = .now, priority: Priority = .medium) {
        self.title = title
        self.isDone = false
        self.date = date
        self.priority = priority
        self.createdAt = .now
        self.updatedAt = .now
    }
}
