import Foundation
import SwiftData
import OSLog

private let logger = Logger(subsystem: "com.j.jday", category: "HomeViewModel")

@MainActor
final class HomeViewModel: ObservableObject {
    func toggleTask(_ task: DailyTask, context: ModelContext) {
        task.setDone(!task.isDone)
        save(context: context)
    }

    func moveTaskToToday(_ task: DailyTask, context: ModelContext) {
        task.date = .now
        task.updatedAt = .now
        save(context: context)
    }

    func deleteTask(_ task: DailyTask, context: ModelContext) {
        context.delete(task)
        save(context: context)
    }

    func restoreTask(_ snapshot: DeletedTaskSnapshot, context: ModelContext) {
        context.insert(snapshot.restored())
        save(context: context)
    }

    func moveYesterdayTasksToToday(_ tasks: [DailyTask], context: ModelContext) {
        for task in tasks {
            task.date = .now
            task.updatedAt = .now
        }
        save(context: context)
    }

    private func save(context: ModelContext) {
        do {
            try context.save()
        } catch {
            logger.error("저장 실패: \(error.localizedDescription)")
        }
    }
}
