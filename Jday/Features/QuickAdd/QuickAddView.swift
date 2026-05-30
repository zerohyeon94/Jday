import SwiftUI
import SwiftData

struct QuickAddView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    @StateObject private var viewModel = QuickAddViewModel()
    @State private var showTabSwitchAlert = false
    @State private var pendingTab: QuickAddTab?

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                Picker(String(localized: "추가 유형"), selection: $viewModel.selectedTab) {
                    ForEach(QuickAddTab.allCases, id: \.self) { tab in
                        Text(tab.rawValue).tag(tab)
                    }
                }
                .pickerStyle(.segmented)
                .padding()

                Divider()

                ScrollView {
                    VStack(spacing: 16) {
                        switch viewModel.selectedTab {
                        case .task: taskForm
                        case .schedule: scheduleForm
                        case .issue: issueForm
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle(String(localized: "빠른 추가"))
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(String(localized: "취소")) { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(String(localized: "저장")) { save() }
                        .disabled(!canSave)
                        .fontWeight(.semibold)
                }
            }
            .alert(String(localized: "입력 내용 초기화"), isPresented: $showTabSwitchAlert) {
                Button(String(localized: "초기화"), role: .destructive) {
                    if let tab = pendingTab {
                        viewModel.resetCurrentTab()
                        viewModel.selectedTab = tab
                    }
                }
                Button(String(localized: "취소"), role: .cancel) { pendingTab = nil }
            } message: {
                Text("입력한 내용이 사라집니다.")
            }
        }
    }

    private var canSave: Bool {
        switch viewModel.selectedTab {
        case .task: viewModel.canSaveTask
        case .schedule: viewModel.canSaveSchedule
        case .issue: viewModel.canSaveIssue
        }
    }

    private var taskForm: some View {
        VStack(spacing: 16) {
            TextField(String(localized: "할 일 제목"), text: $viewModel.taskTitle)
                .textFieldStyle(.roundedBorder)

            DatePicker(String(localized: "날짜"), selection: $viewModel.taskDate, displayedComponents: .date)

            Picker(String(localized: "우선순위"), selection: $viewModel.taskPriority) {
                ForEach(Priority.allCases, id: \.self) { p in
                    Text(p.label).tag(p)
                }
            }
            .pickerStyle(.segmented)
        }
    }

    private var scheduleForm: some View {
        VStack(spacing: 16) {
            TextField(String(localized: "일정 제목"), text: $viewModel.scheduleTitle)
                .textFieldStyle(.roundedBorder)

            DatePicker(String(localized: "시작 시간"), selection: $viewModel.scheduleStartTime)

            DatePicker(String(localized: "종료 시간"), selection: $viewModel.scheduleEndTime)

            if viewModel.scheduleEndTime <= viewModel.scheduleStartTime {
                Text("종료 시간은 시작 시간 이후여야 합니다.")
                    .font(.caption)
                    .foregroundStyle(.red)
            }

            TextField(String(localized: "장소 (선택)"), text: $viewModel.scheduleLocation)
                .textFieldStyle(.roundedBorder)
        }
    }

    private var issueForm: some View {
        VStack(spacing: 16) {
            TextField(String(localized: "이슈 제목"), text: $viewModel.issueTitle)
                .textFieldStyle(.roundedBorder)

            TextField(String(localized: "상세 내용 (선택)"), text: $viewModel.issueDetail, axis: .vertical)
                .textFieldStyle(.roundedBorder)
                .lineLimit(3...6)

            Toggle(String(localized: "알림 설정"), isOn: $viewModel.issueHasNotify)

            if viewModel.issueHasNotify {
                DatePicker(
                    String(localized: "알림 시간"),
                    selection: Binding(
                        get: { viewModel.issueNotifyAt ?? .now },
                        set: { viewModel.issueNotifyAt = $0 }
                    )
                )

                if viewModel.isPastNotifyTime {
                    Label("과거 시간입니다. 알림이 전송되지 않습니다.", systemImage: "exclamationmark.triangle")
                        .font(.caption)
                        .foregroundStyle(.orange)
                }
            }
        }
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
    QuickAddView()
        .modelContainer(
            for: [DailyTask.self, Schedule.self, Issue.self],
            inMemory: true
        )
}
