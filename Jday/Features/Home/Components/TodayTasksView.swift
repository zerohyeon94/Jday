import SwiftUI
import SwiftData

struct TodayTasksView: View {
    let tasks: [DailyTask]
    let onToggle: (DailyTask) -> Void
    /// 항목 본문 탭 시 호출(상세/수정). nil이면 본문 탭도 완료 토글로 동작.
    var onSelect: ((DailyTask) -> Void)? = nil
    /// 스와이프 삭제 콜백. 제공되면 행에 왼쪽 스와이프 삭제 액션이 활성화된다.
    var onDelete: ((DailyTask) -> Void)? = nil

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
                        swipeableRow(task)
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

    /// 완료된 항목은 "완료 HH:mm", 그 외는 예정 시간대 라벨을 표시.
    @ViewBuilder
    private func trailingLabel(_ task: DailyTask) -> some View {
        if task.isDone, let completedAt = task.completedAt {
            Text("완료 \(completedAt.hourMinuteLabel)")
        } else {
            Text(task.date.amPmLabel)
        }
    }

    /// onDelete가 있으면 스와이프 삭제 래퍼를 적용하고, VoiceOver 삭제 액션도 추가.
    @ViewBuilder
    private func swipeableRow(_ task: DailyTask) -> some View {
        if let onDelete {
            SwipeToDeleteRow(onDelete: { onDelete(task) }) {
                row(task)
            }
            .accessibilityAction(named: "삭제") { onDelete(task) }
        } else {
            row(task)
        }
    }

    private func row(_ task: DailyTask) -> some View {
        HStack(spacing: Theme.Spacing.md) {
            // 좌측 우선순위 색상 바 (낮음=회색 / 중간=주황 / 높음=빨강)
            RoundedRectangle(cornerRadius: 2, style: .continuous)
                .fill(Color.priority(task.priority))
                .frame(width: 4)
                .frame(maxHeight: .infinity)
                .opacity(task.isDone ? 0.3 : 1)
                .accessibilityHidden(true)

            // 체크박스: 완료 토글 전용
            Button {
                withAnimation(.easeOut(duration: 0.2)) { onToggle(task) }
            } label: {
                Image(systemName: task.isDone ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 20))
                    .foregroundStyle(task.isDone ? Theme.Colors.brand : Color.secondary)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel(task.isDone ? "완료됨" : "미완료")
            .accessibilityHint("탭하여 완료 상태 변경")

            // 본문: 상세/수정으로 이동(onSelect 없으면 토글)
            Button {
                if let onSelect {
                    onSelect(task)
                } else {
                    withAnimation(.easeOut(duration: 0.2)) { onToggle(task) }
                }
            } label: {
                HStack(spacing: Theme.Spacing.md) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(task.title)
                            .font(.subheadline)
                            .strikethrough(task.isDone)
                            .foregroundStyle(task.isDone ? .secondary : .primary)
                            .lineLimit(1)
                            .truncationMode(.tail)

                        if let detail = task.detail, !detail.isEmpty {
                            Text(detail)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .lineLimit(1)
                        }
                    }

                    Spacer(minLength: Theme.Spacing.sm)

                    trailingLabel(task)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                        .fixedSize()
                        .layoutPriority(1)
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("\(task.title), 우선순위 \(task.priority.label)\(task.detail.map { ", \($0)" } ?? "")")
            .accessibilityHint(onSelect == nil ? "탭하여 완료 상태 변경" : "탭하여 상세 보기")
        }
        .padding(.vertical, Theme.Spacing.sm)
    }
}

#Preview {
    TodayTasksView(tasks: PreviewHelpers.sampleTasks, onToggle: { _ in })
        .padding()
        .background(Theme.Colors.appBackground)
}
