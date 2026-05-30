import SwiftUI
import SwiftData

struct YesterdayTasksView: View {
    let tasks: [DailyTask]
    let onMoveAll: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("어제 미완료")
                    .font(.headline)

                Spacer()

                Button(String(localized: "모두 오늘로")) {
                    onMoveAll()
                }
                .font(.caption)
                .foregroundStyle(Color.accentColor)
            }

            ForEach(tasks) { task in
                HStack(spacing: 8) {
                    Circle()
                        .fill(Color.priority(task.priority))
                        .frame(width: 8, height: 8)

                    Text(task.title)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .strikethrough(task.isDone)
                }
                .padding(.vertical, 2)
            }
        }
        .accessibilityLabel("어제 미완료 항목 \(tasks.count)개")
    }
}
