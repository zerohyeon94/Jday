import WidgetKit
import SwiftUI

/// 오늘 할 일 — 홈 중형. 위젯에서 바로 완료 체크 가능(AppIntents).
struct TodayTasksWidget: Widget {
    let kind = "TodayTasksWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: JdayTimelineProvider()) { entry in
            TodayTasksWidgetView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("오늘 할 일")
        .description("오늘 할 일을 확인하고 위젯에서 바로 완료 체크해요.")
        .supportedFamilies([.systemMedium])
    }
}

struct TodayTasksWidgetView: View {
    let entry: JdayTimelineEntry

    private var visibleTasks: [WidgetTaskItem] {
        Array(entry.tasks.prefix(4))
    }

    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            VStack(alignment: .leading, spacing: 6) {
                Text(entry.date.shortMonthDay)
                    .font(.headline)
                Text("\(entry.remainingCount)개 남음")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
                if let next = entry.nextSchedule {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("다음 일정")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                        Text("\(next.startTime.hourMinuteLabel) \(next.title)")
                            .font(.caption)
                            .lineLimit(1)
                    }
                }
            }
            .frame(width: 96, alignment: .leading)

            if visibleTasks.isEmpty {
                VStack {
                    Spacer()
                    Text("오늘 할 일이 없어요")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity)
                    Spacer()
                }
            } else {
                VStack(alignment: .leading, spacing: 6) {
                    ForEach(visibleTasks) { task in
                        TaskRowView(task: task)
                    }
                    Spacer(minLength: 0)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }
}

private struct TaskRowView: View {
    let task: WidgetTaskItem

    var body: some View {
        HStack(spacing: 8) {
            Button(intent: ToggleTaskIntent(taskID: task.id)) {
                Image(systemName: task.isDone ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(task.isDone ? Color.green : Color.priority(task.priority))
            }
            .buttonStyle(.plain)
            .accessibilityLabel(Text(task.isDone ? "완료 해제" : "완료로 표시"))

            Text(task.title)
                .font(.subheadline)
                .strikethrough(task.isDone)
                .foregroundStyle(task.isDone ? .secondary : .primary)
                .lineLimit(1)
        }
    }
}

#Preview(as: .systemMedium) {
    TodayTasksWidget()
} timeline: {
    JdayTimelineEntry.preview
}
