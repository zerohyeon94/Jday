import Foundation
import SwiftData

@Model
final class Issue {
    var title: String
    var detail: String?
    var isResolved: Bool
    var notifyAt: Date?
    /// 작업 공간(개인/회사). nil = 미분류(기본 공간).
    var workspace: Workspace?
    var createdAt: Date
    var updatedAt: Date

    init(title: String, detail: String? = nil, notifyAt: Date? = nil, workspace: Workspace? = nil) {
        self.title = title
        self.detail = detail
        self.isResolved = false
        self.notifyAt = notifyAt
        self.workspace = workspace
        self.createdAt = .now
        self.updatedAt = .now
    }
}

extension Issue: WorkspaceTaggable {}
