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

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                Picker(String(localized: "보기"), selection: $viewModel.displayMode) {
                    ForEach(CalendarDisplayMode.allCases, id: \.self) { mode in
                        Text(mode.rawValue).tag(mode)
                    }
                }
                .pickerStyle(.segmented)
                .padding()

                monthGrid

                Divider()

                selectedDayDetail
            }
            .navigationTitle(String(localized: "캘린더"))
        }
    }

    private var monthGrid: some View {
        let days = viewModel.daysInMonth(for: viewModel.selectedDate)
        let firstWeekday = Calendar.current.component(.weekday, from: days.first ?? .now) - 1

        return VStack(spacing: 8) {
            HStack {
                ForEach(["일", "월", "화", "수", "목", "금", "토"], id: \.self) { day in
                    Text(day)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity)
                }
            }

            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 8) {
                ForEach(0..<firstWeekday, id: \.self) { _ in
                    Color.clear.frame(height: 36)
                }

                ForEach(days, id: \.self) { date in
                    dayCell(date)
                }
            }
        }
        .padding(.horizontal)
    }

    private func dayCell(_ date: Date) -> some View {
        let isSelected = date.isSameDay(as: viewModel.selectedDate)
        let isToday = date.isToday
        let hasEvents = viewModel.hasEvents(on: date, tasks: tasks, schedules: schedules)

        return Button {
            viewModel.selectedDate = date
        } label: {
            VStack(spacing: 2) {
                Text("\(Calendar.current.component(.day, from: date))")
                    .font(.subheadline)
                    .fontWeight(isToday ? .bold : .regular)
                    .foregroundStyle(isSelected ? .white : isToday ? .accentColor : .primary)
                    .frame(width: 32, height: 32)
                    .background(isSelected ? Color.accentColor : Color.clear)
                    .clipShape(Circle())

                if hasEvents {
                    Circle()
                        .fill(isSelected ? Color.white : Color.accentColor)
                        .frame(width: 4, height: 4)
                } else {
                    Color.clear.frame(width: 4, height: 4)
                }
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(Calendar.current.component(.month, from: date))월 \(Calendar.current.component(.day, from: date))일\(isToday ? ", 오늘" : "")\(hasEvents ? ", 이벤트 있음" : "")")
    }

    private var selectedDayDetail: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text(viewModel.selectedDate.formattedDate)
                    .font(.headline)
                    .padding(.horizontal)
                    .padding(.top, 12)

                if !selectedSchedules.isEmpty {
                    TodayScheduleView(schedules: selectedSchedules)
                        .padding(.horizontal)
                }

                TodayTasksView(tasks: selectedTasks) { task in
                    task.isDone.toggle()
                    task.updatedAt = .now
                    try? context.save()
                }
                .padding(.horizontal)
            }
        }
    }
}

#Preview {
    CalendarView()
        .modelContainer(PreviewHelpers.makeContainer())
}
