import SwiftUI
import SwiftData

/// 선택 날짜에 완료(completedAt)된 할 일을 시간순으로 보여주는 "완료 기록" 섹션.
struct CompletedTasksView: View {
    let tasks: [DailyTask]

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            CardHeader(title: "완료 기록", trailing: "\(tasks.count)개")

            VStack(spacing: 0) {
                ForEach(Array(tasks.enumerated()), id: \.element.persistentModelID) { index, task in
                    row(task)
                    if index < tasks.count - 1 {
                        DashedDivider()
                    }
                }
            }
        }
        .cardStyle()
    }

    private func row(_ task: DailyTask) -> some View {
        HStack(spacing: Theme.Spacing.md) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 18))
                .foregroundStyle(.green)

            VStack(alignment: .leading, spacing: 2) {
                Text(task.title)
                    .font(.subheadline)
                    .foregroundStyle(.primary)

                // 원래 예정 날짜가 완료일과 다르면 함께 표시
                if let completedAt = task.completedAt, !task.date.isSameDay(as: completedAt) {
                    Text("예정 \(task.date.shortMonthDay)")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            if let completedAt = task.completedAt {
                Text(completedAt.hourMinuteLabel)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, Theme.Spacing.sm)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(task.title) 완료\(task.completedAt.map { ", \($0.hourMinuteLabel)" } ?? "")")
    }
}

#Preview {
    CompletedTasksView(tasks: PreviewHelpers.sampleTasks.filter { $0.isDone })
        .padding()
        .background(Theme.Colors.appBackground)
}
