import SwiftUI
import SwiftData

/// macOS 홈 — 상단 요약 카드 + 좌(할 일) / 우(일정) 2단 레이아웃
struct MacHomeView: View {
    @Environment(\.modelContext) private var context
    @StateObject private var viewModel = HomeViewModel()

    @Query(sort: \DailyTask.date) private var allTasks: [DailyTask]
    @Query(sort: \Schedule.startTime) private var allSchedules: [Schedule]

    @State private var selectedTask: DailyTask?
    @State private var deletedSnapshot: DeletedTaskSnapshot?

    @AppStorage("workspaceSeparationEnabled") private var wsEnabled = false
    @AppStorage("activeWorkspace") private var wsActiveRaw = Workspace.personal.rawValue

    private var wsActive: Workspace { Workspace(rawValue: wsActiveRaw) ?? .personal }

    private var filteredTasks: [DailyTask] {
        allTasks.workspaceFiltered(enabled: wsEnabled, active: wsActive)
    }
    private var filteredSchedules: [Schedule] {
        allSchedules.workspaceFiltered(enabled: wsEnabled, active: wsActive)
    }

    private var todayTasks: [DailyTask] { filteredTasks.filter { $0.date.isToday } }
    private var yesterdayPendingTasks: [DailyTask] { filteredTasks.filter { $0.date.isYesterday && !$0.isDone } }
    private var todaySchedules: [Schedule] { filteredSchedules.filter { $0.occurs(on: .now) } }
    private var pendingCount: Int { todayTasks.filter { !$0.isDone }.count }
    private var progressPercentage: Int {
        guard !todayTasks.isEmpty else { return 0 }
        return Int(Double(todayTasks.filter(\.isDone).count) / Double(todayTasks.count) * 100)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Theme.Spacing.xl) {
                HStack {
                    header
                    Spacer()
                    if wsEnabled {
                        WorkspaceToggle()
                    }
                }
                summaryCards

                HStack(alignment: .top, spacing: Theme.Spacing.xl) {
                    leftColumn
                    TodayScheduleView(schedules: todaySchedules)
                        .frame(maxWidth: 360, alignment: .top)
                }
            }
            .padding(Theme.screenPadding)
        }
        .background(Theme.Colors.appBackground)
        .navigationTitle("홈")
        .sheet(item: $selectedTask) { task in
            TaskDetailView(task: task)
        }
        .undoToast($deletedSnapshot) { snapshot in
            viewModel.restoreTask(snapshot, context: context)
        }
    }

    private func deleteTask(_ task: DailyTask) {
        let snapshot = DeletedTaskSnapshot(task)
        viewModel.deleteTask(task, context: context)
        deletedSnapshot = snapshot
    }

    private var header: some View {
        HStack(alignment: .firstTextBaseline, spacing: Theme.Spacing.md) {
            Text("\(Date.now.shortMonthDay) \(Date.now.weekdayLabel)")
                .font(.system(size: 24, weight: .bold))
            Text("오늘 할 일 \(pendingCount)개 남음")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }

    private var summaryCards: some View {
        HStack(spacing: Theme.Spacing.lg) {
            SummaryCardView(value: pendingCount == 0 ? "🎉" : "\(pendingCount)", label: "할 일 남음")
            SummaryCardView(value: "\(todaySchedules.count)", label: "오늘 일정")
            SummaryCardView(value: "\(progressPercentage)%", label: "오늘 진행률", isAccent: true)
        }
    }

    private var leftColumn: some View {
        VStack(spacing: Theme.Spacing.xl) {
            if !yesterdayPendingTasks.isEmpty {
                YesterdayTasksView(
                    tasks: yesterdayPendingTasks,
                    onMoveOne: { viewModel.moveTaskToToday($0, context: context) },
                    onMoveAll: { viewModel.moveYesterdayTasksToToday(yesterdayPendingTasks, context: context) }
                )
            }

            TodayTasksView(
                tasks: todayTasks,
                onToggle: { viewModel.toggleTask($0, context: context) },
                onSelect: { selectedTask = $0 },
                onDelete: { deleteTask($0) },
                onUpdate: { _ in try? context.save() }
            )
        }
        .frame(maxWidth: .infinity, alignment: .top)
    }
}

#Preview {
    MacHomeView()
        .modelContainer(PreviewHelpers.makeContainer())
}
