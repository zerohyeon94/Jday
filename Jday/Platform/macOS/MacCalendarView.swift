import SwiftUI
import SwiftData

/// macOS 캘린더 — 좌측 월별 그리드(인라인 이벤트 칩) + 우측 선택일 패널
struct MacCalendarView: View {
    @Environment(\.modelContext) private var context
    @StateObject private var viewModel = CalendarViewModel()

    @Query(sort: \DailyTask.date) private var allTasks: [DailyTask]
    @Query(sort: \Schedule.startTime) private var allSchedules: [Schedule]

    @AppStorage("workspaceSeparationEnabled") private var wsEnabled = false
    @AppStorage("workspaceFilter") private var wsFilterRaw = WorkspaceFilter.all.rawValue
    @AppStorage("defaultWorkspace") private var wsDefaultRaw = Workspace.personal.rawValue

    private var wsFilter: WorkspaceFilter { WorkspaceFilter(rawValue: wsFilterRaw) ?? .all }
    private var wsDefault: Workspace { Workspace(rawValue: wsDefaultRaw) ?? .personal }

    private var tasks: [DailyTask] {
        allTasks.workspaceFiltered(enabled: wsEnabled, filter: wsFilter, defaultWorkspace: wsDefault)
    }
    private var schedules: [Schedule] {
        allSchedules.workspaceFiltered(enabled: wsEnabled, filter: wsFilter, defaultWorkspace: wsDefault)
    }

    private var selectedTasks: [DailyTask] { viewModel.tasksFor(date: viewModel.selectedDate, tasks: tasks) }
    private var selectedSchedules: [Schedule] { viewModel.schedulesFor(date: viewModel.selectedDate, schedules: schedules) }
    private var completedTasks: [DailyTask] { viewModel.completedTasksFor(date: viewModel.selectedDate, tasks: tasks) }

    @State private var selectedTask: DailyTask?
    @State private var deletedSnapshot: DeletedTaskSnapshot?

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

