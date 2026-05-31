import SwiftUI
import SwiftData

struct HomeView: View {
    @Environment(\.modelContext) private var context
    @StateObject private var viewModel = HomeViewModel()

    @Query(sort: \DailyTask.date) private var allTasks: [DailyTask]
    @Query(sort: \Schedule.startTime) private var allSchedules: [Schedule]

    @State private var selectedTask: DailyTask?

    private var todayTasks: [DailyTask] {
        allTasks.filter { $0.date.isToday }
    }

    private var yesterdayPendingTasks: [DailyTask] {
        allTasks.filter { $0.date.isYesterday && !$0.isDone }
    }

    private var todaySchedules: [Schedule] {
        allSchedules.filter { $0.startTime.isToday }
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
    }

    private var content: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.xl) {
            header
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
                onSelect: { selectedTask = $0 }
            )

            TodayScheduleView(schedules: todaySchedules)
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
