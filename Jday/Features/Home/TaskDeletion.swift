import SwiftUI
import SwiftData

/// 삭제한 할 일의 복구용 스냅샷.
struct DeletedTaskSnapshot: Identifiable, Equatable {
    let id = UUID()
    let title: String
    let detail: String?
    let isDone: Bool
    let completedAt: Date?
    let date: Date
    let priority: Priority
    let createdAt: Date

    init(_ task: DailyTask) {
        title = task.title
        detail = task.detail
        isDone = task.isDone
        completedAt = task.completedAt
        date = task.date
        priority = task.priority
        createdAt = task.createdAt
    }

    /// 스냅샷으로부터 동일한 할 일을 재생성한다.
    func restored() -> DailyTask {
        let task = DailyTask(title: title, detail: detail, date: date, priority: priority)
        task.isDone = isDone
        task.completedAt = completedAt
        task.createdAt = createdAt
        task.updatedAt = .now
        return task
    }

    static func == (lhs: DeletedTaskSnapshot, rhs: DeletedTaskSnapshot) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - Undo 토스트 모디파이어

extension View {
    /// 삭제 직후 하단에 실행 취소 토스트를 띄운다. 약 4초 후 자동으로 사라진다.
    func undoToast(
        _ snapshot: Binding<DeletedTaskSnapshot?>,
        onUndo: @escaping (DeletedTaskSnapshot) -> Void
    ) -> some View {
        modifier(UndoToastModifier(snapshot: snapshot, onUndo: onUndo))
    }
}

private struct UndoToastModifier: ViewModifier {
    @Binding var snapshot: DeletedTaskSnapshot?
    let onUndo: (DeletedTaskSnapshot) -> Void

    func body(content: Content) -> some View {
        content
            .overlay(alignment: .bottom) {
                if let snap = snapshot {
                    ToastView(message: "할 일을 삭제했어요", actionTitle: "실행 취소") {
                        onUndo(snap)
                        withAnimation { snapshot = nil }
                    }
                    .padding(.bottom, Theme.Spacing.sm)
                    .task(id: snap.id) {
                        try? await Task.sleep(for: .seconds(4))
                        guard !Task.isCancelled else { return }
                        if snapshot?.id == snap.id {
                            withAnimation { snapshot = nil }
                        }
                    }
                }
            }
            .animation(.spring(duration: 0.3), value: snapshot?.id)
    }
}
