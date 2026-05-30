import SwiftUI
import SwiftData

struct IssueListView: View {
    @Environment(\.modelContext) private var context
    @StateObject private var viewModel = IssueViewModel()
    @Query(sort: \Issue.createdAt, order: .reverse) private var issues: [Issue]
    @State private var selectedIssue: Issue?
    @State private var deleteTarget: Issue?
    @State private var showDeleteAlert = false

    private var filtered: [Issue] { viewModel.filteredIssues(issues) }

    var body: some View {
        NavigationStack {
            Group {
                if filtered.isEmpty {
                    emptyState
                } else {
                    issueList
                }
            }
            .navigationTitle(String(localized: "이슈"))
            .toolbar {
                ToolbarItem(placement: .automatic) {
                    filterMenu
                }
            }
            .sheet(item: $selectedIssue) { issue in
                IssueDetailView(issue: issue)
            }
            .alert(String(localized: "이슈 삭제"), isPresented: $showDeleteAlert) {
                Button(String(localized: "삭제"), role: .destructive) {
                    if let target = deleteTarget {
                        viewModel.delete(target, context: context)
                    }
                }
                Button(String(localized: "취소"), role: .cancel) {}
            } message: {
                Text("이슈를 삭제하면 복구할 수 없습니다.")
            }
        }
    }

    private var emptyState: some View {
        ContentUnavailableView(
            String(localized: "등록된 이슈가 없어요 ✅"),
            systemImage: "checkmark.circle",
            description: Text("새 이슈를 추가해보세요.")
        )
    }

    private var issueList: some View {
        List {
            ForEach(filtered) { issue in
                IssueRowView(issue: issue) {
                    viewModel.resolve(issue, context: context)
                }
                .contentShape(Rectangle())
                .onTapGesture { selectedIssue = issue }
                .swipeActions(edge: .leading, allowsFullSwipe: false) {
                    Button(role: .destructive) {
                        deleteTarget = issue
                        showDeleteAlert = true
                    } label: {
                        Label(String(localized: "삭제"), systemImage: "trash")
                    }
                }
            }
        }
        .listStyle(.plain)
    }

    private var filterMenu: some View {
        Menu {
            ForEach(IssueFilter.allCases, id: \.self) { f in
                Button {
                    viewModel.filter = f
                } label: {
                    Label(f.rawValue, systemImage: viewModel.filter == f ? "checkmark" : "")
                }
            }
        } label: {
            Label(viewModel.filter.rawValue, systemImage: "line.3.horizontal.decrease.circle")
        }
    }
}

private struct IssueRowView: View {
    let issue: Issue
    let onResolve: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(issue.title)
                    .font(.subheadline)
                    .fontWeight(.medium)

                Text(issue.createdAt, style: .date)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            statusBadge
        }
        .padding(.vertical, 4)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(issue.title), \(issue.isResolved ? "해결완료" : "미해결")")
    }

    private var statusBadge: some View {
        Text(issue.isResolved ? "해결완료" : "미해결")
            .font(.caption2)
            .fontWeight(.semibold)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(issue.isResolved ? Color.gray.opacity(0.2) : Color.blue.opacity(0.15))
            .foregroundStyle(issue.isResolved ? .gray : .blue)
            .clipShape(Capsule())
    }
}

#Preview {
    IssueListView()
        .modelContainer(PreviewHelpers.makeContainer())
}
