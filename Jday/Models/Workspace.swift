import SwiftUI

/// 작업 공간(회사/개인) 분류. nil은 "미분류(기본 공간)"으로 취급한다.
enum Workspace: String, Codable, CaseIterable, Identifiable {
    case personal
    case work

    var id: String { rawValue }

    var label: LocalizedStringKey {
        switch self {
        case .personal: "개인"
        case .work: "회사"
        }
    }

    var shortLabel: String {
        switch self {
        case .personal: "개인"
        case .work: "회사"
        }
    }

    var icon: String {
        switch self {
        case .personal: "person"
        case .work: "briefcase"
        }
    }
}

/// 목록 필터: 전체 / 개인 / 회사
enum WorkspaceFilter: String, CaseIterable, Identifiable {
    case all
    case personal
    case work

    var id: String { rawValue }

    var label: String {
        switch self {
        case .all: "전체"
        case .personal: "개인"
        case .work: "회사"
        }
    }

    var workspace: Workspace? {
        switch self {
        case .all: nil
        case .personal: .personal
        case .work: .work
        }
    }
}

/// 작업 공간 값을 가진 모델(할 일·일정·이슈) 공통 인터페이스.
protocol WorkspaceTaggable {
    var workspace: Workspace? { get }
}

extension Array where Element: WorkspaceTaggable {
    /// 분리 기능이 켜졌을 때만 현재 필터로 거른다. 꺼져 있으면 원본 그대로.
    func workspaceFiltered(
        enabled: Bool,
        filter: WorkspaceFilter,
        defaultWorkspace: Workspace
    ) -> [Element] {
        guard enabled else { return self }
        return self.filter {
            WorkspaceMatcher.matches($0.workspace, filter: filter, default: defaultWorkspace)
        }
    }
}

enum WorkspaceMatcher {
    /// 항목의 공간(nil 가능)이 현재 필터에 부합하는지. 미분류 항목은 기본 공간으로 간주.
    static func matches(
        _ workspace: Workspace?,
        filter: WorkspaceFilter,
        default defaultWorkspace: Workspace
    ) -> Bool {
        switch filter {
        case .all:
            return true
        case .personal:
            return (workspace ?? defaultWorkspace) == .personal
        case .work:
            return (workspace ?? defaultWorkspace) == .work
        }
    }
}
