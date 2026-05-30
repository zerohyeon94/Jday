import SwiftUI
import SwiftData

struct YesterdayTasksView: View {
    let tasks: [DailyTask]
    let onMoveOne: (DailyTask) -> Void
    let onMoveAll: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            CardHeader(title: "어제 미완료", trailing: "\(tasks.count)개")

            VStack(spacing: 0) {
                ForEach(Array(tasks.enumerated()), id: \.element.persistentModelID) { index, task in
                    row(task)
                    if index < tasks.count - 1 {
                        DashedDivider()
                            .padding(.vertical, Theme.Spacing.xs)
                    }
                }
            }

            Button {
                onMoveAll()
            } label: {
                Text("모두 오늘로 옮기기")
            }
            .buttonStyle(PrimaryButtonStyle())
            .padding(.top, Theme.Spacing.xs)
        }
        .cardStyle()
        .accessibilityElement(children: .contain)
    }

    private func row(_ task: DailyTask) -> some View {
        HStack(spacing: Theme.Spacing.md) {
            Image(systemName: "circle")
                .font(.system(size: 18))
                .foregroundStyle(.secondary)

            Text(task.title)
                .font(.subheadline)
                .foregroundStyle(.primary)

            Spacer()

            Button {
                onMoveOne(task)
            } label: {
                Label("오늘로", systemImage: "arrow.uturn.left")
                    .font(.caption.weight(.medium))
                    .labelStyle(.titleAndIcon)
                    .foregroundStyle(Theme.Colors.brand)
            }
            .buttonStyle(.plain)
        }
        .padding(.vertical, Theme.Spacing.sm)
    }
}

#Preview {
    YesterdayTasksView(
        tasks: PreviewHelpers.sampleYesterdayTasks,
        onMoveOne: { _ in },
        onMoveAll: {}
    )
    .padding()
    .background(Theme.Colors.appBackground)
}
