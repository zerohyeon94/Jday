import SwiftUI
import SwiftData

struct TodayTasksView: View {
    let tasks: [DailyTask]
    let onToggle: (DailyTask) -> Void

    private var pending: [DailyTask] { tasks.filter { !$0.isDone } }
    private var done: [DailyTask] { tasks.filter { $0.isDone } }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("오늘 할 일")
                .font(.headline)

            if tasks.isEmpty {
                emptyState
            } else {
                taskList
            }
        }
    }

    private var emptyState: some View {
        Text("할 일을 추가해보세요 +")
            .font(.subheadline)
            .foregroundStyle(.secondary)
            .frame(maxWidth: .infinity, alignment: .center)
            .padding(.vertical, 12)
    }

    private var taskList: some View {
        VStack(spacing: 4) {
            ForEach(pending) { task in
                taskRow(task)
            }
            ForEach(done) { task in
                taskRow(task)
            }
        }
    }

    private func taskRow(_ task: DailyTask) -> some View {
        Button {
            onToggle(task)
        } label: {
            HStack(spacing: 12) {
                Image(systemName: task.isDone ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(task.isDone ? .green : .secondary)
                    .font(.title3)

                Text(task.title)
                    .font(.subheadline)
                    .strikethrough(task.isDone)
                    .foregroundStyle(task.isDone ? .secondary : .primary)

                Spacer()

                Circle()
                    .fill(Color.priority(task.priority))
                    .frame(width: 8, height: 8)
            }
            .padding(.vertical, 6)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(task.title), \(task.isDone ? "완료" : "미완료")")
        .accessibilityHint("탭하여 상태 변경")
    }
}
