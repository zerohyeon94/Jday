import SwiftUI
import SwiftData

struct TodayTasksView: View {
    let tasks: [DailyTask]
    let onToggle: (DailyTask) -> Void

    private var ordered: [DailyTask] {
        tasks.filter { !$0.isDone } + tasks.filter { $0.isDone }
    }

    private var doneCount: Int { tasks.filter(\.isDone).count }

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            CardHeader(
                title: "오늘 할 일",
                trailing: tasks.isEmpty ? nil : "\(doneCount) / \(tasks.count) 완료"
            )

            if tasks.isEmpty {
                emptyState
            } else {
                VStack(spacing: 0) {
                    ForEach(Array(ordered.enumerated()), id: \.element.persistentModelID) { index, task in
                        row(task)
                        if index < ordered.count - 1 {
                            DashedDivider()
                        }
                    }
                }
            }
        }
        .cardStyle()
    }

    private var emptyState: some View {
        Text("할 일을 추가해보세요 +")
            .font(.subheadline)
            .foregroundStyle(.secondary)
            .frame(maxWidth: .infinity, alignment: .center)
            .padding(.vertical, Theme.Spacing.md)
    }

    private func row(_ task: DailyTask) -> some View {
        Button {
            withAnimation(.easeOut(duration: 0.2)) { onToggle(task) }
        } label: {
            HStack(spacing: Theme.Spacing.md) {
                Image(systemName: task.isDone ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 20))
                    .foregroundStyle(task.isDone ? Theme.Colors.brand : Color.secondary)

                Text(task.title)
                    .font(.subheadline)
                    .strikethrough(task.isDone)
                    .foregroundStyle(task.isDone ? .secondary : .primary)

                Spacer()

                Text(task.date.amPmLabel)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding(.vertical, Theme.Spacing.sm)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(task.title), \(task.isDone ? "완료" : "미완료")")
        .accessibilityHint("탭하여 상태 변경")
    }
}

#Preview {
    TodayTasksView(tasks: PreviewHelpers.sampleTasks, onToggle: { _ in })
        .padding()
        .background(Theme.Colors.appBackground)
}
