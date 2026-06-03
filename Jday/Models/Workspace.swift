import SwiftUI

/// 작업 공간(회사/개인) 분류. nil은 "미분류"(분리 OFF일 때 저장된 항목).
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

/// 작업 공간 값을 가진 모델(할 일·일정·이슈) 공통 인터페이스.
protocol WorkspaceTaggable {
    var workspace: Workspace? { get }
}

extension Array where Element: WorkspaceTaggable {
    /// 분리 기능이 켜졌을 때만 현재 활성 공간의 항목만 남긴다(엄격 분리).
    /// 분리가 꺼져 있으면 원본 그대로.
    func workspaceFiltered(enabled: Bool, active: Workspace) -> [Element] {
        guard enabled else { return self }
        return self.filter { $0.workspace == active }
    }
}
