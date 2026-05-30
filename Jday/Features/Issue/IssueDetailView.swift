import SwiftUI
import SwiftData

struct IssueDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    let issue: Issue

    @State private var viewModel = IssueDetailViewModel()

    var body: some View {
        NavigationStack {
            List {
                Section {
                    Text(issue.title)
                        .font(.headline)

                    if let detail = issue.detail, !detail.isEmpty {
                        Text(detail)
                            .font(.body)
                            .foregroundStyle(.secondary)
                    }
                }

                Section(String(localized: "메타 정보")) {
                    LabeledContent(String(localized: "등록일")) {
                        Text(issue.createdAt, style: .date)
                            .foregroundStyle(.secondary)
                    }

                    if let notifyAt = issue.notifyAt {
                        LabeledContent(String(localized: "알림 시간")) {
                            Text(notifyAt.formattedTime)
                                .foregroundStyle(.secondary)
                        }
                    }

                    LabeledContent(String(localized: "상태")) {
                        Text(issue.isResolved ? "해결완료" : "미해결")
                            .foregroundStyle(issue.isResolved ? .gray : .blue)
                    }
                }

                if !issue.isResolved {
                    Section {
                        Button {
                            viewModel.resolve(issue, context: context)
                            dismiss()
                        } label: {
                            Label(String(localized: "해결 완료로 표시"), systemImage: "checkmark.circle.fill")
                                .foregroundStyle(.green)
                        }
                    }
                }
            }
            .navigationTitle(String(localized: "이슈 상세"))
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button(String(localized: "닫기")) { dismiss() }
                }
            }
        }
    }
}

@Observable
@MainActor
private final class IssueDetailViewModel {
    func resolve(_ issue: Issue, context: ModelContext) {
        issue.isResolved = true
        issue.updatedAt = .now
        NotificationService.shared.cancelIssueNotification(for: issue)
        try? context.save()
    }
}
