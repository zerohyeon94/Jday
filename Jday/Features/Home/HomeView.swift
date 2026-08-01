import SwiftUI
import SwiftData

struct HomeView: View {
    @Environment(\.modelContext) private var context
    @StateObject private var viewModel = HomeViewModel()

    @Query(sort: \DailyTask.date) private var allTasks: [DailyTask]
    @Query(sort: \Schedule.startTime) private var allSchedules: [Schedule]
    @Query(sort: \Retrospective.date) private var allRetrospectives: [Retrospective]

    @State private var selectedTask: DailyTask?
    @State private var deletedSnapshot: DeletedTaskSnapshot?
    @State private var showRetrospectiveEditor = false

    @AppStorage(EventKitService.enabledKey, store: AppGroup.defaults) private var appleCalendarEnabled = false
    /// 오늘의 Apple 캘린더 이벤트 (읽기 전용)
    @State private var todayExternalEvents: [ExternalEvent] = []

    /// 설정·캘린더 DB 변경 시 다시 조회하기 위한 키
    private var externalFetchKey: String {
        let service = EventKitService.shared
        return "\(appleCalendarEnabled)-\(service.changeCount)-\(service.hasFullAccess)"
    }

    @AppStorage("workspaceSeparationEnabled", store: AppGroup.defaults) private var wsEnabled = false
    @AppStorage("activeWorkspace", store: AppGroup.defaults) private var wsActiveRaw = Workspace.personal.rawValue

    private var wsActive: Workspace { Workspace(rawValue: wsActiveRaw) ?? .personal }

    private var filteredTasks: [DailyTask] {
        allTasks.workspaceFiltered(enabled: wsEnabled, active: wsActive)
    }
    private var filteredSchedules: [Schedule] {
        allSchedules.workspaceFiltered(enabled: wsEnabled, active: wsActive)
    }
    private var filteredRetrospectives: [Retrospective] {
        allRetrospectives.workspaceFiltered(enabled: wsEnabled, active: wsActive)
    }

    private var todayRetrospective: Retrospective? {
        filteredRetrospectives.first { $0.date.isToday }
    }

    /// 새 항목 저장 시 태그할 작업 공간(분리 OFF면 nil).
    private var newItemWorkspace: Workspace? {
        wsEnabled ? wsActive : nil
    }

    private var todayTasks: [DailyTask] {
        filteredTasks.filter { $0.date.isToday }
    }

    private var yesterdayPendingTasks: [DailyTask] {
        filteredTasks.filter { $0.date.isYesterday && !$0.isDone }
    }

    private var todaySchedules: [Schedule] {
        filteredSchedules.filter { $0.occurs(on: .now) }
    }

    private var pendingCount: Int {
        todayTasks.filter { !$0.isDone }.count
    }

    private var progressPercentage: Int {
        guard !todayTasks.isEmpty else { return 0 }
        let done = todayTasks.filter(\.isDone).count
        return Int(Double(done) / Double(todayTasks.count) * 100)
    }

    var body: some View {
        ScrollView {
            content
                .padding(.horizontal, Theme.screenPadding)
                .padding(.vertical, Theme.Spacing.lg)
        }
        .background(Theme.Colors.appBackground)
        #if os(iOS)
        .toolbar(.hidden, for: .navigationBar)
        #endif
        .sheet(item: $selectedTask) { task in
            TaskDetailView(task: task)
        }
        .sheet(isPresented: $showRetrospectiveEditor) {
            RetrospectiveEditView(
                date: .now,
                existing: todayRetrospective,
                workspace: newItemWorkspace
            )
        }
        .undoToast($deletedSnapshot) { snapshot in
            viewModel.restoreTask(snapshot, context: context)
        }
        .task(id: externalFetchKey) { reloadExternalEvents() }
    }

    private func reloadExternalEvents() {
        guard appleCalendarEnabled else {
            todayExternalEvents = []
            return
        }
        todayExternalEvents = EventKitService.shared.events(from: Date.now.startOfDay, to: Date.now.endOfDay)
    }

    private func deleteTask(_ task: DailyTask) {
        let snapshot = DeletedTaskSnapshot(task)
        viewModel.deleteTask(task, context: context)
        deletedSnapshot = snapshot
    }

    private var content: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.xl) {
            header

            if wsEnabled {
                WorkspaceToggle()
            }

            summaryCards

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

            TodayScheduleView(schedules: todaySchedules)

            if !todayExternalEvents.isEmpty {
                ExternalEventListView(events: todayExternalEvents)
            }

            RetrospectiveCardView(retrospective: todayRetrospective) {
                showRetrospectiveEditor = true
            }
        }
    }

    private var header: some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 2) {
                Text(Date.now.shortMonthDay)
                    .font(.system(size: 28, weight: .bold))

                Text(Date.now.weekdayLabel)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Circle()
                .fill(Theme.Colors.cardStroke)
                .frame(width: 40, height: 40)
                .overlay(
                    Image(systemName: "person.fill")
                        .foregroundStyle(.secondary)
                )
                .accessibilityLabel("프로필")
        }
    }

    private var summaryCards: some View {
        HStack(spacing: Theme.Spacing.md) {
            SummaryCardView(
                value: pendingCount == 0 ? "🎉" : "\(pendingCount)",
                label: "할 일 남음"
            )

            SummaryCardView(
                value: "\(todaySchedules.count)",
                label: "오늘 일정"
            )

            SummaryCardView(
                value: "\(progressPercentage)%",
                label: "진행률",
                isAccent: true
            )
        }
    }
}

#Preview {
    HomeView()
        .modelContainer(PreviewHelpers.makeContainer())
}
