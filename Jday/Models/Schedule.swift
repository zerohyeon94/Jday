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
}
