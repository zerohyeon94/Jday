import SwiftUI
import SwiftData

/// iOS 이슈 목록
struct IssueListView: View {
    @Environment(\.modelContext) private var context
    @StateObject private var viewModel = IssueViewModel()
    @Query(sort: \Issue.createdAt, order: .reverse) private var issues: [Issue]
    @State private var selectedIssue: Issue?
    @State private var deleteTarget: Issue?
    @State private var showDeleteAlert = false

    private var filtered: [Issue] { viewModel.filteredIssues(issues) }
    private var unresolvedCount: Int { issues.filter { !$0.isResolved }.count }

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.lg) {
            header

            PillPicker(
                options: IssueFilter.allCases,
                label: { $0.rawValue },
                selection: $viewModel.filter
            )
            .padding(.horizontal, Theme.screenPadding)

            if filtered.isEmpty {
                emptyState
            } else {
                issueList
            }
        }
        .padding(.top, Theme.Spacing.md)
        .background(Theme.Colors.appBackground)
        #if os(iOS)
        .toolbar(.hidden, for: .navigationBar)
        #endif
        .sheet(item: $selectedIssue) { issue in
            IssueDetailView(issue: issue)
        }
        .alert("이슈 삭제", isPresented: $showDeleteAlert) {
            Button("삭제", role: .destructive) {
                if let target = deleteTarget {
                    viewModel.delete(target, context: context)
                }
            }
            Button("취소", role: .cancel) {}
        } message: {
            Text("이슈를 삭제하면 복구할 수 없습니다.")
        }
    }

    private var header: some View {
        HStack(alignment: .firstTextBaseline) {
            Text("이슈")
                .font(.system(size: 28, weight: .bold))
            Spacer()
            Text("미해결 \(unresolvedCount)")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, Theme.screenPadding)
    }

    private var emptyState: some View {
        ContentUnavailableView(
            "등록된 이슈가 없어요 ✅",
            systemImage: "checkmark.circle",
            description: Text("새 이슈를 추가해보세요.")
        )
        .frame(maxHeight: .infinity)
    }

    private var issueList: some View {
        List {
            ForEach(filtered) { issue in
                IssueRowView(issue: issue)
                    .contentShape(Rectangle())
                    .onTapGesture { selectedIssue = issue }
                    .padding(Theme.Spacing.lg)
                    .cardStyle()
                    .listRowInsets(EdgeInsets(
                        top: Theme.Spacing.xs,
                        leading: Theme.screenPadding,
                        bottom: Theme.Spacing.xs,
                        trailing: Theme.screenPadding
                    ))
                    .listRowSeparator(.hidden)
                    .listRowBackground(Color.clear)
                    .swipeActions(edge: .trailing) {
                        Button(role: .destructive) {
                            deleteTarget = issue
                            showDeleteAlert = true
                        } label: {
                            Label("삭제", systemImage: "trash")
                        }
                    }
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
    }
}

#Preview {
    NavigationStack {
        IssueListView()
            .modelContainer(PreviewHelpers.makeContainer())
    }
}
