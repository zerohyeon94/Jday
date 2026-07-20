import Foundation
import SwiftData
import OSLog

private let logger = Logger(subsystem: "com.j.jday", category: "HomeViewModel")

@MainActor
final class HomeViewModel: ObservableObject {
    func toggleTask(_ task: DailyTask, context: ModelContext) {
        task.setDone(!task.isDone)
        save(context: context)
        syncToReminders(task, context: context)
    }

    func moveTaskToToday(_ task: DailyTask, context: ModelContext) {
        task.date = .now
        task.updatedAt = .now
        save(context: context)
        syncToReminders(task, context: context)
    }

    func deleteTask(_ task: DailyTask, context: ModelContext) {
        // 삭제 후에는 모델에 접근할 수 없으므로 식별자를 먼저 확보한다
        let reminderID = task.exportedReminderID
        context.delete(task)
        save(context: context)
        #if os(iOS)
        if let reminderID {
            Task { await ReminderService.shared.removeExport(reminderID: reminderID) }
        }
        #endif
    }

    func restoreTask(_ snapshot: DeletedTaskSnapshot, context: ModelContext) {
        let restored = snapshot.restored()
        context.insert(restored)
        save(context: context)
        syncToReminders(restored, context: context)
    }

    func moveYesterdayTasksToToday(_ tasks: [DailyTask], context: ModelContext) {
        for task in tasks {
            task.date = .now
            task.updatedAt = .now
        }
        save(context: context)
        for task in tasks {
            syncToReminders(task, context: context)
        }
    }

    /// Apple 미리 알림에 반영 (동기화가 켜져 있을 때만 동작).
    private func syncToReminders(_ task: DailyTask, context: ModelContext) {
        #if os(iOS)
        Task {
            if await ReminderService.shared.syncExport(for: task) {
                save(context: context)
            }
        }
        #endif
    }

    private func save(context: ModelContext) {
        do {
            try context.save()
        } catch {
            logger.error("저장 실패: \(error.localizedDescription)")
        }
    }
}
