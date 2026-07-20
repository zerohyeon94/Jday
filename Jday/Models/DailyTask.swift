import Foundation
import SwiftData

@Model
final class DailyTask {
    var title: String = ""
    var detail: String?
    var isDone: Bool = false
    /// 완료로 체크한 시각. 미완료면 nil.
    var completedAt: Date?
    var date: Date = Date()
    var priority: Priority = Priority.medium
    /// 작업 공간(개인/회사). nil = 미분류(기본 공간).
    var workspace: Workspace?
    /// Apple 미리 알림으로 내보낸 항목의 외부 식별자(calendarItemExternalIdentifier).
    /// iCloud 목록이면 기기 간에도 안정적이라 중복 내보내기를 방지한다.
    var exportedReminderID: String?
    /// 필기 메모 (PencilKit PKDrawing 직렬화 데이터). CloudKit 호환을 위해 옵셔널.
    @Attribute(.externalStorage) var drawingData: Data?
    var createdAt: Date = Date()
    var updatedAt: Date = Date()

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
