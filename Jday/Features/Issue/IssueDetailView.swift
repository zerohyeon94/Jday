import SwiftUI
import SwiftData

/// iOS 이슈 상세 시트
struct IssueDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    let issue: Issue
    @StateObject private var viewModel = IssueViewModel()

    var body: some View {
        NavigationStack {
            ScrollView {
                IssueDetailContent(issue: issue) {
                    viewModel.resolve(issue, context: context)
                    dismiss()
                }
                .padding(Theme.screenPadding)
            }
            .background(Theme.Colors.appBackground)
            .navigationTitle("이슈 상세")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("닫기") { dismiss() }
                }
            }
        }
    }
}

#Preview {
    IssueDetailView(issue: Issue(
        title: "결제 플로우 결제 버튼 무반응",
        detail: "iOS 17 일부 기기에서 결제 버튼을 눌러도 다음 화면으로 넘어가지 않음. 재현율 약 40%.",
        notifyAt: .now
    ))
    .modelContainer(PreviewHelpers.makeContainer())
}
