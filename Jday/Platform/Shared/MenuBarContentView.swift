#if os(macOS)
import SwiftUI
import SwiftData

/// macOS 메뉴바 위젯 콘텐츠 — 오늘 업무를 빠르게 확인하고 할 일을 바로 체크한다.
/// (JdayApp의 `MenuBarExtra` 씬에서 사용, `.menuBarExtraStyle(.window)`)
struct MenuBarContentView: View {
    @Environment(\.modelContext) private var context

    @Query(sort: \DailyTask.date) private var allTasks: [DailyTask]
    @Query(sort: \Schedule.startTime) private var allSchedules: [Schedule]

    @AppStorage("workspaceSeparationEnabled", store: AppGroup.defaults) private var wsEnabled = false
    @AppStorage("activeWorkspace", store: AppGroup.defaults) private var wsActiveRaw = Workspace.personal.rawValue

    private var wsActive: Workspace { Workspace(rawValue: wsActiveRaw) ?? .personal }

    private var todayTasks: [DailyTask] {
        allTasks
            .workspaceFiltered(enabled: wsEnabled, active: wsActive)
            .filter { $0.date.isToday }
            .sorted { !$0.isDone && $1.isDone }
    }
    private var todaySchedules: [Schedule] {
        allSchedules
            .workspaceFiltered(enabled: wsEnabled, active: wsActive)
            .filter { $0.occurs(on: .now) }
            .sorted { $0.startTime < $1.startTime }
    }
    private var pendingCount: Int { todayTasks.filter { !$0.isDone }.count }

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            header

            Divider()

            tasksSection

            if !todaySchedules.isEmpty {
                Divider()
                schedulesSection
            }
        }
        .padding(Theme.Spacing.lg)
        .frame(width: 300)
    }

    private var header: some View {
        HStack(alignment: .firstTextBaseline) {
            Text("\(Date.now.shortMonthDay) \(Date.now.weekdayLabel)")
                .font(.headline)
            Spacer()
            Text(pendingCount == 0 ? "모두 완료 🎉" : "할 일 \(pendingCount)개")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }

    private var tasksSection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            Text("오늘 할 일")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)

            if todayTasks.isEmpty {
                Text("할 일 없음")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            } else {
                ForEach(todayTasks) { task in
                    Button {
                        toggle(task)
                    } label: {
                        HStack(spacing: Theme.Spacing.sm) {
                            Image(systemName: task.isDone ? "checkmark.circle.fill" : "circle")
                                .foregroundStyle(task.isDone ? Theme.Colors.brand : .secondary)
                            Text(task.title)
                                .strikethrough(task.isDone)
                                .foregroundStyle(task.isDone ? .secondary : .primary)
                            Spacer(minLength: 0)
                        }
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private var schedulesSection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            Text("오늘 일정")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)

            ForEach(todaySchedules) { schedule in
                HStack(spacing: Theme.Spacing.sm) {
                    Text(schedule.startTime.hourMinuteLabel)
                        .font(.caption.monospacedDigit())
                        .foregroundStyle(.secondary)
                        .frame(width: 44, alignment: .leading)
                    Circle()
                        .fill(Color.priority(schedule.priority))
                        .frame(width: 6, height: 6)
                    Text(schedule.title)
                        .foregroundStyle(schedule.isPast ? .secondary : .primary)
                    Spacer(minLength: 0)
                }
            }
        }
    }

    private func toggle(_ task: DailyTask) {
        task.setDone(!task.isDone)
        try? context.save()
    }
}
#endif
