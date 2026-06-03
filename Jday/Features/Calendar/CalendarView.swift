import SwiftUI
import SwiftData

struct CalendarView: View {
    @Environment(\.modelContext) private var context
    @StateObject private var viewModel = CalendarViewModel()

    @Query(sort: \DailyTask.date) private var tasks: [DailyTask]
    @Query(sort: \Schedule.startTime) private var schedules: [Schedule]

    private var selectedTasks: [DailyTask] {
        viewModel.tasksFor(date: viewModel.selectedDate, tasks: tasks)
    }

    private var selectedSchedules: [Schedule] {
        viewModel.schedulesFor(date: viewModel.selectedDate, schedules: schedules)
    }

    private var completedTasks: [DailyTask] {
        viewModel.completedTasksFor(date: viewModel.selectedDate, tasks: tasks)
    }

    @State private var selectedTask: DailyTask?
    @State private var deletedSnapshot: DeletedTaskSnapshot?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Theme.Spacing.lg) {
                header
                modePicker
                gridCard
                dayDetail
            }
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
        .undoToast($deletedSnapshot) { snapshot in
            context.insert(snapshot.restored())
            try? context.save()
        }
    }

    private func deleteTask(_ task: DailyTask) {
        let snapshot = DeletedTaskSnapshot(task)
        context.delete(task)
        try? context.save()
        deletedSnapshot = snapshot
    }

    private var header: some View {
        HStack(alignment: .firstTextBaseline) {
            HStack(alignment: .firstTextBaseline, spacing: Theme.Spacing.sm) {
                Text(viewModel.selectedDate.monthLabel)
                    .font(.system(size: 26, weight: .bold))
                Text(viewModel.selectedDate.yearLabel)
                    .font(.title3)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            HStack(spacing: Theme.Spacing.lg) {
                Button { shiftMonth(-1) } label: {
                    Image(systemName: "chevron.left")
                }
                Button { viewModel.goToToday() } label: {
                    Text("오늘").fontWeight(.semibold)
                }
                Button { shiftMonth(1) } label: {
                    Image(systemName: "chevron.right")
                }
            }
            .foregroundStyle(Theme.Colors.brand)
            .buttonStyle(.plain)
        }
    }

    private var modePicker: some View {
        Picker("보기", selection: $viewModel.displayMode) {
            ForEach(CalendarDisplayMode.allCases, id: \.self) { Text($0.rawValue).tag($0) }
        }
        .pickerStyle(.segmented)
    }

    private var gridCard: some View {
        VStack(spacing: Theme.Spacing.md) {
            weekdayHeader

            if viewModel.displayMode == .monthly {
                monthGrid
            } else {
                weekRow
            }
        }
        .cardStyle()
    }

    private var weekdayHeader: some View {
        HStack {
            ForEach(["일", "월", "화", "수", "목", "금", "토"], id: \.self) { day in
                Text(day)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity)
            }
        }
    }

    private var monthGrid: some View {
        let days = viewModel.daysInMonth(for: viewModel.selectedDate)
        let leadingBlanks = (Calendar.current.component(.weekday, from: days.first ?? .now)) - 1

        return LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: Theme.Spacing.md) {
            ForEach(0..<leadingBlanks, id: \.self) { _ in
                Color.clear.frame(height: 40)
            }
            ForEach(days, id: \.self) { dayCell($0) }
        }
    }

    private var weekRow: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: Theme.Spacing.md) {
            ForEach(viewModel.daysInWeek(for: viewModel.selectedDate), id: \.self) { dayCell($0) }
        }
    }

    private func dayCell(_ date: Date) -> some View {
        let isSelected = date.isSameDay(as: viewModel.selectedDate)
        let isToday = date.isToday
        let hasEvents = viewModel.hasEvents(on: date, tasks: tasks, schedules: schedules)
        let hasCompletions = viewModel.hasCompletions(on: date, tasks: tasks)

        return Button {
            withAnimation(.easeOut(duration: 0.15)) { viewModel.selectedDate = date }
        } label: {
            VStack(spacing: 3) {
                Text("\(Calendar.current.component(.day, from: date))")
                    .font(.subheadline)
                    .fontWeight(isToday || isSelected ? .bold : .regular)
                    .foregroundStyle(isSelected ? .white : (isToday ? Theme.Colors.brand : .primary))
                    .frame(width: 32, height: 32)
                    .background(isSelected ? Theme.Colors.brand : .clear)
                    .clipShape(Circle())
                    // 오늘(선택되지 않은 경우): 얇은 테두리로 기준점 표시
                    .overlay {
                        if isToday && !isSelected {
                            Circle().stroke(Theme.Colors.brand, lineWidth: 1.5)
                        }
                    }

                dayMarkers(isSelected: isSelected, hasEvents: hasEvents, hasCompletions: hasCompletions)
            }
            .frame(maxWidth: .infinity)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(cellAccessibilityLabel(date: date, isToday: isToday, isSelected: isSelected, hasEvents: hasEvents, hasCompletions: hasCompletions))
    }

    /// 날짜 셀 하단 마커: 이벤트 도트 + 완료 체크 마커.
    @ViewBuilder
    private func dayMarkers(isSelected: Bool, hasEvents: Bool, hasCompletions: Bool) -> some View {
        HStack(spacing: 2) {
            if hasEvents {
                Circle()
                    .fill(isSelected ? Color.white : Theme.Colors.brand)
                    .frame(width: 4, height: 4)
            }
            if hasCompletions {
                Image(systemName: "checkmark")
                    .font(.system(size: 7, weight: .bold))
                    .foregroundStyle(isSelected ? Color.white : .green)
            }
        }
        .frame(height: 8)
    }

    private func cellAccessibilityLabel(date: Date, isToday: Bool, isSelected: Bool, hasEvents: Bool, hasCompletions: Bool) -> String {
        var parts = ["\(Calendar.current.component(.month, from: date))월 \(Calendar.current.component(.day, from: date))일"]
        if isToday { parts.append("오늘") }
        if isSelected { parts.append("선택됨") }
        if hasEvents { parts.append("이벤트 있음") }
        if hasCompletions { parts.append("완료 기록 있음") }
        return parts.joined(separator: ", ")
    }

    private var dayDetail: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.lg) {
            HStack(alignment: .firstTextBaseline) {
                Text("\(viewModel.selectedDate.shortMonthDay) \(viewModel.selectedDate.weekdayLabel)")
                    .font(.headline)
                Spacer()
                Text("일정 \(selectedSchedules.count) · 할 일 \(selectedTasks.count)")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            if !selectedSchedules.isEmpty {
                TodayScheduleView(schedules: selectedSchedules)
            }

            TodayTasksView(
                tasks: selectedTasks,
                onToggle: { task in
                    task.setDone(!task.isDone)
                    try? context.save()
                },
                onSelect: { selectedTask = $0 },
                onDelete: { deleteTask($0) }
            )

            if !completedTasks.isEmpty {
                CompletedTasksView(tasks: completedTasks)
            }
        }
    }

    private func shiftMonth(_ value: Int) {
        let component: Calendar.Component = viewModel.displayMode == .monthly ? .month : .weekOfYear
        if let newDate = Calendar.current.date(byAdding: component, value: value, to: viewModel.selectedDate) {
            withAnimation(.easeOut(duration: 0.15)) { viewModel.selectedDate = newDate }
        }
    }
}

#Preview {
    NavigationStack {
        CalendarView()
            .modelContainer(PreviewHelpers.makeContainer())
    }
}