            if wsEnabled {
                WorkspaceFilterBar()
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

    private let cellHeight: CGFloat = 96
    private let barHeight: CGFloat = 15
    private let barLaneSpacing: CGFloat = 2
    private let barTopInset: CGFloat = 30
    private let maxBarLanes = 3

    private var monthGrid: some View {
        VStack(spacing: 0) {
            ForEach(Array(monthWeeks(for: viewModel.selectedDate).enumerated()), id: \.offset) { _, week in
                weekRow(week)
            }
        }
        .overlay(
            RoundedRectangle(cornerRadius: Theme.Radius.card)
                .stroke(Theme.Colors.cardStroke, lineWidth: 1)
        )
    }

    /// 한 달을 주(7칸) 단위로 분할. 앞뒤 빈 칸은 nil.
    private func monthWeeks(for date: Date) -> [[Date?]] {
        let days = viewModel.daysInMonth(for: date)
        guard let first = days.first else { return [] }
        let leading = Calendar.current.component(.weekday, from: first) - 1
        var slots: [Date?] = Array(repeating: nil, count: leading) + days.map { Optional($0) }
        while slots.count % 7 != 0 { slots.append(nil) }
        return stride(from: 0, to: slots.count, by: 7).map { Array(slots[$0..<$0 + 7]) }
    }

    /// 한 주: 날짜 셀(배경) + 이어지는 일정 막대(오버레이).
    private func weekRow(_ week: [Date?]) -> some View {
        ZStack(alignment: .topLeading) {
            HStack(spacing: 0) {
                ForEach(Array(week.enumerated()), id: \.offset) { _, day in
                    if let day {
                        dayCell(day)
                    } else {
                        Color.clear
                            .frame(height: cellHeight)
                            .frame(maxWidth: .infinity)
                            .overlay(Rectangle().stroke(Theme.Colors.cardStroke, lineWidth: 0.5))
                    }
                }
            }

            GeometryReader { geo in
                let cellWidth = geo.size.width / 7
                ForEach(weekBars(week)) { bar in
                    barView(bar)
                        .frame(width: max(0, cellWidth * CGFloat(bar.span) - 6), height: barHeight)
                        .offset(
                            x: cellWidth * CGFloat(bar.startCol) + 3,
                            y: barTopInset + CGFloat(bar.lane) * (barHeight + barLaneSpacing)
                        )
                }
            }
            .allowsHitTesting(false)
        }
    }

    private func dayCell(_ date: Date) -> some View {
        let isSelected = date.isSameDay(as: viewModel.selectedDate)
        let hasCompletions = viewModel.hasCompletions(on: date, tasks: tasks)

        return VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 3) {
                Text("\(Calendar.current.component(.day, from: date))")
                    .font(.caption.weight(date.isToday ? .bold : .regular))
                    .foregroundStyle(isSelected ? .white : (date.isToday ? Theme.Colors.brand : .primary))
                    .frame(width: 22, height: 22)
                    .background(isSelected ? Theme.Colors.brand : .clear)
                    .clipShape(Circle())
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

                Spacer(minLength: 0)
            }
            Spacer(minLength: 0)
        }
        .padding(6)
        .frame(height: cellHeight, alignment: .topLeading)
        .frame(maxWidth: .infinity)
        .background(isSelected ? Theme.Colors.brand.opacity(0.05) : .clear)
        .overlay(Rectangle().stroke(Theme.Colors.cardStroke, lineWidth: 0.5))
        .contentShape(Rectangle())
        .onTapGesture { viewModel.selectedDate = date }
    }

    // MARK: - 이어지는 일정 막대

    private struct EventBar: Identifiable {
        let id: String
        let title: String
        let startCol: Int
        let span: Int
        let lane: Int
        let isMultiDay: Bool
    }

    /// 한 주 안에서 각 일정이 차지하는 막대(시작 칸·길이·레인)를 계산.
    private func weekBars(_ week: [Date?]) -> [EventBar] {
        let dated = week.enumerated().compactMap { index, day in day.map { (col: index, date: $0) } }
        guard let weekFirst = dated.first?.date, let weekLast = dated.last?.date else { return [] }

        let calendar = Calendar.current
        func col(of date: Date) -> Int? { dated.first { $0.date.isSameDay(as: date) }?.col }

        let weekSchedules = schedules
            .filter { $0.startTime < weekLast.endOfDay && $0.endTime > weekFirst.startOfDay }
            .sorted {
                if $0.startTime != $1.startTime { return $0.startTime < $1.startTime }
                return $0.endTime > $1.endTime // 긴 일정 먼저 배치
            }

        var laneLastCol: [Int] = [] // 레인별 마지막 점유 칸
        var bars: [EventBar] = []

        for schedule in weekSchedules {
            let startDay = calendar.startOfDay(for: schedule.startTime)
            let endDay = calendar.startOfDay(for: schedule.endTime)
            let segStart = max(startDay, weekFirst)
            let segEnd = min(endDay, weekLast)
            guard let startCol = col(of: segStart), let endCol = col(of: segEnd), endCol >= startCol else { continue }

            // 레인 배정(겹치지 않는 첫 레인)
            var lane = 0
            while lane < laneLastCol.count && laneLastCol[lane] >= startCol { lane += 1 }
            guard lane < maxBarLanes else { continue } // 초과 막대는 생략

            if lane == laneLastCol.count {
                laneLastCol.append(endCol)
            } else {
                laneLastCol[lane] = endCol
            }

            bars.append(EventBar(
                id: "\(schedule.persistentModelID)-\(startCol)",
                title: schedule.title,
                startCol: startCol,
                span: endCol - startCol + 1,
                lane: lane,
                isMultiDay: endDay > startDay
            ))
        }
        return bars
    }

    @ViewBuilder
    private func barView(_ bar: EventBar) -> some View {
        if bar.isMultiDay {
            Text(bar.title)
                .font(.system(size: 10, weight: .medium))
                .foregroundStyle(.white)
                .lineLimit(1)
                .padding(.horizontal, 5)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
                .background(Theme.Colors.brand.opacity(0.9))
                .clipShape(RoundedRectangle(cornerRadius: 4))
        } else {
            Text(bar.title)
                .font(.system(size: 10))
                .foregroundStyle(Theme.Colors.brand)
                .lineLimit(1)
                .padding(.horizontal, 5)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
                .background(Theme.Colors.brand.opacity(0.12))
                .clipShape(RoundedRectangle(cornerRadius: 4))
        }
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
                    onSelect: { selectedTask = $0 },
                    onDelete: { deleteTask($0) },
                    onUpdate: { _ in try? context.save() }
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
