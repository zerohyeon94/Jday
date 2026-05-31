import SwiftUI
import SwiftData

struct QuickAddView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    @StateObject private var viewModel = QuickAddViewModel()
    @State private var showTabSwitchAlert = false
    @State private var pendingTab: QuickAddTab?

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.xl) {
            handle

            Text("빠른 추가")
                .font(.title2.bold())

            PillPicker(
                options: QuickAddTab.allCases,
                label: { $0.rawValue },
                selection: tabBinding
            )

            ScrollView {
                VStack(alignment: .leading, spacing: Theme.Spacing.xl) {
                    switch viewModel.selectedTab {
                    case .task: taskForm
                    case .schedule: scheduleForm
                    case .issue: issueForm
                    }
                }
            }

            Button(action: save) {
                Text("저장")
            }
            .buttonStyle(PrimaryButtonStyle())
            .disabled(!canSave)
        }
        .padding(Theme.screenPadding)
        .background(Theme.Colors.appBackground)
        .presentationDragIndicator(.hidden)
        .alert("입력 내용 초기화", isPresented: $showTabSwitchAlert) {
            Button("초기화", role: .destructive) {
                if let tab = pendingTab {
                    viewModel.resetCurrentTab()
                    viewModel.selectedTab = tab
                    pendingTab = nil
                }
            }
            Button("취소", role: .cancel) { pendingTab = nil }
        } message: {
            Text("입력한 내용이 사라집니다.")
        }
    }

    // 탭 전환 시 입력값이 있으면 확인 Alert
    private var tabBinding: Binding<QuickAddTab> {
        Binding(
            get: { viewModel.selectedTab },
            set: { newTab in
                if newTab != viewModel.selectedTab, hasInput {
                    pendingTab = newTab
                    showTabSwitchAlert = true
                } else {
                    viewModel.selectedTab = newTab
                }
            }
        )
    }

    private var hasInput: Bool {
        switch viewModel.selectedTab {
        case .task: !viewModel.taskTitle.isEmpty || !viewModel.taskDetail.isEmpty
        case .schedule: !viewModel.scheduleTitle.isEmpty || !viewModel.scheduleLocation.isEmpty
        case .issue: !viewModel.issueTitle.isEmpty || !viewModel.issueDetail.isEmpty
        }
    }

    private var canSave: Bool {
        switch viewModel.selectedTab {
        case .task: viewModel.canSaveTask
        case .schedule: viewModel.canSaveSchedule
        case .issue: viewModel.canSaveIssue
        }
    }

    private var handle: some View {
        Capsule()
            .fill(Theme.Colors.cardStroke)
            .frame(width: 36, height: 5)
            .frame(maxWidth: .infinity)
    }

    // MARK: - Forms

    private var taskForm: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.xl) {
            field(label: "제목") {
                styledField("할 일 제목을 입력", text: $viewModel.taskTitle)
            }
            field(label: "메모 (선택)") {
                styledField("할 일에 대한 설명을 입력", text: $viewModel.taskDetail, axis: .vertical)
            }
            field(label: "날짜") {
                DatePicker("", selection: $viewModel.taskDate, displayedComponents: .date)
                    .labelsHidden()
            }
            field(label: "우선순위") {
                Picker("", selection: $viewModel.taskPriority) {
                    ForEach(Priority.allCases, id: \.self) { Text($0.label).tag($0) }
                }
                .pickerStyle(.segmented)
                .labelsHidden()
            }
        }
    }

    private var scheduleForm: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.xl) {
            field(label: "제목") {
                styledField("일정 제목을 입력", text: $viewModel.scheduleTitle)
            }
            field(label: "시작 시간") {
                DatePicker("", selection: $viewModel.scheduleStartTime)
                    .labelsHidden()
            }
            field(label: "종료 시간") {
                DatePicker("", selection: $viewModel.scheduleEndTime)
                    .labelsHidden()
            }
            if viewModel.scheduleEndTime <= viewModel.scheduleStartTime {
                Text("종료 시간은 시작 시간 이후여야 합니다.")
                    .font(.caption)
                    .foregroundStyle(.red)
            }
            field(label: "장소 (선택)") {
                styledField("장소를 입력", text: $viewModel.scheduleLocation)
            }
        }
    }

    private var issueForm: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.xl) {
            field(label: "제목") {
                styledField("이슈 제목을 입력", text: $viewModel.issueTitle)
            }
            field(label: "상세 내용 (선택)") {
                styledField("상세 내용을 입력", text: $viewModel.issueDetail, axis: .vertical)
            }
            field(label: "알림") {
                Toggle("알림 설정", isOn: $viewModel.issueHasNotify)
            }
            if viewModel.issueHasNotify {
                field(label: "알림 시간") {
                    DatePicker("", selection: Binding(
                        get: { viewModel.issueNotifyAt ?? .now },
                        set: { viewModel.issueNotifyAt = $0 }
                    ))
                    .labelsHidden()
                }
                if viewModel.isPastNotifyTime {
                    Label("과거 시간입니다. 알림이 전송되지 않습니다.", systemImage: "exclamationmark.triangle")
                        .font(.caption)
                        .foregroundStyle(.orange)
                }
            }
        }
    }

    // MARK: - Helpers

    private func field<Content: View>(
        label: LocalizedStringKey,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            Text(label)
                .font(.subheadline)
                .foregroundStyle(.secondary)
            content()
        }
    }

    private func styledField(
        _ placeholder: LocalizedStringKey,
        text: Binding<String>,
        axis: Axis = .horizontal
    ) -> some View {
        TextField(placeholder, text: text, axis: axis)
            .textFieldStyle(.plain)
            .padding(Theme.Spacing.md)
            .frame(minHeight: axis == .vertical ? 80 : nil, alignment: .topLeading)
            .background(Theme.Colors.card)
            .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.control, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: Theme.Radius.control, style: .continuous)
                    .stroke(Theme.Colors.cardStroke, lineWidth: 1)
            )
    }

    private func save() {
        let saved: Bool
        switch viewModel.selectedTab {
        case .task: saved = viewModel.saveTask(context: context)
        case .schedule: saved = viewModel.saveSchedule(context: context)
        case .issue: saved = viewModel.saveIssue(context: context)
        }
        if saved { dismiss() }
    }
}

#Preview {
    Color.black.opacity(0.2)
        .sheet(isPresented: .constant(true)) {
            QuickAddView()
                .modelContainer(PreviewHelpers.makeContainer())
                .presentationDetents([.medium, .large])
        }
}
