import SwiftUI

/// 작업 공간 분리가 켜졌을 때 목록 상단에 표시하는 전체/개인/회사 필터.
/// 자체적으로 AppStorage("workspaceFilter")를 공유하므로 어느 화면에 두어도 동기화된다.
struct WorkspaceFilterBar: View {
    @AppStorage("workspaceFilter") private var filterRaw = WorkspaceFilter.all.rawValue

    private var filterBinding: Binding<WorkspaceFilter> {
        Binding(
            get: { WorkspaceFilter(rawValue: filterRaw) ?? .all },
            set: { filterRaw = $0.rawValue }
        )
    }

    var body: some View {
        PillPicker(
            options: WorkspaceFilter.allCases,
            label: { $0.label },
            selection: filterBinding
        )
    }
}

#Preview {
    WorkspaceFilterBar()
        .padding()
        .background(Theme.Colors.appBackground)
}
