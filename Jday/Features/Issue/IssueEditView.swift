import SwiftUI
import SwiftData

/// 이슈 편집 시트 — iOS/macOS 공용
struct IssueEditView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    let issue: Issue
    @StateObject private var viewModel = IssueViewModel()

    @State private var title: String
    @State private var detail: String
    @State private var hasNotify: Bool
    @State private var notifyAt: Date

    init(issue: Issue) {
        self.issue = issue
        _title = State(initialValue: issue.title)
        _detail = State(initialValue: issue.detail ?? "")
        _hasNotify = State(initialValue: issue.notifyAt != nil)
        _notifyAt = State(initialValue: issue.notifyAt ?? .now.addingTimeInterval(30 * 60))
    }

    private var canSave: Bool {
        !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private var isNotifyInPast: Bool {
        hasNotify && notifyAt <= .now
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("제목") {
                    TextField("이슈 제목", text: $title)
                }

                Section("상세 내용") {
                    TextEditor(text: $detail)
                        .frame(minHeight: 120)
                }

                Section("알림") {
                    Toggle("알림 받기", isOn: $hasNotify)

                    if hasNotify {
                        DatePicker(
                            "알림 시간",
                            selection: $notifyAt,
                            displayedComponents: [.date, .hourAndMinute]
                        )

                        if isNotifyInPast {
                            Label("과거 시간에는 알림이 발송되지 않습니다", systemImage: "exclamationmark.triangle")
                                .font(.caption)
                                .foregroundStyle(.orange)
                        }
                    }
                }
            }
            .formStyle(.grouped)
            .navigationTitle("이슈 수정")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("취소") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("저장") { save() }
                        .disabled(!canSave)
                }
            }
        }
        #if os(macOS)
        .frame(minWidth: 420, minHeight: 480)
        #endif
    }

    private func save() {
        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedDetail = detail.trimmingCharacters(in: .whitespacesAndNewlines)
        viewModel.update(
            issue,
            title: trimmedTitle,
            detail: trimmedDetail.isEmpty ? nil : trimmedDetail,
            notifyAt: hasNotify ? notifyAt : nil,
            context: context
        )
        dismiss()
    }
}

#Preview {
    IssueEditView(issue: Issue(
        title: "결제 플로우 결제 버튼 무반응",
        detail: "iOS 17 일부 기기에서 결제 버튼을 눌러도 다음 화면으로 넘어가지 않음.",
        notifyAt: .now.addingTimeInterval(3600)
    ))
    .modelContainer(PreviewHelpers.makeContainer())
}
