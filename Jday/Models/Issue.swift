import Foundation
import SwiftData

@Model
final class Issue {
    var title: String
    var detail: String?
    var isResolved: Bool
    var notifyAt: Date?
    var createdAt: Date
    var updatedAt: Date

    init(title: String, detail: String? = nil, notifyAt: Date? = nil) {
        self.title = title
        self.detail = detail
        self.isResolved = false
        self.notifyAt = notifyAt
        self.createdAt = .now
        self.updatedAt = .now
    }
}
