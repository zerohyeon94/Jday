import Foundation
import SwiftData

/// 하루 회고(배운 점) 기록 — 날짜별 1건 원칙(자정 정규화 저장).
/// CloudKit 호환을 위해 모든 속성에 기본값을 두고 workspace는 옵셔널로 선언한다.
@Model
final class Retrospective {
    /// 회고 내용(오늘 배운 점).
    var content: String = ""
    /// 회고 대상 날짜(자정으로 정규화되어 저장).
    var date: Date = Date()
    /// 작업 공간(개인/회사). nil = 미분류(기본 공간).
    var workspace: Workspace?
    var createdAt: Date = Date()
    var updatedAt: Date = Date()

    init(content: String = "", date: Date = .now, workspace: Workspace? = nil) {
        self.content = content
        self.date = date.startOfDay
        self.workspace = workspace
        self.createdAt = .now
        self.updatedAt = .now
    }
}

extension Retrospective: WorkspaceTaggable {}
