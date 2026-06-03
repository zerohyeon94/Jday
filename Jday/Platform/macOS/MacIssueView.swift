import SwiftUI
import SwiftData

/// macOS 이슈 — 좌측 목록 + 우측 상세 패널
struct MacIssueView: View {
    @Environment(\.modelContext) private var context
    @StateObject private var viewModel = IssueViewModel()
    @Query(sort: \Issue.createdAt, order: .reverse) private var allIssues: [Issue]
    @State private var selectedID: PersistentIdentifier?

    @AppStorage("workspaceSeparationEnabled") private var wsEnabled = false
    @AppStorage("activeWorkspace") private var wsActiveRaw = Workspace.personal.rawValue

    private var wsActive: Workspace { Workspace(rawValue: wsActiveRaw) ?? .personal }

    private var issues: [Issue] {
        allIssues.workspaceFiltered(enabled: wsEnabled, active: wsActive)
    }

    private var filtered: [Issue] { viewModel.filteredIssues(issues) }
    private var selectedIssue: Issue? {
        filtered.first { $0.persistentModelID == selectedID } ?? filtered.first
    }

    var body: some View {
        HStack(spacing: 0) {
            listColumn
                .frame(minWidth: 360)

            Divider()

            detailColumn
                .frame(minWidth: 340)
        }
        .background(Theme.Colors.appBackground)
        .navigationTitle("이슈")
    }

    private var listColumn: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.lg) {
            if wsEnabled {
                WorkspaceToggle()
            }

            PillPicker(
                options: IssueFilter.allCases,
                label: { $0.rawValue },
                selection: $viewModel.filter
            )

            if filtered.isEmpty {
                ContentUnavailableView("등록된 이슈가 없어요 ✅", systemImage: "checkmark.circle")
                    .frame(maxHeight: .infinity)
            } else {
                ScrollView {
                    LazyVStack(spacing: 0) {
                        ForEach(filtered) { issue in
                            let isSelected = issue.persistentModelID == selectedIssue?.persistentModelID
                            IssueRowView(issue: issue, showsChevron: false)
                                .padding(Theme.Spacing.md)
                                .background(isSelected ? Theme.Colors.brand.opacity(0.08) : .clear)
                                .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.control))
                                .contentShape(Rectangle())
                                .onTapGesture { selectedID = issue.persistentModelID }
                            DashedDivider()
                        }
                    }
                }
            }
        }
        .padding(Theme.screenPadding)
    }

    @ViewBuilder
    private var detailColumn: some View {
        if let issue = selectedIssue {
            ScrollView {
                IssueDetailContent(issue: issue) {
                    viewModel.resolve(issue, context: context)
                }
                .padding(Theme.screenPadding)
            }
        } else {
            ContentUnavailableView("이슈를 선택하세요", systemImage: "sidebar.right")
        }
    }
}

#Preview {
    MacIssueView()
        .modelContainer(PreviewHelpers.makeContainer())
        .frame(width: 900, height: 600)
}
