import SwiftUI
import SwiftData

/// macOS 캘린더 — 좌측 월별 그리드(인라인 이벤트 칩) + 우측 선택일 패널
struct MacCalendarView: View {
    @Environment(\.modelContext) private var context
    @StateObject private var viewModel = CalendarViewModel()

    @Query(sort: \DailyTask.date) private var tasks: [DailyTask]
    @Query(sort: \Schedule.startTime) private var schedules: [Schedule]

    private var selectedTasks: [DailyTask] { viewModel.tasksFor(date: viewModel.selectedDate, tasks: tasks) }
    private var selectedSchedules: [Schedule] { viewModel.schedulesFor(date: viewModel.selectedDate, schedules: schedules) }
    private var completedTasks: [DailyTask] { viewModel.completedTasksFor(date: viewModel.selectedDate, tasks: tasks) }

    @State private var selectedTask: DailyTask?

    var body: some View {
        HStack(spacing: 0) {
            gridColumn
            Divider()
            rightPanel.frame(width: 320)
        }
        .background(Theme.Colors.appBackground)
        .navigationTitle("캘린더")
        .sheet(item: $selectedTask) { task in
            TaskDetailView(task: task)
        }
    }

    private var gridColumn: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.lg) {
            HStack(alignment: .firstTextBaseline) {
                VStack(alignment: .leading) {
                    Text(viewModel.selectedDate.monthLabel)
                        .font(.system(size: 24, weight: .bold))
                    Text(viewModel.selectedDate.yearLabel)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Picker("", selection: $viewModel.displayMode) {
                    ForEach(CalendarDisplayMode.allCases, id: \.self) { Text($0.rawValue).tag($0) }
                }
                .pickerStyle(.segmented)
                .labelsHidden()
                .frame(width: 160)

                HStack(spacing: Theme.Spacing.md) {
                    Button { shift(-1) } label: { Image(systemName: "chevron.left") }
                    Button { viewModel.goToToday() } label: { Text("오늘").fontWeight(.semibold) }
                    Button { shift(1) } label: { Image(systemName: "chevron.right") }
                }
                .foregroundStyle(Theme.Colors.brand)
                .buttonStyle(.plain)
            }

            weekdayHeader
            monthGrid
            Spacer()
        }
        .padding(Theme.screenPadding)
        .frame(maxWidth: .infinity)
    }

    private var weekdayHeader: some View {
        HStack {
            ForEach(["일", "월", "화", "수", "목", "금", "토"], id: \.self) { day in
                Text(day).font(.caption2).foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }

    private var monthGrid: some View {
        let days = viewModel.daysInMonth(for: viewModel.selectedDate)
        let leadingBlanks = (Calendar.current.component(.weekday, from: days.first ?? .now)) - 1

        return LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 0), count: 7), spacing: 0) {
            ForEach(0..<leadingBlanks, id: \.self) { _ in
                Color.clear.frame(height: 96)
            }
            ForEach(days, id: \.self) { cell($0) }
        }
        .overlay(
            RoundedRectangle(cornerRadius: Theme.Radius.card)
                .stroke(Theme.Colors.cardStroke, lineWidth: 1)
        )
    }

    private func cell(_ date: Date) -> some View {
        let isSelected = date.isSameDay(as: viewModel.selectedDate)
        let counts = viewModel.eventCount(on: date, tasks: tasks, schedules: schedules)
        let daySchedules = viewModel.schedulesFor(date: date, schedules: schedules)
        let hasCompletions = viewModel.hasCompletions(on: date, tasks: tasks)

        return VStack(alignment: .leading, spacing: 3) {
            HStack(spacing: 3) {
                Text("\(Calendar.current.component(.day, from: date))")
                    .font(.caption.weight(date.isToday ? .bold : .regular))
                    .foregroundStyle(isSelected ? .white : (date.isToday ? Theme.Colors.brand : .primary))
                    .frame(width: 22, height: 22)
                    .background(isSelected ? Theme.Colors.brand : .clear)
                    .clipShape(Circle())
                    // 오늘(선택되지 않은 경우): 얇은 테두리로 기준점 표시
                    .overlay {
                        if date.isToday && !isSelected {
                            Circle().stroke(Theme.Colors.brand, lineWidth: 1.5)
                        }
                    }

                if hasCompletions {
                    Image(systemName: "checkmark")
                        .font(.system(size: 8, weight: .bold))
                        .foregroundStyle(.green)
                }
            }

            ForEach(daySchedules.prefix(2)) { schedule in
                Text(schedule.title)
                    .font(.system(size: 10))
                    .lineLimit(1)
                    .padding(.horizontal, 4)
                    .padding(.vertical, 1)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Theme.Colors.brand.opacity(0.12))
                    .clipShape(RoundedRectangle(cornerRadius: 4))
            }

            if counts.schedules > 2 {
                Text("+\(counts.schedules - 2)")
                    .font(.system(size: 9))
                    .foregroundStyle(.secondary)
            }
            Spacer(minLength: 0)
        }
        .padding(6)
        .frame(height: 96, alignment: .topLeading)
        .frame(maxWidth: .infinity)
        .background(isSelected ? Theme.Colors.brand.opacity(0.05) : .clear)
        .overlay(
            Rectangle().stroke(Theme.Colors.cardStroke, lineWidth: 0.5)
        )
        .contentShape(Rectangle())
        .onTapGesture { viewModel.selectedDate = date }
    }

    private var rightPanel: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Theme.Spacing.lg) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(viewModel.selectedDate.shortMonthDay)
                        .font(.title3.bold())
                    Text(viewModel.selectedDate.weekdayLabel)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                TodayScheduleView(schedules: selectedSchedules)

                TodayTasksView(
                    tasks: selectedTasks,
                    onToggle: { task in
                        task.setDone(!task.isDone)
                        try? context.save()
                    },
                    onSelect: { selectedTask = $0 }
                )

                if !completedTasks.isEmpty {
                    CompletedTasksView(tasks: completedTasks)
                }
            }
            .padding(Theme.screenPadding)
        }
    }

    private func shift(_ value: Int) {
        if let d = Calendar.current.date(byAdding: .month, value: value, to: viewModel.selectedDate) {
            viewModel.selectedDate = d
        }
    }
}

#Preview {
    MacCalendarView()
        .modelContainer(PreviewHelpers.makeContainer())
        .frame(width: 1000, height: 700)
}
