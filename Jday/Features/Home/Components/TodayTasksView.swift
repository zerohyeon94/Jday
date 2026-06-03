import SwiftUI
import SwiftData

struct TodayTasksView: View {
    let tasks: [DailyTask]
    let onToggle: (DailyTask) -> Void
    /// 항목 본문 탭 시 호출(상세/수정). nil이면 본문 탭도 완료 토글로 동작.
    var onSelect: ((DailyTask) -> Void)? = nil
    /// 스와이프 삭제 콜백. 제공되면 행에 왼쪽 스와이프 삭제 액션이 활성화된다.
    var onDelete: ((DailyTask) -> Void)? = nil
    /// 컨텍스트 메뉴에서 항목을 수정한 뒤 저장(persist)하기 위한 콜백.
    /// 제공되면 우선순위·날짜 변경 메뉴가 활성화된다.
    var onUpdate: ((DailyTask) -> Void)? = nil

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

    /// 행에 컨텍스트 메뉴(양 플랫폼)를 달고, iOS에서는 스와이프 삭제 래퍼를 추가한다.
    /// macOS는 우클릭 컨텍스트 메뉴로 삭제 등을 수행한다.
    @ViewBuilder
    private func swipeableRow(_ task: DailyTask) -> some View {
        let base = row(task)
            .contextMenu { contextMenuItems(task) }

        #if os(iOS)
        if let onDelete {
            SwipeToDeleteRow(onDelete: { onDelete(task) }) {
                base
            }
            .accessibilityAction(named: "삭제") { onDelete(task) }
        } else {
            base
        }
        #else
        base
        #endif
    }

    /// 우클릭(macOS) / 길게 누르기(iOS) 컨텍스트 메뉴.
    @ViewBuilder
    private func contextMenuItems(_ task: DailyTask) -> some View {
        Button {
            onToggle(task)
        } label: {
            Label(task.isDone ? "완료 해제" : "완료됨으로 표시",
                  systemImage: task.isDone ? "circle" : "checkmark.circle")
        }

        if let onSelect {
            Button {
                onSelect(task)
            } label: {
                Label("상세 보기", systemImage: "info.circle")
            }
        }

        if onUpdate != nil {
            Divider()

            Menu {
                ForEach(Priority.allCases, id: \.self) { priority in
                    Button {
                        updatePriority(task, priority)
                    } label: {
                        if task.priority == priority {
                            Label(priority.label, systemImage: "checkmark")
                        } else {
                            Text(priority.label)
                        }
                    }
                }
            } label: {
                Label("우선 순위", systemImage: "flag")
            }

            Menu {
                Button { updateDate(task, daysFromToday: 0) } label: { Text("오늘") }
                Button { updateDate(task, daysFromToday: 1) } label: { Text("내일") }
                Button { updateDate(task, daysFromToday: 2) } label: { Text("모레") }
                Button { updateDate(task, daysFromToday: 7) } label: { Text("다음 주") }
            } label: {
                Label("날짜 변경", systemImage: "calendar")
            }
        }

        if let onDelete {
            Divider()
            Button(role: .destructive) {
                onDelete(task)
            } label: {
                Label("삭제", systemImage: "trash")
            }
        }
    }

    private func updatePriority(_ task: DailyTask, _ priority: Priority) {
        task.priority = priority
        task.updatedAt = .now
        onUpdate?(task)
    }

    private func updateDate(_ task: DailyTask, daysFromToday days: Int) {
        let base = Calendar.current.startOfDay(for: .now)
        guard let newDate = Calendar.current.date(byAdding: .day, value: days, to: base) else { return }
        task.date = newDate
        task.updatedAt = .now
        onUpdate?(task)
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
