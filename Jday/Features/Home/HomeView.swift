import SwiftUI
import SwiftData

struct HomeView: View {
    @Environment(\.modelContext) private var context
    @StateObject private var viewModel = HomeViewModel()

    @Query(sort: \DailyTask.date) private var allTasks: [DailyTask]
    @Query(sort: \Schedule.startTime) private var allSchedules: [Schedule]

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

    private var progressPercentage: Double {
        guard !todayTasks.isEmpty else { return 0 }
        let done = todayTasks.filter(\.isDone).count
        return Double(done) / Double(todayTasks.count) * 100
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                content
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
            }
            .navigationTitle(Date.now.formattedDate)
            #if os(iOS)
            .navigationBarTitleDisplayMode(.large)
            #endif
        }
    }

    private var content: some View {
        VStack(alignment: .leading, spacing: 20) {
            summaryCards

            if !yesterdayPendingTasks.isEmpty {
                yesterdaySection
            }

            todayTasksSection
            todayScheduleSection
        }
    }

    private var summaryCards: some View {
        HStack(spacing: 10) {
            SummaryCardView(
                title: String(localized: "남은 할 일"),
                value: pendingCount == 0 ? "🎉" : "\(pendingCount)",
                subtitle: pendingCount == 0 ? "모두 완료!" : nil,
                color: .blue
            )

            if !todayTasks.isEmpty {
                SummaryCardView(
                    title: String(localized: "진행률"),
                    value: "\(Int(progressPercentage))%",
                    color: .orange
                )
            }

            SummaryCardView(
                title: String(localized: "오늘 일정"),
                value: "\(todaySchedules.count)",
                color: .green
            )
        }
    }

    private var yesterdaySection: some View {
        YesterdayTasksView(tasks: yesterdayPendingTasks) {
            viewModel.moveYesterdayTasksToToday(yesterdayPendingTasks, context: context)
        }
    }

    private var todayTasksSection: some View {
        TodayTasksView(tasks: todayTasks) { task in
            viewModel.toggleTask(task, context: context)
        }
    }

    private var todayScheduleSection: some View {
        TodayScheduleView(schedules: todaySchedules)
    }
}

#Preview {
    HomeView()
        .modelContainer(
            for: [DailyTask.self, Schedule.self, Issue.self],
            inMemory: true
        )
}
