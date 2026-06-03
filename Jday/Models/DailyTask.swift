import Foundation
import SwiftData

@Model
final class DailyTask {
    var title: String
    var detail: String?
    var isDone: Bool
    /// 완료로 체크한 시각. 미완료면 nil.
    var completedAt: Date?
    var date: Date
    var priority: Priority
    /// 작업 공간(개인/회사). nil = 미분류(기본 공간).
    var workspace: Workspace?
    var createdAt: Date
    var updatedAt: Date

    init(title: String, detail: String? = nil, date: Date = .now, priority: Priority = .medium, workspace: Workspace? = nil) {
        self.title = title
        self.detail = detail
        self.isDone = false
        self.completedAt = nil
        self.date = date
        self.priority = priority
        self.workspace = workspace
        self.createdAt = .now
        self.updatedAt = .now
    }

    /// 완료 상태를 변경하며 완료 시각도 함께 갱신한다.
    func setDone(_ done: Bool) {
        isDone = done
        completedAt = done ? .now : nil
        updatedAt = .now
    }
}

extension DailyTask: WorkspaceTaggable {}
